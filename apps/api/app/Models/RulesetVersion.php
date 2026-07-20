<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class RulesetVersion extends Model
{
    use HasUuids;

    protected $fillable = ['version', 'content_hash', 'published_at'];

    protected function casts(): array
    {
        return ['published_at' => 'immutable_datetime'];
    }

    public function rules(): HasMany
    {
        return $this->hasMany(MaintenanceRule::class);
    }

    public function snapshots(): HasMany
    {
        return $this->hasMany(MaintenancePlanSnapshot::class);
    }
}
