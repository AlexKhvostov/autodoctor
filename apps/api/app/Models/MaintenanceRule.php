<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MaintenanceRule extends Model
{
    use HasUuids;

    protected $fillable = [
        'ruleset_version_id', 'source_id', 'work_catalog_item_id', 'work_code',
        'rule_level', 'rule_type', 'rule_kind', 'mileage_interval_km',
        'time_interval_days', 'applicability', 'localized_content', 'criticality', 'version',
    ];

    protected function casts(): array
    {
        return [
            'mileage_interval_km' => 'integer',
            'time_interval_days' => 'integer',
            'applicability' => 'array',
            'localized_content' => 'array',
            'version' => 'integer',
        ];
    }

    public function rulesetVersion(): BelongsTo
    {
        return $this->belongsTo(RulesetVersion::class);
    }

    public function source(): BelongsTo
    {
        return $this->belongsTo(MaintenanceSource::class);
    }

    public function workCatalogItem(): BelongsTo
    {
        return $this->belongsTo(WorkCatalogItem::class);
    }

    public function planItems(): HasMany
    {
        return $this->hasMany(PlanItem::class, 'rule_id');
    }
}
