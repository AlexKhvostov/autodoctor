<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConsumableResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $maintenanceItem = (new MaintenanceItemResource($this->resource))->resolve($request);
        $rule = $this->resource->rule;
        $slug = str_replace('_', '-', $rule->work_code);
        $explanation = $this->resource->explanation;

        return [
            'id' => $slug,
            'vehicle_id' => $this->resource->snapshot->vehicle_id,
            'work_code' => $rule->work_code,
            'title' => $maintenanceItem['title'],
            'kind' => $rule->rule_kind,
            'status' => $this->resource->status,
            'criticality' => $rule->criticality,
            'urgency' => $this->resource->urgency,
            'future_importance' => $maintenanceItem['presentation_importance'] ?? (
                $rule->criticality === 'safety_critical' ? 'critical_attention' : 'recommended'
            ),
            'due' => $maintenanceItem['due'],
            'basis' => $maintenanceItem['basis'],
            'requires_check_now' => $maintenanceItem['requires_check_now'],
            'history_impact' => $maintenanceItem['history_impact'],
            'history_state' => $maintenanceItem['history_state'],
            'source' => $maintenanceItem['source'],
            'source_rule_id' => $rule->id,
            'plan_item_link' => [
                'id' => $slug,
                'href' => '/roadmap/items/'.$slug,
            ],
            'presentation' => $rule->rule_kind === 'interval_based'
                ? $this->intervalPresentation($rule, $maintenanceItem, $explanation)
                : [
                    'kind' => 'condition_based',
                    'inspection_state' => $explanation['inspection_state'],
                    'latest_observation' => $explanation['latest_observation'] ?? null,
                    'thresholds' => $explanation['condition_thresholds'] ?? null,
                    'derived_state' => $explanation['wear_derived_state'] ?? 'unknown',
                ],
        ];
    }

    private function intervalPresentation($rule, array $item, array $explanation): array
    {
        return [
            'kind' => 'interval_based',
            'time' => $rule->time_interval_days === null ? null : [
                'used_fraction' => $explanation['time_used_fraction'],
                'due' => $item['due']['date'] === null ? null : [
                    'mileage' => null,
                    'date' => $item['due']['date'],
                ],
            ],
            'mileage' => $rule->mileage_interval_km === null ? null : [
                'used_fraction' => $explanation['mileage_used_fraction'],
                'due' => $item['due']['mileage'] === null ? null : [
                    'mileage' => $item['due']['mileage'],
                    'date' => null,
                ],
            ],
            'effective_used_fraction' => $explanation['effective_used_fraction'],
            'effective_trigger' => $explanation['effective_trigger'],
            'derived_state' => $explanation['derived_state'],
            'thresholds' => [
                'warning_at' => (float) config('maintenance.consumable_thresholds.warning_at'),
                'danger_at' => (float) config('maintenance.consumable_thresholds.danger_at'),
            ],
        ];
    }
}
