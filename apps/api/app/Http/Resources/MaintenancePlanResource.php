<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MaintenancePlanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->resource->id,
            'vehicle_id' => $this->resource->vehicle_id,
            'ruleset_version' => $this->resource->rulesetVersion->version,
            'algorithm_version' => $this->resource->algorithm_version,
            'config_version' => $this->resource->config_version,
            'as_of_date' => $this->resource->input_snapshot['as_of_date'],
            'input_hash' => $this->resource->input_hash,
            'content_hash' => $this->resource->content_hash,
            'calculated_at' => $this->resource->calculated_at->toISOString(),
            'soon_threshold' => [
                'mileage_km' => (int) config('maintenance.soon_threshold.mileage_km'),
                'days' => (int) config('maintenance.soon_threshold.days'),
            ],
            'items' => MaintenanceItemResource::collection($this->resource->items)->resolve($request),
            'warnings' => $this->resource->warnings,
        ];
    }
}
