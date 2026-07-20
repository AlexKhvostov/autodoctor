<?php

namespace App\Http\Controllers;

use App\Http\Resources\HistoryAnswerResource;
use App\Models\AnonymousSession;
use App\Models\HistoryAnswer;
use App\Models\WorkCatalogItem;
use App\Services\IdempotencyService;
use App\Services\PlanCalculator;
use App\Services\VehicleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class HistoryAnswerController extends Controller
{
    public function __construct(
        private readonly VehicleService $vehicles,
        private readonly PlanCalculator $plans,
        private readonly IdempotencyService $idempotency,
    ) {}

    public function store(Request $request, string $vehicle): JsonResponse
    {
        $session = $this->session($request);
        $model = $this->vehicles->owned($session, $vehicle);
        $applicable = $this->plans->applicableWorkCodes($model)->all();
        $validator = Validator::make($request->all(), [
            'answers' => ['required', 'array', 'min:1'],
            'answers.*' => ['required', 'array'],
            'answers.*.work_code' => ['required', 'string', 'distinct:strict', Rule::in($applicable)],
            'answers.*.answer' => ['required', 'string', Rule::in(HistoryAnswer::VALUES)],
            'answers.*.performed_date' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'answers.*.performed_mileage_km' => ['nullable', 'integer', 'min:0'],
        ]);
        $validator->after(function ($validator) use ($request, $model): void {
            $currentMileage = $model->current_mileage;
            if ($currentMileage !== null && $model->mileage_unit === 'mi') {
                $currentMileage = (int) round($currentMileage * 1.609344);
            }

            foreach ($request->input('answers', []) as $index => $answer) {
                $known = ($answer['answer'] ?? null) === 'done_known';
                $hasDate = array_key_exists('performed_date', $answer) && $answer['performed_date'] !== null;
                $hasMileage = array_key_exists('performed_mileage_km', $answer)
                    && $answer['performed_mileage_km'] !== null;
                if ($known && ! $hasDate && ! $hasMileage) {
                    $validator->errors()->add("answers.{$index}", __('api.fields.history_known_reference'));
                }
                if (! $known && ($hasDate || $hasMileage)) {
                    $validator->errors()->add("answers.{$index}", __('api.fields.history_reference_prohibited'));
                }
                if ($hasMileage && $currentMileage !== null
                    && (int) $answer['performed_mileage_km'] > $currentMileage) {
                    $validator->errors()->add(
                        "answers.{$index}.performed_mileage_km",
                        __('api.fields.history_mileage_above_current'),
                    );
                }
                $unknownKeys = array_diff(
                    array_keys($answer),
                    ['work_code', 'answer', 'performed_date', 'performed_mileage_km'],
                );
                if ($unknownKeys !== []) {
                    $validator->errors()->add("answers.{$index}", __('api.fields.unknown'));
                }
            }
            if (array_diff(array_keys($request->all()), ['answers']) !== []) {
                $validator->errors()->add('request', __('api.fields.unknown'));
            }
        });
        if ($validator->fails()) {
            throw new ValidationException($validator);
        }
        $validated = $validator->validated();

        return $this->idempotency->execute(
            $request,
            'anonymous:'.$session->id,
            'submitHistoryAnswers:'.$vehicle,
            function () use ($validated, $model, $request): JsonResponse {
                $catalog = WorkCatalogItem::query()
                    ->whereIn('code', collect($validated['answers'])->pluck('work_code'))
                    ->get()
                    ->keyBy('code');
                $saved = collect();

                foreach ($validated['answers'] as $value) {
                    $item = $catalog->get($value['work_code']);
                    $answer = HistoryAnswer::query()
                        ->where('vehicle_id', $model->id)
                        ->where('work_catalog_item_id', $item->id)
                        ->lockForUpdate()
                        ->first();
                    if ($answer === null) {
                        $answer = new HistoryAnswer([
                            'vehicle_id' => $model->id,
                            'work_catalog_item_id' => $item->id,
                            'version' => 1,
                        ]);
                    } else {
                        $answer->version++;
                    }
                    $answer->fill([
                        'answer' => $value['answer'],
                        'performed_date' => $value['performed_date'] ?? null,
                        'performed_mileage_km' => $value['performed_mileage_km'] ?? null,
                    ])->save();
                    $answer->setRelation('workCatalogItem', $item);
                    $saved->push($answer);
                }

                $snapshot = $this->plans->calculate($model);

                return response()->json([
                    'items' => HistoryAnswerResource::collection($saved)->resolve($request),
                    'maintenance_plan_id' => $snapshot->id,
                ]);
            },
        );
    }

    private function session(Request $request): AnonymousSession
    {
        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');

        return $session;
    }
}
