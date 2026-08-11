<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GuestSkillObservation extends Model
{
    use HasUuids;

    public const SOURCE_ONBOARDING_QUIZ = 'onboarding_quiz';

    public const SOURCE_CHAT = 'chat';

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'delta' => 'integer',
            'score_before' => 'integer',
            'score_after' => 'integer',
        ];
    }

    public function skillProfile(): BelongsTo
    {
        return $this->belongsTo(GuestSkillProfile::class, 'guest_skill_profile_id');
    }
}
