<?php

namespace Tests\Feature;

use App\Models\AiUsageEvent;
use App\Models\AnonymousSession;
use App\Models\GuestProfile;
use App\Services\AgentProfileService;
use App\Services\Ai\VehicleUserDossierBuilder;
use Database\Seeders\AiConfigSeeder;
use Database\Seeders\MaintenanceV1Seeder;
use Database\Seeders\MaintenanceV2Seeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class AgentProfileTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(MaintenanceV1Seeder::class);
        $this->seed(MaintenanceV2Seeder::class);
        $this->seed(AiConfigSeeder::class);
    }

    public function test_agent_profile_returns_defaults_and_starting_fuel(): void
    {
        $headers = $this->sessionHeaders();

        $this->withHeaders($headers)
            ->getJson('/api/v1/guest/agent-profile')
            ->assertOk()
            ->assertJsonPath('agent_profile.preferences.simplicity', 3)
            ->assertJsonPath('agent_profile.skill.band', 'basic')
            ->assertJsonPath('agent_profile.fuel.status', 'ok')
            ->assertJsonPath('agent_profile.fuel.balance_ml', 5000)
            ->assertJsonPath('agent_profile.refuel_packages.0.payment_available', false);
    }

    public function test_low_energy_status_when_balance_is_small(): void
    {
        $headers = $this->sessionHeaders();
        $this->withHeaders($headers)->getJson('/api/v1/guest/agent-profile')->assertOk();

        $session = AnonymousSession::query()
            ->where('token_hash', hash('sha256', $headers['X-Session-Token']))
            ->firstOrFail();
        $profile = $session->guestProfile;
        $agents = app(AgentProfileService::class);
        $wallet = $agents->wallet($profile);
        $wallet->forceFill(['balance_ml' => 200])->save();

        $this->withHeaders($headers)
            ->getJson('/api/v1/guest/agent-profile')
            ->assertOk()
            ->assertJsonPath('agent_profile.fuel.status', 'low')
            ->assertJsonPath('agent_profile.fuel.balance_ml', 200);
    }

    public function test_skill_can_be_updated_from_agent_profile(): void
    {
        $headers = $this->sessionHeaders();

        $this->withHeaders($headers)
            ->patchJson('/api/v1/guest/agent-profile/skill', [
                'knowledge_band' => 'pro',
                'hands_on' => 'always',
            ])
            ->assertOk()
            ->assertJsonPath('skill.self_reported_band', 'pro')
            ->assertJsonPath('skill.hands_on', true)
            ->assertJsonPath('skill.hands_on_level', 'always')
            ->assertJsonPath('skill.band', 'confident');
    }

    public function test_preferences_update_and_appear_in_dossier(): void
    {
        $headers = $this->sessionHeaders();

        $this->withHeaders($headers)
            ->patchJson('/api/v1/guest/agent-profile/preferences', [
                'simplicity' => 1,
                'verbosity' => 2,
                'directness' => 8,
                'initiative' => 6,
                'custom_instructions' => 'Всегда зови меня Алексей',
            ])
            ->assertOk()
            ->assertJsonPath('preferences.simplicity', 1)
            ->assertJsonPath('preferences.custom_instructions', 'Всегда зови меня Алексей');

        $vehicleId = $this->withHeaders(array_merge($headers, [
            'Idempotency-Key' => (string) Str::uuid(),
        ]))->postJson('/api/v1/vehicles', [
            'make' => 'Other',
            'model' => 'Other model',
            'production_year' => 2020,
            'fuel_type' => 'petrol',
            'engine' => ['displacement_cc' => 1600],
        ])->assertCreated()->json('id');

        $session = AnonymousSession::query()
            ->where('token_hash', hash('sha256', $headers['X-Session-Token']))
            ->firstOrFail();
        $profile = $session->guestProfile;
        $this->assertNotNull($profile);

        $dossier = app(VehicleUserDossierBuilder::class)->build(
            $profile,
            \App\Models\Vehicle::query()->findOrFail($vehicleId),
        );

        $this->assertStringContainsString('## Настройки агента от пользователя', $dossier);
        $this->assertStringContainsString('простота: 1/10', $dossier);
        $this->assertStringContainsString('Всегда зови меня Алексей', $dossier);
    }

    public function test_usage_decrements_fuel_and_refuel_stub_restores(): void
    {
        $headers = $this->sessionHeaders();
        $this->withHeaders($headers)->getJson('/api/v1/guest/agent-profile')->assertOk();

        $session = AnonymousSession::query()
            ->where('token_hash', hash('sha256', $headers['X-Session-Token']))
            ->firstOrFail();
        /** @var GuestProfile $profile */
        $profile = $session->guestProfile;

        $agents = app(AgentProfileService::class);
        $before = (int) $agents->wallet($profile)->balance_ml;

        $agents->recordUsage($profile, AiUsageEvent::SOURCE_CHAT, [
            'prompt_tokens' => 1000,
            'completion_tokens' => 500,
            'total_tokens' => 1500,
            'provider' => 'deepseek',
            'model' => 'deepseek-chat',
        ]);

        $after = (int) $agents->wallet($profile->fresh())->balance_ml;
        $this->assertLessThan($before, $after);
        $this->assertDatabaseHas('ai_usage_events', [
            'guest_profile_id' => $profile->id,
            'source' => AiUsageEvent::SOURCE_CHAT,
            'total_tokens' => 1500,
        ]);

        $this->withHeaders($headers)
            ->postJson('/api/v1/guest/agent-profile/refuel-stub', [
                'package_ml' => 2000,
            ])
            ->assertOk()
            ->assertJsonPath('fuel.payment_stub', true);

        $refueled = (int) $agents->wallet($profile->fresh())->balance_ml;
        $this->assertGreaterThan($after, $refueled);
    }

    public function test_empty_fuel_blocks_chat(): void
    {
        $headers = $this->sessionHeaders();
        $this->withHeaders($headers)->getJson('/api/v1/guest/agent-profile')->assertOk();

        $session = AnonymousSession::query()
            ->where('token_hash', hash('sha256', $headers['X-Session-Token']))
            ->firstOrFail();
        $profile = $session->guestProfile;
        $agents = app(AgentProfileService::class);
        $wallet = $agents->wallet($profile);
        $wallet->forceFill(['balance_ml' => 0])->save();

        $vehicleId = $this->withHeaders(array_merge($headers, [
            'Idempotency-Key' => (string) Str::uuid(),
        ]))->postJson('/api/v1/vehicles', [
            'make' => 'Other',
            'model' => 'Other model',
            'production_year' => 2020,
            'fuel_type' => 'petrol',
            'engine' => ['displacement_cc' => 1600],
        ])->assertCreated()->json('id');

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Привет',
                'history' => [],
            ])
            ->assertStatus(402)
            ->assertJsonPath('error.code', 'AGENT_FUEL_EMPTY');
    }

    /**
     * @return array{X-Session-Token: string}
     */
    private function sessionHeaders(): array
    {
        $response = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
                'app_version' => '0.1.0',
            ])
            ->assertCreated();

        return [
            'X-Session-Token' => $response->json('session_token'),
        ];
    }
}
