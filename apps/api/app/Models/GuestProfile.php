<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;
use Illuminate\Database\Eloquent\Relations\HasOne;

class GuestProfile extends Model
{
    use HasUuids;

    protected $guarded = [];

    public function sessions(): HasMany
    {
        return $this->hasMany(AnonymousSession::class);
    }

    public function skillProfile(): HasOne
    {
        return $this->hasOne(GuestSkillProfile::class);
    }

    public function agentPreference(): HasOne
    {
        return $this->hasOne(AgentPreference::class);
    }

    public function agentFuelWallet(): HasOne
    {
        return $this->hasOne(AgentFuelWallet::class);
    }

    public function aiUsageEvents(): HasMany
    {
        return $this->hasMany(AiUsageEvent::class);
    }

    public function vehicles(): HasManyThrough
    {
        return $this->hasManyThrough(
            Vehicle::class,
            AnonymousSession::class,
            'guest_profile_id',
            'anonymous_session_id',
            'id',
            'id',
        );
    }

    public function aiNotes(): HasMany
    {
        return $this->hasMany(GuestProfileAiNote::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function assistantThreads(): HasMany
    {
        return $this->hasMany(AssistantThread::class);
    }

    public function adminLabel(): string
    {
        if (filled($this->telegram_username)) {
            return '@'.$this->telegram_username;
        }
        if ($this->telegram_id) {
            return 'Telegram '.$this->telegram_id;
        }
        if (filled($this->telegram_first_name)) {
            return (string) $this->telegram_first_name;
        }
        if (filled($this->user?->email)) {
            return (string) $this->user->email;
        }
        if (filled($this->user?->name)) {
            return (string) $this->user->name;
        }

        return 'Гость '.mb_substr((string) $this->id, 0, 8);
    }
}
