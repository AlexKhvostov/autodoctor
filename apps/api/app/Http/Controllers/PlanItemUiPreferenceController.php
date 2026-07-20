<?php

namespace App\Http\Controllers;

use App\Exceptions\ApiException;
use App\Http\Resources\PlanItemUiPreferenceResource;
use App\Models\AnonymousSession;
use App\Models\VehiclePlanItemUiPreference;
use App\Models\WorkCatalogItem;
use App\Services\IdempotencyService;
use App\Services\PlanCalculator;
use App\Services\VehicleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class PlanItemUiPreferenceController extends Controller
{
    public function __construct(
        private readonly VehicleService $vehicles,
        private readonly PlanCalculator $plans,
        private readonly IdempotencyService $idempotency,
    ) {}

    public function index(Request $request, string $vehicle): JsonResponse
    {
        $model = $this->vehicles->owned($this->session($request), $vehicle);
        $items = VehiclePlanItemUiPreference::query()
            ->with('workCatalogItem')
            ->where('vehicle_id', $model->id)
            ->orderBy(WorkCatalogItem::query()->select('code')
                ->whereColumn('work_catalog_items.id', 'vehicle_plan_item_ui_preferences.work_catalog_item_id'))
            ->get();

        return response()->json([
            'items' => PlanItemUiPreferenceResource::collection($items)->resolve($request),
        ]);
    }

    public function update(Request $request, string $vehicle): JsonResponse
    {
        $session = $this->session($request);
        $model = $this->vehicles->owned($session, $vehicle);
        $validated = $request->validate([
            'work_code' => ['required', 'string'],
            'collapsed' => ['required', 'boolean'],
            'version' => ['required', 'integer', 'min:0'],
        ]);
        if (array_diff(array_keys($request->all()), ['work_code', 'collapsed', 'version']) !== []) {
            throw ValidationException::withMessages(['request' => [__('api.fields.unknown')]]);
        }
        if (! $this->plans->applicableWorkCodes($model)->contains($validated['work_code'])) {
            throw ValidationException::withMessages(['work_code' => [__('api.fields.work_not_applicable')]]);
        }

        return $this->idempotency->execute(
            $request,
            'anonymous:'.$session->id,
            'putPlanItemUiPreference:'.$vehicle,
            function () use ($validated, $model, $request): JsonResponse {
                $work = WorkCatalogItem::query()->where('code', $validated['work_code'])->firstOrFail();
                $preference = VehiclePlanItemUiPreference::query()
                    ->where('vehicle_id', $model->id)
                    ->where('work_catalog_item_id', $work->id)
                    ->lockForUpdate()
                    ->first();
                if (($preference === null && $validated['version'] !== 0)
                    || ($preference !== null && $preference->version !== $validated['version'])) {
                    throw new ApiException('VERSION_CONFLICT', __('api.errors.preference_version_conflict'), 409);
                }
                if ($preference === null) {
                    $preference = new VehiclePlanItemUiPreference([
                        'vehicle_id' => $model->id,
                        'work_catalog_item_id' => $work->id,
                        'version' => 1,
                    ]);
                } else {
                    $preference->version++;
                }
                $preference->collapsed = $validated['collapsed'];
                $preference->save();
                $preference->setRelation('workCatalogItem', $work);

                return response()->json((new PlanItemUiPreferenceResource($preference))->resolve($request));
            },
        );
    }

    private function session(Request $request): AnonymousSession
    {
        return $request->attributes->get('anonymous_session');
    }
}
