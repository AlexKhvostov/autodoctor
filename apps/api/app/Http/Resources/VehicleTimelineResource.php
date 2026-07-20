<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class VehicleTimelineResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $snapshot = $this->resource;
        $vehicle = $snapshot->vehicle;
        $lastObservation = $vehicle->mileageObservations()
            ->latest('observed_at')
            ->latest('created_at')
            ->first();

        foreach ($snapshot->items as $item) {
            $item->setRelation('snapshot', $snapshot);
        }
        $serviceItems = $vehicle->serviceRecords()
            ->with('items.workCatalogItem')
            ->orderByDesc('service_date')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->get()
            ->map(function ($record) use ($request): array {
                $resource = (new ServiceRecordResource($record))->resolve($request);
                $titles = collect($resource['items'])->pluck('title')->all();
                $title = app()->getLocale() === 'en'
                    ? 'Service: '.implode(', ', $titles)
                    : 'Обслуживание: '.implode(', ', $titles);

                return [
                    'type' => 'service_record',
                    'occurred_at' => $resource['service_date'],
                    'service_record' => $resource,
                    'presentation' => [
                        'title' => $title,
                        'temporal' => [
                            'kind' => 'moment',
                            'at' => $resource['service_date'],
                        ],
                        'mileage' => $resource['mileage'],
                        'primary_category' => 'maintenance_repair',
                        'action_level' => 'info',
                        'basis' => 'confirmed',
                    ],
                ];
            });
        $planItems = $snapshot->items->where('status', '!=', 'not_applicable')->map(function ($item) use ($request): array {
            $planItem = (new MaintenanceItemResource($item))->resolve($request);
            $conditionBased = $item->rule->rule_kind === 'condition_based';
            $confirmed = $planItem['history_state']['answer'] === 'done_known'
                || ($item->explanation['latest_observation'] ?? null) !== null;

            return [
                'type' => 'plan_item',
                'plan_item' => $planItem,
                'presentation' => [
                    'title' => $planItem['title'],
                    'temporal' => $planItem['due']['date'] === null ? null : [
                        'kind' => 'moment',
                        'at' => $planItem['due']['date'],
                    ],
                    'mileage' => $planItem['due']['mileage'],
                    'primary_category' => $conditionBased ? 'inspection' : 'maintenance_repair',
                    'action_level' => $this->actionLevel([
                        $item->status,
                        $item->urgency,
                        $item->rule->criticality,
                        $planItem['presentation_importance'],
                        $planItem['requires_check_now'] ? 'requires_check_now' : null,
                    ]),
                    'basis' => $confirmed ? 'confirmed' : 'missing_data',
                ],
            ];
        });

        return [
            'vehicle_id' => $vehicle->id,
            'generated_at' => now()->toISOString(),
            'last_confirmed_observation' => $lastObservation === null ? null : [
                'id' => $lastObservation->id,
                'vehicle_id' => $lastObservation->vehicle_id,
                'mileage' => [
                    'value' => $lastObservation->value,
                    'unit' => $lastObservation->unit,
                ],
                'source' => $lastObservation->source,
                'observed_at' => $lastObservation->observed_at->toISOString(),
                'created_at' => $lastObservation->created_at->toISOString(),
            ],
            'nearest_consumables' => ConsumableResource::collection(
                $snapshot->items->where('status', '!=', 'not_applicable')->take(3),
            )->resolve($request),
            'items' => $serviceItems->concat($planItems)->values()->all(),
        ];
    }

    private function actionLevel(array $signals): string
    {
        $levels = [
            'info' => 0,
            'recommendation' => 1,
            'attention' => 2,
            'required' => 3,
            'critical' => 4,
        ];
        $resolved = 'info';

        foreach ($signals as $signal) {
            $candidate = match ($signal) {
                'immediate', 'critical_attention' => 'critical',
                'high', 'overdue', 'requires_check_now' => 'required',
                'medium', 'soon' => 'attention',
                'recommended' => 'recommendation',
                default => 'info',
            };
            if ($levels[$candidate] > $levels[$resolved]) {
                $resolved = $candidate;
            }
        }

        return $resolved;
    }
}
