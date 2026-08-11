<?php

namespace App\Http\Controllers;

use App\Services\Auth\GoogleAuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(
        private readonly GoogleAuthService $googleAuth,
    ) {}

    public function google(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id_token' => ['required', 'string', 'min:20'],
            'guest_profile_id' => ['sometimes', 'nullable', 'uuid', 'exists:guest_profiles,id'],
        ]);

        $result = $this->googleAuth->loginWithIdToken(
            $data['id_token'],
            $data['guest_profile_id'] ?? null,
        );

        $user = $result['user'];

        return response()->json([
            'token' => $result['token'],
            'token_type' => 'Bearer',
            'guest_profile_id' => $result['guest_profile_id'],
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'avatar_url' => $user->avatar_url,
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();
        $user->loadMissing('guestProfile');

        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'avatar_url' => $user->avatar_url,
            'guest_profile_id' => $user->guestProfile?->id,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json(['ok' => true]);
    }
}
