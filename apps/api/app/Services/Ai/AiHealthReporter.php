<?php

namespace App\Services\Ai;

use App\Models\AiConfigVersion;
use Illuminate\Support\Facades\DB;
use Throwable;

class AiHealthReporter
{
    public function __construct(private readonly LlmClient $llm) {}

    /**
     * @return array{
     *     status: string,
     *     database: array{ok: bool, error: ?string},
     *     ai: array<string, mixed>
     * }
     */
    public function snapshot(): array
    {
        $database = $this->databaseCheck();
        try {
            $ai = $this->aiCheck();
        } catch (Throwable $error) {
            $ai = [
                'ready' => false,
                'code' => 'AI_STATUS_ERROR',
                'message' => mb_substr($error->getMessage(), 0, 240),
                'has_config_row' => false,
                'is_active' => false,
                'enabled' => false,
                'prompt_approved' => false,
                'prompt_code' => null,
                'primary_provider' => null,
                'primary_model' => null,
                'primary_key_configured' => false,
                'fallback_provider' => null,
                'fallback_model' => null,
                'fallback_key_configured' => false,
            ];
        }

        return [
            'status' => $database['ok'] ? 'ok' : 'error',
            'database' => $database,
            'ai' => $ai,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function probe(): array
    {
        $snapshot = $this->snapshot();
        $ai = $snapshot['ai'];
        $provider = $ai['primary_provider'] ?? null;
        $model = $ai['primary_model'] ?? null;

        if (! is_string($provider) || $provider === '' || ! is_string($model) || $model === '') {
            return [
                'ok' => false,
                'skipped' => true,
                'code' => $ai['code'] ?? 'AI_NOT_CONFIGURED',
                'message' => $ai['message'] ?? 'AI is not configured.',
                'latency_ms' => null,
                'reply' => null,
            ];
        }

        if (! ($ai['primary_key_configured'] ?? false)) {
            return [
                'ok' => false,
                'skipped' => true,
                'code' => 'AI_PROVIDER_NOT_CONFIGURED',
                'message' => __('api.errors.ai_provider_not_configured', ['provider' => $provider]),
                'latency_ms' => null,
                'reply' => null,
            ];
        }

        $started = microtime(true);
        try {
            $reply = $this->llm->testConnection($provider, $model);

            return [
                'ok' => true,
                'skipped' => false,
                'code' => 'OK',
                'message' => 'Provider responded.',
                'provider' => $provider,
                'model' => $model,
                'latency_ms' => (int) round((microtime(true) - $started) * 1000),
                'reply' => mb_substr($reply, 0, 120),
            ];
        } catch (Throwable $error) {
            return [
                'ok' => false,
                'skipped' => false,
                'code' => 'AI_PROVIDER_ERROR',
                'message' => mb_substr($error->getMessage(), 0, 400),
                'provider' => $provider,
                'model' => $model,
                'latency_ms' => (int) round((microtime(true) - $started) * 1000),
                'reply' => null,
            ];
        }
    }

    /**
     * @return array{ok: bool, error: ?string}
     */
    private function databaseCheck(): array
    {
        try {
            DB::select('select 1');

            return ['ok' => true, 'error' => null];
        } catch (Throwable $error) {
            return ['ok' => false, 'error' => mb_substr($error->getMessage(), 0, 240)];
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function aiCheck(): array
    {
        $row = AiConfigVersion::query()
            ->with('promptVersion')
            ->where('is_active', true)
            ->latest('id')
            ->first()
            ?? AiConfigVersion::query()->with('promptVersion')->latest('id')->first();

        $provider = filled($row?->primary_provider) ? (string) $row->primary_provider : 'abacus';
        $fallback = $row?->fallback_provider;
        $prompt = $row?->promptVersion;
        $promptApproved = $prompt !== null && $prompt->isApproved();
        $primaryKey = $this->keyConfigured($provider);
        $fallbackKey = is_string($fallback) && $fallback !== '' ? $this->keyConfigured($fallback) : false;

        $code = 'READY';
        $message = 'AI is ready.';
        $ready = false;

        if ($row === null) {
            $code = 'AI_NOT_CONFIGURED';
            $message = __('api.errors.ai_not_configured');
        } elseif (! $row->is_active || ! $row->enabled) {
            $code = 'AI_DISABLED';
            $message = __('api.errors.ai_disabled_detail');
        } elseif (! $promptApproved) {
            $code = 'AI_PROMPT_MISSING';
            $message = __('api.errors.ai_prompt_missing');
        } elseif (! $primaryKey) {
            $code = 'AI_PROVIDER_NOT_CONFIGURED';
            $message = __('api.errors.ai_provider_not_configured', ['provider' => $provider]);
        } else {
            $ready = true;
        }

        return [
            'ready' => $ready,
            'code' => $code,
            'message' => $message,
            'has_config_row' => $row !== null,
            'is_active' => (bool) ($row?->is_active),
            'enabled' => (bool) ($row?->enabled),
            'prompt_approved' => $promptApproved,
            'prompt_code' => $prompt?->code,
            'primary_provider' => $provider,
            'primary_model' => $row?->primary_model,
            'primary_key_configured' => $primaryKey,
            'fallback_provider' => $fallback,
            'fallback_model' => $row?->fallback_model,
            'fallback_key_configured' => $fallbackKey,
        ];
    }

    private function keyConfigured(string $provider): bool
    {
        $key = config("ai.providers.{$provider}.api_key");

        return is_string($key) && trim($key) !== '';
    }
}
