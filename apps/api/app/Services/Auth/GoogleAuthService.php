<?php

namespace App\Services\Auth;

use App\Models\GuestProfile;
use App\Models\User;
use App\Services\AccountOwnershipService;
use Illuminate\Support\Str;

class GoogleAuthService
{
    public function __construct(
        private readonly GoogleIdTokenVerifier $verifier,
        private readonly AccountOwnershipService $ownership,
    ) {}

    /**
     * @return array{user: User, token: string, guest_profile_id: string}
     */
    public function loginWithIdToken(string $idToken, ?string $guestProfileId = null): array
    {
        $identity = $this->verifier->verify($idToken);

        $user = User::query()->where('google_id', $identity['sub'])->first();
        if ($user === null) {
            $user = User::query()->where('email', $identity['email'])->first();
        }

        if ($user === null) {
            $user = User::query()->create([
                'name' => $identity['name'] ?: Str::before($identity['email'], '@'),
                'email' => $identity['email'],
                'avatar_url' => $identity['picture'],
                'google_id' => $identity['sub'],
                'email_verified_at' => $identity['email_verified'] ? now() : null,
                'password' => Str::password(48),
                'is_admin' => false,
            ]);
        } else {
            $user->forceFill([
                'google_id' => $identity['sub'],
                'name' => $identity['name'] ?: $user->name,
                'avatar_url' => $identity['picture'] ?: $user->avatar_url,
                'email_verified_at' => $user->email_verified_at ?? ($identity['email_verified'] ? now() : null),
            ])->save();
        }

        $profile = $this->ownership->attachGuestProfile($user, $guestProfileId);

        $token = $user->createToken('mobile')->plainTextToken;

        return [
            'user' => $user,
            'token' => $token,
            'guest_profile_id' => $profile->id,
        ];
    }
}
