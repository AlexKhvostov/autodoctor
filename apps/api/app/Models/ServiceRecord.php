<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ServiceRecord extends Model
{
    use HasUuids;

    protected $fillable = [
        'vehicle_id',
        'service_date',
        'mileage_value',
        'mileage_unit',
        'evidence_source',
        'note',
        'version',
    ];

    protected function casts(): array
    {
        return [
            'service_date' => 'immutable_date',
            'mileage_value' => 'integer',
            'version' => 'integer',
        ];
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(ServiceRecordItem::class);
    }
}
