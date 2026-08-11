<?php

namespace App\Services;

use App\Models\GuestProfile;
use App\Models\GuestSkillObservation;
use App\Models\GuestSkillProfile;
use Illuminate\Support\Facades\DB;

class GuestSkillProfileService
{
    public function forProfile(GuestProfile $profile): GuestSkillProfile
    {
        return GuestSkillProfile::query()->firstOrCreate(
            ['guest_profile_id' => $profile->id],
            [
                'overall_score' => 50,
                'samples_count' => 0,
            ],
        );
    }

    /**
     * @param  array{
     *     knowledge_band: string,
     *     hands_on: string,
     *     detail_preference?: string|null
     * }  $answers
     */
    public function applyOnboardingQuiz(GuestProfile $profile, array $answers): GuestSkillProfile
    {
        $band = $this->normalizeKnowledgeBand($answers['knowledge_band']);
        $handsLevel = $this->normalizeHandsLevel($answers['hands_on']);
        $detail = $answers['detail_preference'] ?? null;

        $score = match ($band) {
            'never_tools' => 8,
            'scared' => 18,
            'novice' => 28,
            'basic' => 45,
            'curious' => 58,
            'confident' => 72,
            'advanced' => 86,
            'pro' => 96,
            default => 50,
        };

        $handsOn = match ($handsLevel) {
            'never', 'outside' => false,
            'sometimes' => null,
            'often', 'always', 'yes' => true,
            default => null,
        };

        // Legacy quiz value "yes" already mapped above via normalizeHandsLevel → often/always.
        if ($handsLevel === 'never') {
            $score = max(0, $score - 8);
        } elseif ($handsLevel === 'outside') {
            $score = max(0, $score - 4);
        } elseif ($handsLevel === 'often') {
            $score = min(100, $score + 4);
        } elseif ($handsLevel === 'always') {
            $score = min(100, $score + 8);
        }

        if ($detail === 'simple') {
            $score = max(0, $score - 5);
        } elseif ($detail === 'detailed') {
            $score = min(100, $score + 5);
        }

        return DB::transaction(function () use ($profile, $band, $handsOn, $handsLevel, $score): GuestSkillProfile {
            $skill = $this->forProfile($profile);
            $before = (int) $skill->overall_score;

            $skill->forceFill([
                'overall_score' => $score,
                'self_reported_band' => $band,
                'hands_on' => $handsOn,
                'hands_on_level' => $handsLevel,
                'samples_count' => max(1, (int) $skill->samples_count),
                'last_assessed_at' => now(),
            ])->save();

            GuestSkillObservation::query()->create([
                'guest_skill_profile_id' => $skill->id,
                'delta' => $score - $before,
                'source' => GuestSkillObservation::SOURCE_ONBOARDING_QUIZ,
                'raw_signal' => 'quiz:'.$band.':'.$handsLevel,
                'score_before' => $before,
                'score_after' => $score,
            ]);

            return $skill->fresh();
        });
    }

    public function applyChatSignal(
        GuestProfile $profile,
        int $delta,
        ?string $rawSignal = null,
    ): GuestSkillProfile {
        $delta = max(-15, min(15, $delta));
        if ($delta === 0) {
            return $this->forProfile($profile);
        }

        return DB::transaction(function () use ($profile, $delta, $rawSignal): GuestSkillProfile {
            $skill = $this->forProfile($profile);
            $before = (int) $skill->overall_score;
            $samples = (int) $skill->samples_count;
            $weight = $samples < 5 ? 0.25 : 0.15;
            $target = $before + $delta;
            $after = (int) round(((1 - $weight) * $before) + ($weight * $target));
            $after = max(0, min(100, $after));

            $skill->forceFill([
                'overall_score' => $after,
                'samples_count' => $samples + 1,
                'last_assessed_at' => now(),
            ])->save();

            GuestSkillObservation::query()->create([
                'guest_skill_profile_id' => $skill->id,
                'delta' => $delta,
                'source' => GuestSkillObservation::SOURCE_CHAT,
                'raw_signal' => $rawSignal !== null ? mb_substr($rawSignal, 0, 255) : null,
                'score_before' => $before,
                'score_after' => $after,
            ]);

            return $skill->fresh();
        });
    }

    /**
     * @return array{
     *     overall_score: int,
     *     band: string,
     *     self_reported_band: ?string,
     *     hands_on: ?bool,
     *     hands_on_level: ?string,
     *     samples_count: int,
     *     last_assessed_at: ?string,
     *     assessed: bool
     * }
     */
    public function toArray(GuestSkillProfile $skill): array
    {
        return [
            'overall_score' => (int) $skill->overall_score,
            'band' => $skill->band(),
            'self_reported_band' => $skill->self_reported_band,
            'hands_on' => $skill->hands_on,
            'hands_on_level' => $skill->resolvedHandsOnLevel(),
            'samples_count' => (int) $skill->samples_count,
            'last_assessed_at' => $skill->last_assessed_at?->toIso8601String(),
            'assessed' => $skill->self_reported_band !== null || (int) $skill->samples_count > 0,
        ];
    }

    private function normalizeKnowledgeBand(string $band): string
    {
        if (in_array($band, GuestSkillProfile::KNOWLEDGE_LEVELS, true)) {
            return $band;
        }

        return match ($band) {
            GuestSkillProfile::BAND_NOVICE => 'novice',
            GuestSkillProfile::BAND_BASIC => 'basic',
            GuestSkillProfile::BAND_CONFIDENT => 'confident',
            default => 'basic',
        };
    }

    private function normalizeHandsLevel(string $level): string
    {
        // Legacy quiz / API value.
        if ($level === 'yes') {
            return 'often';
        }

        if (in_array($level, GuestSkillProfile::HANDS_LEVELS, true)) {
            return $level;
        }

        return 'sometimes';
    }
}
