<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ServiceRecordItem extends Model
{
    use HasUuids;

    protected $fillable = ['service_record_id', 'work_catalog_item_id'];

    public function serviceRecord(): BelongsTo
    {
        return $this->belongsTo(ServiceRecord::class);
    }

    public function workCatalogItem(): BelongsTo
    {
        return $this->belongsTo(WorkCatalogItem::class);
    }
}
