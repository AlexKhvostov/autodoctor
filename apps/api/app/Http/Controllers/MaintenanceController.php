<?php

namespace App\Http\Controllers;

use App\Http\Resources\ConsumableResource;
use App\Http\Resources\MaintenancePlanResource;
use App\Http\Resources\VehicleTimelineResource;
use App\Models\AnonymousSession;
use App\Services\PlanCalculator;
use App\Services\VehicleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MaintenanceController extends Controller
{
    public function __construct(
        private readonly VehicleService $vehicles,
        private readonly PlanCalculator $plans,
    ) {}

    public function show(Request $request, string $vehicle): JsonResponse
    {
        $model = $this->vehicles->owned($this->session($request), $vehicle);
        $snapshot = $this->plans->calculate($model);

        return response()->json((new MaintenancePlanResource($snapshot))->resolve($request));
    }

    public function timeline(Request $request, string $vehicle): JsonResponse
    {
        $model = $this->vehicles->owned($this->session($request), $vehicle);
        $snapshot = $this->plans->calculate($model);
        $snapshot->setRelation('vehicle', $model);

        return response()->json((new VehicleTimelineResource($snapshot))->resolve($request));
    }

    public function consumables(Request $request, string $vehicle): JsonResponse
    {
        $pagination = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', Rule::in([20, 50, 100])],
        ]);
        $model = $this->vehicles->owned($this->session($request), $vehicle);
        $snapshot = $this->plans->calculate($model);
        $page = $pagination['page'] ?? 1;
        $perPage = $pagination['per_page'] ?? 20;
        $total = $snapshot->items->count();
        $items = $snapshot->items->forPage($page, $perPage)->values();
        foreach ($items as $item) {
            $item->setRelation('snapshot', $snapshot);
        }

        return response()->json([
            'items' => ConsumableResource::collection($items)->resolve($request),
            'meta' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'total_pages' => max(1, (int) ceil($total / $perPage)),
            ],
            'warnings' => $snapshot->warnings,
        ]);
    }

    private function session(Request $request): AnonymousSession
    {
        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');

        return $session;
    }
}
