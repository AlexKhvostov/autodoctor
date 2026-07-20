<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Vehicle extends Model
{
    use HasUuids;

    protected $guarded = [];

    protected $hidden = ['vin_ciphertext', 'vin_hash', 'vin_last4'];

    protected function casts(): array
    {
        return [
            'vin_ciphertext' => 'encrypted',
            'production_year' => 'integer',
            'first_use_date' => 'immutable_date',
            'current_mileage' => 'integer',
            'version' => 'integer',
        ];
    }

    public function configuration(): BelongsTo
    {
        return $this->belongsTo(VehicleConfiguration::class, 'configuration_id');
    }

    public function anonymousSession(): BelongsTo
    {
        return $this->belongsTo(AnonymousSession::class);
    }

    public function mileageObservations(): HasMany
    {
        return $this->hasMany(MileageObservation::class);
    }

    public function maintenancePlanSnapshots(): HasMany
    {
        return $this->hasMany(MaintenancePlanSnapshot::class);
    }

    public function historyAnswers(): HasMany
    {
        return $this->hasMany(HistoryAnswer::class);
    }

    public function serviceRecords(): HasMany
    {
        return $this->hasMany(ServiceRecord::class);
    }

    public function conditionObservations(): HasMany
    {
        return $this->hasMany(ConditionObservation::class);
    }

    public function planItemUiPreferences(): HasMany
    {
        return $this->hasMany(VehiclePlanItemUiPreference::class);
    }
}
