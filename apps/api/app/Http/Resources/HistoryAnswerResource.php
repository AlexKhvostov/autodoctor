<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HistoryAnswerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->resource->id,
            'vehicle_id' => $this->resource->vehicle_id,
            'work_code' => $this->resource->workCatalogItem->code,
            'answer' => $this->resource->answer,
            'performed_date' => $this->resource->performed_date?->format('Y-m-d'),
            'performed_mileage_km' => $this->resource->performed_mileage_km,
            'created_at' => $this->resource->created_at->toISOString(),
            'updated_at' => $this->resource->updated_at->toISOString(),
            'version' => $this->resource->version,
        ];
    }
}
