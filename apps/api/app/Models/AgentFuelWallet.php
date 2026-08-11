<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AgentFuelWallet extends Model
{
    use HasUuids;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'balance_ml' => 'integer',
            'capacity_ml' => 'integer',
            'lifetime_consumed_ml' => 'integer',
            'lifetime_prompt_tokens' => 'integer',
            'lifetime_completion_tokens' => 'integer',
            'lifetime_estimated_cost' => 'float',
        ];
    }

    public function guestProfile(): BelongsTo
    {
        return $this->belongsTo(GuestProfile::class);
    }

    public function percentFull(): int
    {
        $capacity = max(1, (int) $this->capacity_ml);

        return (int) max(0, min(100, round(((int) $this->balance_ml / $capacity) * 100)));
    }
}
