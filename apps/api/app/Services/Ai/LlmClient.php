<?php

namespace App\Services\Ai;

use App\Exceptions\ApiException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class LlmClient
{
    /**
     * @param  list<array{role: string, content: string}>  $messages
     * @return array{
     *     content: string,
     *     provider: string,
     *     model: string,
     *     prompt_tokens: ?int,
     *     completion_tokens: ?int,
     *     total_tokens: ?int
     * }
     */
    public function chat(
        string $provider,
        string $model,
        array $messages,
        ?int $maxTokens = null,
    ): array {
        $config = $this->providerConfig($provider);
        $apiKey = $config['api_key'] ?? null;
        if (! is_string($apiKey) || trim($apiKey) === '') {
            throw new ApiException(
                'AI_PROVIDER_NOT_CONFIGURED',
                __('api.errors.ai_provider_not_configured', ['provider' => $provider]),
                503,
            );
        }

        $baseUrl = rtrim((string) $config['base_url'], '/');
        $payload = [
            'model' => $model,
            'messages' => $messages,
            'temperature' => 0.4,
        ];
        if ($maxTokens !== null) {
            $payload['max_tokens'] = $maxTokens;
        }

        $response = Http::timeout(60)
            ->withOptions([
                'verify' => $this->sslVerifyOption(),
            ])
            ->withToken($apiKey)
            ->acceptJson()
            ->post($baseUrl.'/v1/chat/completions', $payload);

        if (! $response->successful()) {
            throw new ApiException(
                'AI_PROVIDER_ERROR',
                __('api.errors.ai_provider_error', [
                    'provider' => $provider,
                    'detail' => mb_substr($response->body(), 0, 240),
                ]),
                502,
                ['status' => $response->status()],
            );
        }

        $json = $response->json();
        $content = data_get($json, 'choices.0.message.content');
        if (! is_string($content) || trim($content) === '') {
            throw new ApiException(
                'AI_PROVIDER_ERROR',
                __('api.errors.ai_empty_response'),
                502,
            );
        }

        $promptTokens = data_get($json, 'usage.prompt_tokens');
        $completionTokens = data_get($json, 'usage.completion_tokens');
        $totalTokens = data_get($json, 'usage.total_tokens');

        return [
            'content' => trim($content),
            'provider' => $provider,
            'model' => $model,
            'prompt_tokens' => is_numeric($promptTokens) ? (int) $promptTokens : null,
            'completion_tokens' => is_numeric($completionTokens) ? (int) $completionTokens : null,
            'total_tokens' => is_numeric($totalTokens) ? (int) $totalTokens : null,
        ];
    }

    public function testConnection(string $provider, string $model): string
    {
        $result = $this->chat(
            $provider,
            $model,
            [
                ['role' => 'system', 'content' => 'Reply with exactly: ok'],
                ['role' => 'user', 'content' => 'ping'],
            ],
            32,
        );

        return $result['content'];
    }

    /**
     * @return array<string, mixed>
     */
    private function providerConfig(string $provider): array
    {
        if (! in_array($provider, config('ai.whitelist', []), true)) {
            throw new RuntimeException("Provider [{$provider}] is not whitelisted.");
        }

        $config = config("ai.providers.{$provider}");
        if (! is_array($config)) {
            throw new RuntimeException("Provider [{$provider}] is not configured.");
        }

        return $config;
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
