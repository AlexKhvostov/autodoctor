<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConditionObservationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->resource->id,
            'vehicle_id' => $this->resource->vehicle_id,
            'work_code' => $this->resource->workCatalogItem->code,
            'wear_percent' => $this->resource->wear_percent,
            'remaining_percent' => 100 - $this->resource->wear_percent,
            'observed_at' => $this->resource->observed_at->format('Y-m-d'),
            'mileage' => $this->resource->mileage_value === null ? null : [
                'value' => $this->resource->mileage_value,
                'unit' => $this->resource->mileage_unit,
            ],
            'source' => $this->resource->source,
            'note' => $this->resource->note,
            'created_at' => $this->resource->created_at->toISOString(),
        ];
    }
}
