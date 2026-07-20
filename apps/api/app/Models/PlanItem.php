<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PlanItem extends Model
{
    use HasUuids;

    protected $fillable = [
        'snapshot_id', 'rule_id', 'status', 'urgency', 'due_mileage_km',
        'due_date', 'interval_metadata', 'warnings', 'explanation',
    ];

    protected function casts(): array
    {
        return [
            'due_mileage_km' => 'integer',
            'due_date' => 'immutable_date',
            'interval_metadata' => 'array',
            'warnings' => 'array',
            'explanation' => 'array',
        ];
    }

    public function snapshot(): BelongsTo
    {
        return $this->belongsTo(MaintenancePlanSnapshot::class, 'snapshot_id');
    }

    public function rule(): BelongsTo
    {
        return $this->belongsTo(MaintenanceRule::class);
    }
}
