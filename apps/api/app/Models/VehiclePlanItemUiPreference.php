<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VehiclePlanItemUiPreference extends Model
{
    use HasUuids;

    protected $guarded = [];

    protected function casts(): array
    {
        return ['collapsed' => 'boolean', 'version' => 'integer'];
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function workCatalogItem(): BelongsTo
    {
        return $this->belongsTo(WorkCatalogItem::class);
    }
}
