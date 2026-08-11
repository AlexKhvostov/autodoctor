<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\AgentFuelWallet;
use App\Models\AgentPreference;
use App\Models\AiUsageEvent;
use App\Models\AnonymousSession;
use App\Models\AssistantThread;
use App\Models\GuestProfile;
use App\Models\GuestProfileAiNote;
use App\Models\GuestSkillProfile;
use App\Models\User;
use App\Models\Vehicle;
use Illuminate\Support\Facades\DB;

/**
 * Best-practice guest → account ownership:
 * - free guest data becomes the user's on first Google login;
 * - vehicles are owned by user_id, not only by an ephemeral session;
 * - a later free guest profile on the same account is merged in.
 */
class AccountOwnershipService
{
    public function attachGuestProfile(User $user, ?string $guestProfileId): GuestProfile
    {
        return DB::transaction(function () use ($user, $guestProfileId): GuestProfile {
            $canonical = GuestProfile::query()
                ->where('user_id', $user->id)
                ->lockForUpdate()
                ->first();

            if ($canonical !== null) {
                if (filled($guestProfileId) && $guestProfileId !== $canonical->id) {
                    $this->mergeFreeGuestProfile($user, $canonical, $guestProfileId);
                }
                $this->claimVehiclesForProfile($user, $canonical);

                return $canonical->fresh() ?? $canonical;
            }

            if (filled($guestProfileId)) {
                $profile = GuestProfile::query()->lockForUpdate()->find($guestProfileId);
                if ($profile === null) {
                    throw new ApiException(
                        'GUEST_PROFILE_NOT_FOUND',
                        __('api.errors.guest_profile_not_found'),
                        404,
                    );
                }
                if ($profile->user_id !== null && (int) $profile->user_id !== (int) $user->id) {
                    throw new ApiException(
                        'GUEST_PROFILE_OWNED',
                        __('api.errors.guest_profile_owned'),
                        409,
                    );
                }
                $profile->forceFill(['user_id' => $user->id])->save();
                $this->claimVehiclesForProfile($user, $profile);

                return $profile;
            }

            $profile = GuestProfile::query()->create(['user_id' => $user->id]);
            $this->claimVehiclesForProfile($user, $profile);

            return $profile;
        });
    }

    /**
     * Repair path: if the session already belongs to a linked account,
     * claim any still-unclaimed vehicles under that guest profile.
     */
    public function ensureClaimedForSession(AnonymousSession $session): ?int
    {
        $session->loadMissing('guestProfile');
        $profile = $session->guestProfile;
        $userId = $profile?->user_id;
        if ($profile === null || $userId === null) {
            return null;
        }

        $this->claimVehiclesForProfile(
            User::query()->findOrFail($userId),
            $profile,
        );

        return (int) $userId;
    }

    public function claimVehiclesForProfile(User $user, GuestProfile $profile): int
    {
        $sessionIds = AnonymousSession::query()
            ->where('guest_profile_id', $profile->id)
            ->pluck('id');

        if ($sessionIds->isEmpty()) {
            return 0;
        }

        return Vehicle::query()
            ->whereNull('user_id')
            ->whereIn('anonymous_session_id', $sessionIds)
            ->update(['user_id' => $user->id]);
    }

    private function mergeFreeGuestProfile(User $user, GuestProfile $canonical, string $orphanId): void
    {
        $orphan = GuestProfile::query()->lockForUpdate()->find($orphanId);
        if ($orphan === null) {
            return;
        }
        if ($orphan->user_id !== null) {
            return;
        }

        AnonymousSession::query()
            ->where('guest_profile_id', $orphan->id)
            ->update(['guest_profile_id' => $canonical->id]);

        GuestProfileAiNote::query()
            ->where('guest_profile_id', $orphan->id)
            ->update(['guest_profile_id' => $canonical->id]);

        AssistantThread::query()
            ->where('guest_profile_id', $orphan->id)
            ->update(['guest_profile_id' => $canonical->id]);

        AiUsageEvent::query()
            ->where('guest_profile_id', $orphan->id)
            ->update(['guest_profile_id' => $canonical->id]);

        $this->moveSingletonIfAbsent(
            GuestSkillProfile::class,
            $canonical->id,
            $orphan->id,
        );
        $this->moveSingletonIfAbsent(
            AgentPreference::class,
            $canonical->id,
            $orphan->id,
        );
        $this->mergeFuelWallets($canonical->id, $orphan->id);

        $this->claimVehiclesForProfile($user, $canonical);

        // Drop emptied orphan profile (related rows already moved or removed).
        GuestSkillProfile::query()->where('guest_profile_id', $orphan->id)->delete();
        AgentPreference::query()->where('guest_profile_id', $orphan->id)->delete();
        AgentFuelWallet::query()->where('guest_profile_id', $orphan->id)->delete();
        $orphan->delete();
    }

    private function mergeFuelWallets(string $canonicalId, string $orphanId): void
    {
        $canonical = AgentFuelWallet::query()->where('guest_profile_id', $canonicalId)->first();
        $orphan = AgentFuelWallet::query()->where('guest_profile_id', $orphanId)->first();
        if ($orphan === null) {
            return;
        }
        if ($canonical === null) {
            $orphan->forceFill(['guest_profile_id' => $canonicalId])->save();

            return;
        }

        $canonical->forceFill([
            'balance_ml' => (int) $canonical->balance_ml + (int) $orphan->balance_ml,
            'capacity_ml' => max((int) $canonical->capacity_ml, (int) $orphan->capacity_ml),
            'lifetime_consumed_ml' => (int) $canonical->lifetime_consumed_ml + (int) $orphan->lifetime_consumed_ml,
            'lifetime_prompt_tokens' => (int) $canonical->lifetime_prompt_tokens + (int) $orphan->lifetime_prompt_tokens,
            'lifetime_completion_tokens' => (int) $canonical->lifetime_completion_tokens + (int) $orphan->lifetime_completion_tokens,
            'lifetime_estimated_cost' => (float) $canonical->lifetime_estimated_cost + (float) $orphan->lifetime_estimated_cost,
        ])->save();
        $orphan->delete();
    }

    /**
     * @param  class-string<\Illuminate\Database\Eloquent\Model>  $model
     */
    private function moveSingletonIfAbsent(string $model, string $canonicalId, string $orphanId): void
    {
        $hasCanonical = $model::query()->where('guest_profile_id', $canonicalId)->exists();
        if ($hasCanonical) {
            $model::query()->where('guest_profile_id', $orphanId)->delete();

            return;
        }

        $model::query()
            ->where('guest_profile_id', $orphanId)
            ->update(['guest_profile_id' => $canonicalId]);
    }
}
