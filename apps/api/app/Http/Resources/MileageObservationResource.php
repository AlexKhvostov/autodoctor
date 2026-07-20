<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MileageObservationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->resource->id,
            'vehicle_id' => $this->resource->vehicle_id,
            'mileage' => [
                'value' => $this->resource->value,
                'unit' => $this->resource->unit,
            ],
            'source' => $this->resource->source,
            'observed_at' => $this->resource->observed_at->toISOString(),
            'created_at' => $this->resource->created_at->toISOString(),
        ];
    }
}
