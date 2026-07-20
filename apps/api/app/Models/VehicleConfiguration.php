<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasOne;

class VehicleConfiguration extends Model
{
    use HasUuids;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'engine_displacement_cc' => 'integer',
            'engine_power_kw' => 'decimal:2',
            'transmission_gears' => 'integer',
            'field_provenance' => 'array',
            'confirmed_at' => 'immutable_datetime',
        ];
    }

    public function vehicle(): HasOne
    {
        return $this->hasOne(Vehicle::class, 'configuration_id');
    }
}
