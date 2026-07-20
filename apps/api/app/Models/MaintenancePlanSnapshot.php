<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MaintenancePlanSnapshot extends Model
{
    use HasUuids;

    protected $fillable = [
        'vehicle_id', 'ruleset_version_id', 'algorithm_version', 'config_version',
        'input_snapshot', 'input_hash', 'content_hash', 'warnings', 'calculated_at',
    ];

    protected function casts(): array
    {
        return [
            'input_snapshot' => 'array',
            'warnings' => 'array',
            'calculated_at' => 'immutable_datetime',
        ];
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function rulesetVersion(): BelongsTo
    {
        return $this->belongsTo(RulesetVersion::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(PlanItem::class, 'snapshot_id');
    }
}
