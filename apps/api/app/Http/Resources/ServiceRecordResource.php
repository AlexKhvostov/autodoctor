<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ServiceRecordResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $locale = app()->getLocale() === 'en' ? 'en' : 'ru';

        return [
            'id' => $this->resource->id,
            'vehicle_id' => $this->resource->vehicle_id,
            'service_date' => $this->resource->service_date->format('Y-m-d'),
            'mileage' => $this->resource->mileage_value === null ? null : [
                'value' => $this->resource->mileage_value,
                'unit' => $this->resource->mileage_unit,
            ],
            'evidence_source' => $this->resource->evidence_source,
            'note' => $this->resource->note,
            'items' => $this->resource->items
                ->sortBy(fn ($item): string => $item->workCatalogItem->code)
                ->map(fn ($item): array => [
                    'work_code' => $item->workCatalogItem->code,
                    'title' => $item->workCatalogItem->localized_name[$locale],
                ])->values()->all(),
            'created_at' => $this->resource->created_at->toISOString(),
        ];
    }
}
