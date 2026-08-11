<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class GuestSkillProfile extends Model
{
    use HasUuids;

    /** Coarse band derived from score (used by prompt rules). */
    public const BAND_NOVICE = 'novice';

    public const BAND_BASIC = 'basic';

    public const BAND_CONFIDENT = 'confident';

    /** Self-reported knowledge ladder (profile + quiz). */
    public const KNOWLEDGE_LEVELS = [
        'never_tools',
        'scared',
        'novice',
        'basic',
        'curious',
        'confident',
        'advanced',
        'pro',
    ];

    /** Self-reported readiness to inspect the car. */
    public const HANDS_LEVELS = [
        'never',
        'outside',
        'sometimes',
        'often',
        'always',
    ];

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'overall_score' => 'integer',
            'hands_on' => 'boolean',
            'samples_count' => 'integer',
            'last_assessed_at' => 'datetime',
        ];
    }

    public function guestProfile(): BelongsTo
    {
        return $this->belongsTo(GuestProfile::class);
    }

    public function observations(): HasMany
    {
        return $this->hasMany(GuestSkillObservation::class);
    }

    public function band(): string
    {
        return match (true) {
            $this->overall_score <= 35 => self::BAND_NOVICE,
            $this->overall_score <= 65 => self::BAND_BASIC,
            default => self::BAND_CONFIDENT,
        };
    }

    public function resolvedHandsOnLevel(): ?string
    {
        if (is_string($this->hands_on_level) && $this->hands_on_level !== '') {
            return $this->hands_on_level;
        }

        return match ($this->hands_on) {
            true => 'often',
            false => 'never',
            default => null,
        };
    }
}
