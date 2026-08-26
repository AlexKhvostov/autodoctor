<?php

namespace Tests\Feature;

use App\Models\AiConfigVersion;
use Database\Seeders\AiConfigSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Tests\TestCase;

class HealthCheckTest extends TestCase
{
    use RefreshDatabase;

    public function test_api_health_endpoint_is_available(): void
    {
        Carbon::setTestNow('2026-07-17T08:00:00Z');

        $response = $this->getJson('/api/v1/health');

        $response
            ->assertOk()
            ->assertJsonPath('status', 'ok')
            ->assertJsonPath('service', 'autodoctor-api')
            ->assertJsonPath('version', '0.4.0-draft')
            ->assertJsonPath('time', '2026-07-17T08:00:00.000000Z')
            ->assertJsonPath('checks.database.ok', true)
            ->assertJsonPath('checks.ai.ready', false)
            ->assertJsonPath('checks.ai.code', 'AI_NOT_CONFIGURED');

        $response->assertHeader('X-Request-ID');
    }

    public function test_health_reports_ready_ai_when_seeded_and_key_present(): void
    {
        $this->seed(AiConfigSeeder::class);
        config(['ai.providers.abacus.api_key' => 'test-key']);

        $this->getJson('/api/v1/health')
            ->assertOk()
            ->assertJsonPath('checks.ai.ready', true)
            ->assertJsonPath('checks.ai.code', 'READY')
            ->assertJsonPath('checks.ai.primary_provider', 'abacus')
            ->assertJsonPath('checks.ai.primary_key_configured', true)
            ->assertJsonPath('checks.ai.prompt_approved', true);
    }

    public function test_ai_probe_calls_provider(): void
    {
        $this->seed(AiConfigSeeder::class);
        config(['ai.providers.abacus.api_key' => 'test-key']);
        Http::fake([
            'routellm.abacus.ai/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'ok']],
                ],
            ], 200),
        ]);

        $token = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
            ])
            ->assertCreated()
            ->json('session_token');

        $this->withHeader('X-Session-Token', $token)
            ->postJson('/api/v1/diagnostics/ai')
            ->assertOk()
            ->assertJsonPath('probe.ok', true)
            ->assertJsonPath('probe.reply', 'ok')
            ->assertJsonPath('checks.ai.ready', true);
    }

    public function test_health_reports_disabled_config(): void
    {
        $this->seed(AiConfigSeeder::class);
        AiConfigVersion::query()->update(['enabled' => false]);

        $this->getJson('/api/v1/health')
            ->assertOk()
            ->assertJsonPath('checks.ai.ready', false)
            ->assertJsonPath('checks.ai.code', 'AI_DISABLED')
            ->assertJsonPath('checks.ai.is_active', true)
            ->assertJsonPath('checks.ai.enabled', false);
    }
}
