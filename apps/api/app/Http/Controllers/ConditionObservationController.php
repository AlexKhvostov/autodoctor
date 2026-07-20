<?php

namespace App\Http\Controllers;

use App\Http\Resources\ConditionObservationResource;
use App\Models\AnonymousSession;
use App\Models\ConditionObservation;
use App\Models\WorkCatalogItem;
use App\Services\IdempotencyService;
use App\Services\PlanCalculator;
use App\Services\VehicleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class ConditionObservationController extends Controller
{
    private const CODES = ['brake_pads', 'brake_discs', 'tire_condition_inspection'];

    public function __construct(
        private readonly VehicleService $vehicles,
        private readonly PlanCalculator $plans,
        private readonly IdempotencyService $idempotency,
    ) {}

    public function index(Request $request, string $vehicle): JsonResponse
    {
        $model = $this->vehicles->owned($this->session($request), $vehicle);
        $validated = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', Rule::in([20, 50, 100])],
        ]);
        $page = ConditionObservation::query()
            ->with('workCatalogItem')
            ->where('vehicle_id', $model->id)
            ->orderByDesc('observed_at')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->paginate($validated['per_page'] ?? 20, ['*'], 'page', $validated['page'] ?? 1);

        return response()->json([
            'items' => ConditionObservationResource::collection($page->getCollection())->resolve($request),
            'meta' => [
                'page' => $page->currentPage(),
                'per_page' => $page->perPage(),
                'total' => $page->total(),
                'total_pages' => max(1, $page->lastPage()),
            ],
        ]);
    }

    public function store(Request $request, string $vehicle): JsonResponse
    {
        $session = $this->session($request);
        $model = $this->vehicles->owned($session, $vehicle);
        $validated = $request->validate([
            'work_code' => ['required', 'string', Rule::in(self::CODES)],
            'wear_percent' => ['required', 'integer', 'between:0,100'],
            'observed_at' => ['required', 'date_format:Y-m-d', 'before_or_equal:today'],
            'mileage' => ['sometimes', 'nullable', 'array:value,unit'],
            'mileage.value' => ['required_with:mileage', 'integer', 'min:0'],
            'mileage.unit' => ['required_with:mileage', Rule::in(['km', 'mi'])],
            'source' => ['required', Rule::in(['self', 'workshop'])],
            'note' => ['sometimes', 'nullable', 'string', 'max:2000'],
        ]);
        if (array_diff(array_keys($request->all()), [
            'work_code', 'wear_percent', 'observed_at', 'mileage', 'source', 'note',
        ]) !== []) {
            throw ValidationException::withMessages(['request' => [__('api.fields.unknown')]]);
        }
        if (isset($validated['mileage']) && $model->current_mileage !== null) {
            $inputKm = $validated['mileage']['unit'] === 'mi'
                ? (int) round($validated['mileage']['value'] * 1.609344)
                : $validated['mileage']['value'];
            $currentKm = $model->mileage_unit === 'mi'
                ? (int) round($model->current_mileage * 1.609344)
                : $model->current_mileage;
            if ($inputKm > $currentKm) {
                throw ValidationException::withMessages([
                    'mileage.value' => [__('api.fields.condition_mileage_above_current')],
                ]);
            }
        }
        $applicable = $this->plans->applicableWorkCodes($model);
        if (! $applicable->contains($validated['work_code'])) {
            throw ValidationException::withMessages(['work_code' => [__('api.fields.work_not_applicable')]]);
        }

        return $this->idempotency->execute(
            $request,
            'anonymous:'.$session->id,
            'createConditionObservation:'.$vehicle,
            function () use ($validated, $model, $request): JsonResponse {
                $work = WorkCatalogItem::query()->where('code', $validated['work_code'])->firstOrFail();
                $observation = ConditionObservation::query()->create([
                    'vehicle_id' => $model->id,
                    'work_catalog_item_id' => $work->id,
                    'wear_percent' => $validated['wear_percent'],
                    'observed_at' => $validated['observed_at'],
                    'mileage_value' => $validated['mileage']['value'] ?? null,
                    'mileage_unit' => $validated['mileage']['unit'] ?? null,
                    'source' => $validated['source'],
                    'note' => $validated['note'] ?? null,
                ]);
                $observation->setRelation('workCatalogItem', $work);
                $snapshot = $this->plans->calculate($model);

                return response()->json([
                    'observation' => (new ConditionObservationResource($observation))->resolve($request),
                    'maintenance_plan_id' => $snapshot->id,
                ], 201);
            },
        );
    }

    public function update(Request $request, string $vehicle, string $observation): JsonResponse
    {
        $model = $this->vehicles->owned($this->session($request), $vehicle);
        $existing = ConditionObservation::query()
            ->with('workCatalogItem')
            ->where('vehicle_id', $model->id)
            ->where('id', $observation)
            ->firstOrFail();

        $validated = $request->validate([
            'wear_percent' => ['sometimes', 'integer', 'between:0,100'],
            'observed_at' => ['sometimes', 'date_format:Y-m-d', 'before_or_equal:today'],
            'mileage' => ['sometimes', 'nullable', 'array:value,unit'],
            'mileage.value' => ['required_with:mileage', 'integer', 'min:0'],
            'mileage.unit' => ['required_with:mileage', Rule::in(['km', 'mi'])],
            'source' => ['sometimes', Rule::in(['self', 'workshop'])],
            'note' => ['sometimes', 'nullable', 'string', 'max:2000'],
        ]);
        if (array_diff(array_keys($request->all()), [
            'wear_percent', 'observed_at', 'mileage', 'source', 'note',
        ]) !== []) {
            throw ValidationException::withMessages(['request' => [__('api.fields.unknown')]]);
        }
        if (isset($validated['mileage']) && $model->current_mileage !== null) {
            $inputKm = $validated['mileage']['unit'] === 'mi'
                ? (int) round($validated['mileage']['value'] * 1.609344)
                : $validated['mileage']['value'];
            $currentKm = $model->mileage_unit === 'mi'
                ? (int) round($model->current_mileage * 1.609344)
                : $model->current_mileage;
            if ($inputKm > $currentKm) {
                throw ValidationException::withMessages([
                    'mileage.value' => [__('api.fields.condition_mileage_above_current')],
                ]);
            }
        }

        if (array_key_exists('wear_percent', $validated)) {
            $existing->wear_percent = $validated['wear_percent'];
        }
        if (array_key_exists('observed_at', $validated)) {
            $existing->observed_at = $validated['observed_at'];
        }
        if (array_key_exists('source', $validated)) {
            $existing->source = $validated['source'];
        }
        if (array_key_exists('note', $validated)) {
            $existing->note = $validated['note'];
        }
        if (array_key_exists('mileage', $validated)) {
            $mileage = $validated['mileage'];
            $existing->mileage_value = $mileage['value'] ?? null;
            $existing->mileage_unit = $mileage['unit'] ?? null;
        }
        $existing->save();
        $existing->load('workCatalogItem');
        $snapshot = $this->plans->calculate($model);

        return response()->json([
            'observation' => (new ConditionObservationResource($existing))->resolve($request),
            'maintenance_plan_id' => $snapshot->id,
        ]);
    }

    public function destroy(Request $request, string $vehicle, string $observation): JsonResponse
    {
        $model = $this->vehicles->owned($this->session($request), $vehicle);
        $existing = ConditionObservation::query()
            ->where('vehicle_id', $model->id)
            ->where('id', $observation)
            ->firstOrFail();
        $existing->delete();
        $snapshot = $this->plans->calculate($model);

        return response()->json([
            'deleted' => true,
            'maintenance_plan_id' => $snapshot->id,
        ]);
    }

    private function session(Request $request): AnonymousSession
    {
        return $request->attributes->get('anonymous_session');
    }
}
