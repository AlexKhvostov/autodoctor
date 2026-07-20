<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PlanItemUiPreferenceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'vehicle_id' => $this->resource->vehicle_id,
            'work_code' => $this->resource->workCatalogItem->code,
            'collapsed' => $this->resource->collapsed,
            'version' => $this->resource->version,
            'created_at' => $this->resource->created_at->toISOString(),
            'updated_at' => $this->resource->updated_at->toISOString(),
        ];
    }
}
