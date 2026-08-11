<?php

namespace App\Services\Auth;

use App\Exceptions\ApiException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class GoogleIdTokenVerifier
{
    /**
     * @return array{sub: string, email: string, name: ?string, picture: ?string, email_verified: bool}
     */
    public function verify(string $idToken): array
    {
        $clientIds = array_values(array_filter([
            config('services.google.client_id'),
            config('services.google.android_client_id'),
            config('services.google.ios_client_id'),
        ]));

        if ($clientIds === []) {
            throw new ApiException(
                'GOOGLE_AUTH_NOT_CONFIGURED',
                __('api.errors.google_auth_not_configured'),
                503,
            );
        }

        $payload = $this->fetchTokenInfo($idToken);

        $aud = (string) ($payload['aud'] ?? '');
        if ($aud === '' || ! in_array($aud, $clientIds, true)) {
            Log::warning('Google id_token aud mismatch', [
                'aud' => $aud,
                'allowed' => $clientIds,
            ]);
            throw new ApiException(
                'GOOGLE_TOKEN_INVALID',
                __('api.errors.google_token_aud_mismatch'),
                401,
                details: ['aud' => $aud],
            );
        }

        $sub = (string) ($payload['sub'] ?? '');
        $email = (string) ($payload['email'] ?? '');
        if ($sub === '' || $email === '') {
            throw new ApiException(
                'GOOGLE_TOKEN_INVALID',
                __('api.errors.google_token_invalid'),
                401,
            );
        }

        return [
            'sub' => $sub,
            'email' => $email,
            'name' => isset($payload['name']) ? (string) $payload['name'] : null,
            'picture' => isset($payload['picture']) ? (string) $payload['picture'] : null,
            'email_verified' => ($payload['email_verified'] ?? 'false') === 'true'
                || ($payload['email_verified'] ?? false) === true,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function fetchTokenInfo(string $idToken): array
    {
        $verify = $this->sslVerifyOption();

        try {
            $response = Http::timeout(15)
                ->withOptions(['verify' => $verify])
                ->acceptJson()
                ->get('https://oauth2.googleapis.com/tokeninfo', [
                    'id_token' => $idToken,
                ]);
        } catch (Throwable $exception) {
            Log::warning('Google tokeninfo request failed', [
                'message' => $exception->getMessage(),
            ]);
            throw new ApiException(
                'GOOGLE_TOKEN_INVALID',
                __('api.errors.google_token_network'),
                401,
            );
        }

        if (! $response->successful()) {
            Log::warning('Google tokeninfo rejected token', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            throw new ApiException(
                'GOOGLE_TOKEN_INVALID',
                __('api.errors.google_token_invalid'),
                401,
            );
        }

        $payload = $response->json();
        if (! is_array($payload)) {
            throw new ApiException(
                'GOOGLE_TOKEN_INVALID',
                __('api.errors.google_token_invalid'),
                401,
            );
        }

        return $payload;
    }

    private function sslVerifyOption(): bool|string
    {
        $bundle = config('ai.ca_bundle');
        if (is_string($bundle) && $bundle !== '' && is_file($bundle)) {
            return $bundle;
        }

        return true;
    }
}
