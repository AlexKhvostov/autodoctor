<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HistoryAnswer extends Model
{
    use HasUuids;

    public const VALUES = [
        'done_known',
        'done_unknown',
        'not_done',
        'unknown',
        'not_applicable',
    ];

    protected $fillable = [
        'vehicle_id',
        'work_catalog_item_id',
        'answer',
        'performed_date',
        'performed_mileage_km',
        'version',
    ];

    protected function casts(): array
    {
        return [
            'performed_date' => 'immutable_date',
            'performed_mileage_km' => 'integer',
            'version' => 'integer',
        ];
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
