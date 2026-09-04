<?php

namespace App\Services\Firebase;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Google\Auth\HttpHandler\HttpHandlerFactory;
use GuzzleHttp\Client as GuzzleClient;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class FirebaseRemoteConfigClient
{
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.remoteconfig';

    /**
     * Raw string value of a Remote Config parameter (default value), or null.
     */
    public function getParameterString(string $key): ?string
    {
        if ((bool) config('firebase.force_defaults', false)) {
            return null;
        }

        $template = $this->fetchTemplate();
        if ($template === null) {
            return null;
        }

        $parameter = data_get($template, 'parameters.'.$key);
        if (! is_array($parameter)) {
            return null;
        }

        $value = data_get($parameter, 'defaultValue.value');
        if (! is_string($value) || trim($value) === '') {
            return null;
        }

        return $value;
    }

    /**
     * @return array<string, mixed>|null
     */
    public function fetchTemplate(): ?array
    {
        $projectId = trim((string) config('firebase.project_id', ''));
        if ($projectId === '') {
            return null;
        }

        $ttl = max(30, (int) config('firebase.cache_seconds', 300));
        $cacheKey = 'firebase.remote_config.template.'.$projectId;

        try {
            $cached = Cache::get($cacheKey);
            if (is_array($cached)) {
                return $cached;
            }

            $token = $this->accessToken();
            if ($token === null) {
                return null;
            }

            $response = Http::withToken($token)
                ->withOptions(['verify' => $this->sslVerifyOption()])
                ->acceptJson()
                ->timeout(12)
                ->get('https://firebaseremoteconfig.googleapis.com/v1/projects/'.$projectId.'/remoteConfig');

            if (! $response->successful()) {
                Log::warning('Firebase Remote Config fetch failed', [
                    'status' => $response->status(),
                    'body' => mb_substr($response->body(), 0, 400),
                ]);

                return null;
            }

            $json = $response->json();
            if (! is_array($json)) {
                return null;
            }

            Cache::put($cacheKey, $json, $ttl);

            return $json;
        } catch (Throwable $e) {
            Log::warning('Firebase Remote Config error: '.$e->getMessage());

            return null;
        }
    }

    public function forgetCache(): void
    {
        $projectId = trim((string) config('firebase.project_id', ''));
        if ($projectId !== '') {
            Cache::forget('firebase.remote_config.template.'.$projectId);
        }
    }

    private function accessToken(): ?string
    {
        $path = $this->credentialsPath();
        if ($path === null) {
            return null;
        }

        try {
            $json = json_decode((string) file_get_contents($path), true);
            if (! is_array($json)) {
                return null;
            }

            $credentials = new ServiceAccountCredentials(self::SCOPE, $json);
            $httpHandler = HttpHandlerFactory::build(new GuzzleClient([
                'verify' => $this->sslVerifyOption(),
                'timeout' => 12,
            ]));
            $token = $credentials->fetchAuthToken($httpHandler);
            $access = $token['access_token'] ?? null;

            return is_string($access) && $access !== '' ? $access : null;
        } catch (Throwable $e) {
            Log::warning('Firebase service account auth failed: '.$e->getMessage());

            return null;
        }
    }

    private function credentialsPath(): ?string
    {
        $configured = trim((string) config('firebase.credentials', ''));
        if ($configured === '') {
            return null;
        }

        $candidates = [
            $configured,
            base_path($configured),
            storage_path(ltrim(str_replace('storage/', '', $configured), '/\\')),
        ];

        // Common default: storage/app/firebase-service-account.json
        if (! str_contains($configured, DIRECTORY_SEPARATOR) && ! str_contains($configured, '/')) {
            $candidates[] = storage_path('app/'.$configured);
        }

        foreach (array_unique($candidates) as $path) {
            if (is_string($path) && is_file($path)) {
                return $path;
            }
        }

        return null;
    }

    private function sslVerifyOption(): bool|string
    {
        $bundle = config('firebase.ca_bundle') ?: config('ai.ca_bundle');
        if (is_string($bundle) && $bundle !== '' && is_file($bundle)) {
            return $bundle;
        }

        return true;
    }
}
