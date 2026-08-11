<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AiUsageEvent extends Model
{
    use HasUuids;

    public const SOURCE_CHAT = 'chat';

    public const SOURCE_MEMORY = 'memory';

    public const SOURCE_TITLE = 'title';

    public const SOURCE_REFUEL = 'refuel';

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'prompt_tokens' => 'integer',
            'completion_tokens' => 'integer',
            'total_tokens' => 'integer',
            'fuel_ml' => 'integer',
            'estimated_cost' => 'float',
            'tokens_estimated' => 'boolean',
        ];
    }

    public function guestProfile(): BelongsTo
    {
        return $this->belongsTo(GuestProfile::class);
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }
}
