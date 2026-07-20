<?php

namespace App\Http\Controllers;

use App\Http\Resources\MileageObservationResource;
use App\Http\Resources\ServiceRecordResource;
use App\Models\AnonymousSession;
use App\Models\HistoryAnswer;
use App\Models\MileageObservation;
use App\Models\ServiceRecord;
use App\Models\Vehicle;
use App\Models\WorkCatalogItem;
use App\Services\IdempotencyService;
use App\Services\PlanCalculator;
use App\Services\VehicleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class ServiceRecordController extends Controller
{
    public function __construct(
        private readonly VehicleService $vehicles,
        private readonly PlanCalculator $plans,
        private readonly IdempotencyService $idempotency,
    ) {}

    public function index(Request $request, string $vehicle): JsonResponse
    {
        $validator = Validator::make($request->query(), [
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', Rule::in([20, 50, 100])],
        ]);
        $validator->after(function ($validator) use ($request): void {
            if (array_diff(array_keys($request->query()), ['page', 'per_page']) !== []) {
                $validator->errors()->add('request', __('api.fields.unknown'));
            }
        });
        if ($validator->fails()) {
            throw new ValidationException($validator);
        }

        $model = $this->vehicles->owned($this->session($request), $vehicle);
        $page = (int) $request->query('page', 1);
        $perPage = (int) $request->query('per_page', 20);
        $paginator = ServiceRecord::query()
            ->with('items.workCatalogItem')
            ->where('vehicle_id', $model->id)
            ->orderByDesc('service_date')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'items' => ServiceRecordResource::collection($paginator->items())->resolve($request),
            'meta' => [
                'page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'total_pages' => $paginator->lastPage(),
            ],
        ]);
    }

    public function store(Request $request, string $vehicle): JsonResponse
    {
        $session = $this->session($request);
        $model = $this->vehicles->owned($session, $vehicle);
        $applicable = $this->plans->applicableWorkCodes($model)->all();
        $validator = Validator::make($request->all(), [
            'service_date' => ['required', 'date_format:Y-m-d', 'before_or_equal:today'],
            'mileage' => ['sometimes', 'nullable', 'array'],
            'mileage.value' => ['required_with:mileage', 'integer', 'min:0'],
            'mileage.unit' => ['required_with:mileage', Rule::in(['km', 'mi'])],
            'work_codes' => ['required', 'array', 'min:1'],
            'work_codes.*' => ['required', 'string', 'distinct:strict', Rule::in($applicable)],
            'note' => ['sometimes', 'string', 'max:4000'],
            'evidence_source' => ['sometimes', Rule::in(['self'])],
        ]);
        $validator->after(function ($validator) use ($request): void {
            if (array_diff(array_keys($request->all()), [
                'service_date', 'mileage', 'work_codes', 'note', 'evidence_source',
            ]) !== []) {
                $validator->errors()->add('request', __('api.fields.unknown'));
            }
            if (is_array($request->input('mileage'))
                && array_diff(array_keys($request->input('mileage')), ['value', 'unit']) !== []) {
                $validator->errors()->add('mileage', __('api.fields.unknown'));
            }
        });
        if ($validator->fails()) {
            throw new ValidationException($validator);
        }
        $validated = $validator->validated();

        return $this->idempotency->execute(
            $request,
            'anonymous:'.$session->id,
            'createServiceRecord:'.$vehicle,
            function () use ($session, $vehicle, $validated, $request): JsonResponse {
                [$record, $observation, $snapshot] = $this->create($session, $vehicle, $validated);

                return response()->json([
                    'service_record' => (new ServiceRecordResource($record))->resolve($request),
                    'mileage_observation' => $observation === null
                        ? null
                        : (new MileageObservationResource($observation))->resolve($request),
                    'maintenance_plan_id' => $snapshot->id,
                ], 201);
            },
        );
    }

    private function create(AnonymousSession $session, string $id, array $data): array
    {
        return DB::transaction(function () use ($session, $id, $data): array {
            $vehicle = $this->vehicles->owned($session, $id, true);
            $mileage = array_key_exists('mileage', $data)
                ? $data['mileage']
                : ($vehicle->current_mileage === null ? null : [
                    'value' => $vehicle->current_mileage,
                    'unit' => $vehicle->mileage_unit,
                ]);
            $catalog = WorkCatalogItem::query()
                ->whereIn('code', $data['work_codes'])
                ->get()
                ->keyBy('code');
            $record = ServiceRecord::query()->create([
                'vehicle_id' => $vehicle->id,
                'service_date' => $data['service_date'],
                'mileage_value' => $mileage['value'] ?? null,
                'mileage_unit' => $mileage['unit'] ?? null,
                'evidence_source' => $data['evidence_source'] ?? 'self',
                'note' => $data['note'] ?? null,
                'version' => 1,
            ]);
            foreach ($data['work_codes'] as $code) {
                $record->items()->create(['work_catalog_item_id' => $catalog[$code]->id]);
            }

            $this->synchronizeHistoryAnswers($vehicle, $record, $catalog);
            $observation = null;
            if ($mileage !== null) {
                $isNewCurrent = $vehicle->current_mileage === null
                    || $this->toKm($mileage['value'], $mileage['unit'])
                        > $this->toKm($vehicle->current_mileage, $vehicle->mileage_unit);
                if ($isNewCurrent) {
                    $observation = MileageObservation::query()->create([
                        'vehicle_id' => $vehicle->id,
                        'value' => $mileage['value'],
                        'unit' => $mileage['unit'],
                        'source' => 'service',
                        'observed_at' => now(),
                    ]);
                    $vehicle->forceFill([
                        'current_mileage' => $mileage['value'],
                        'mileage_unit' => $mileage['unit'],
                        'version' => $vehicle->version + 1,
                    ])->save();
                }
            }

            $record->load('items.workCatalogItem');
            $snapshot = $this->plans->calculate($vehicle->fresh('configuration'));

            return [$record, $observation, $snapshot];
        });
    }

    private function synchronizeHistoryAnswers(Vehicle $vehicle, ServiceRecord $record, $catalog): void
    {
        foreach ($catalog as $item) {
            $latest = ServiceRecord::query()
                ->where('vehicle_id', $vehicle->id)
                ->whereHas('items', fn ($query) => $query->where('work_catalog_item_id', $item->id))
                ->orderByDesc('service_date')
                ->orderByDesc('created_at')
                ->orderByDesc('id')
                ->firstOrFail();
            $answer = HistoryAnswer::query()
                ->where('vehicle_id', $vehicle->id)
                ->where('work_catalog_item_id', $item->id)
                ->lockForUpdate()
                ->first();
            $values = [
                'answer' => 'done_known',
                'performed_date' => $latest->service_date,
                'performed_mileage_km' => $latest->mileage_value === null
                    ? null
                    : (int) round($this->toKm($latest->mileage_value, $latest->mileage_unit)),
            ];
            if ($answer === null) {
                HistoryAnswer::query()->create([
                    'vehicle_id' => $vehicle->id,
                    'work_catalog_item_id' => $item->id,
                    ...$values,
                    'version' => 1,
                ]);
            } else {
                $answer->fill([...$values, 'version' => $answer->version + 1])->save();
            }
        }
    }

    private function toKm(int $value, string $unit): float
    {
        return $unit === 'mi' ? $value * 1.609344 : $value;
    }

    private function session(Request $request): AnonymousSession
    {
        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');

        return $session;
    }
}
