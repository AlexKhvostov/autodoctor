<?php

namespace Tests\Feature;

use App\Models\GuestProfile;
use App\Models\HistoryAnswer;
use App\Models\TelegramBotUser;
use App\Models\Vehicle;
use App\Models\VehicleConfiguration;
use App\Models\WorkCatalogItem;
use App\Services\Telegram\TelegramMiniAppSnapshot;
use Database\Seeders\MaintenanceV1Seeder;
use Database\Seeders\MaintenanceV2Seeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TelegramMiniAppTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(MaintenanceV1Seeder::class);
        $this->seed(MaintenanceV2Seeder::class);
    }

    public function test_mini_app_page_is_served(): void
    {
        $this->get('/telegram/app')
            ->assertOk()
            ->assertSee('AutoDoctor', false)
            ->assertSee('telegram-web-app.js', false)
            ->assertSee('topbar-shell', false)
            ->assertSee('tl-wrap', false)
            ->assertSee('chart-card', false);
    }

    public function test_state_requires_telegram_init_data(): void
    {
        $this->getJson('/telegram/app/state')->assertUnauthorized();
    }

    public function test_state_returns_full_vehicle_template_with_dashes_for_new_user(): void
    {
        config(['telegram.bot_token' => 'TESTTOKEN', 'telegram.allowlist_ids' => '70001']);
        GuestProfile::query()->create([
            'telegram_id' => 70001,
            'telegram_username' => 'anna',
            'telegram_first_name' => 'Anna',
        ]);

        $this->withHeader('X-Telegram-Init-Data', $this->sign([
            'auth_date' => (string) time(),
            'user' => '{"id":70001,"first_name":"Anna"}',
        ]))->getJson('/telegram/app/state')
            ->assertOk()
            ->assertJsonPath('ok', true)
            ->assertJsonPath('allowed', true)
            ->assertJsonPath('title', 'AutoDoctor')
            ->assertJsonPath('vehicles.0.title', 'Автомобиль')
            ->assertJsonPath('vehicles.0.status', 'placeholder')
            ->assertJsonStructure(['vehicles' => [['tabs' => ['state', 'roadmap' => ['timeline'], 'analytics' => ['charts']]]]])
            ->assertJsonStructure(['agent' => ['title', 'form', 'editable', 'memory_hint'], 'help' => ['sections'], 'garage'])
            ->assertJsonPath('user.initial', 'A')
            ->assertJsonMissingPath('subtitle');
    }

    public function test_state_shows_draft_vehicle_card_from_bot(): void
    {
        config(['telegram.bot_token' => 'TESTTOKEN', 'telegram.allowlist_ids' => '70002']);
        GuestProfile::query()->create([
            'telegram_id' => 70002,
            'telegram_username' => 'pilot',
        ]);
        TelegramBotUser::query()->create([
            'telegram_user_id' => 70002,
            'pending_vehicle_draft' => [
                'make' => 'Volkswagen',
                'model' => 'Polo',
                'production_year' => 2014,
                'fuel_type' => 'petrol',
                'mileage_km' => 148000,
                'vin' => null,
            ],
        ]);

        $this->withHeader('X-Telegram-Init-Data', $this->sign([
            'auth_date' => (string) time(),
            'user' => '{"id":70002,"first_name":"Pilot"}',
        ]))->getJson('/telegram/app/state')
            ->assertOk()
            ->assertJsonPath('vehicles.0.title', 'Volkswagen Polo')
            ->assertJsonPath('vehicles.0.status', 'draft')
            ->assertJsonPath('vehicles.0.tabs.roadmap.timeline.0.tone', 'unknown');
    }

    public function test_mini_app_can_update_agent_preferences(): void
    {
        config(['telegram.bot_token' => 'TESTTOKEN', 'telegram.allowlist_ids' => '70004']);
        GuestProfile::query()->create(['telegram_id' => 70004]);

        $headers = ['X-Telegram-Init-Data' => $this->sign([
            'auth_date' => (string) time(),
            'user' => '{"id":70004,"first_name":"Agent"}',
        ])];

        $this->withHeaders($headers)
            ->patchJson('/telegram/app/agent/skill', [
                'knowledge_band' => 'curious',
                'hands_on' => 'sometimes',
            ])
            ->assertOk()
            ->assertJsonPath('skill.self_reported_band', 'curious');

        $this->withHeaders($headers)
            ->patchJson('/telegram/app/agent/preferences', [
                'simplicity' => 7,
                'verbosity' => 4,
                'directness' => 6,
                'initiative' => 5,
                'custom_instructions' => 'Обращайся на «ты»',
            ])
            ->assertOk()
            ->assertJsonPath('preferences.simplicity', 7)
            ->assertJsonPath('preferences.custom_instructions', 'Обращайся на «ты»');
    }

    public function test_snapshot_lists_saved_vehicle_profile_and_maintenance_slots(): void
    {
        $profile = GuestProfile::query()->create(['telegram_id' => 70003]);
        $session = \App\Models\AnonymousSession::query()->create([
            'guest_profile_id' => $profile->id,
            'locale' => 'ru',
            'platform' => 'telegram',
            'app_version' => 'telegram-bot',
            'token_hash' => hash('sha256', 'test'),
            'status' => 'active',
            'last_activity_at' => now(),
            'expires_at' => now()->addYear(),
        ]);
        $configuration = VehicleConfiguration::query()->create([
            'make' => 'Volkswagen',
            'model' => 'Polo',
            'fuel_type' => 'petrol',
            'transmission_type' => 'manual',
            'field_provenance' => [],
            'confirmed_at' => now(),
        ]);
        $vehicle = Vehicle::query()->create([
            'anonymous_session_id' => $session->id,
            'configuration_id' => $configuration->id,
            'production_year' => 2014,
            'current_mileage' => 148000,
            'mileage_unit' => 'km',
            'profile_status' => 'pending_review',
            'plan_eligibility' => 'universal_type_only',
            'version' => 1,
        ]);
        $oil = WorkCatalogItem::query()->where('code', 'engine_oil')->firstOrFail();
        HistoryAnswer::query()->create([
            'vehicle_id' => $vehicle->id,
            'work_catalog_item_id' => $oil->id,
            'answer' => 'done_known',
            'performed_date' => '2026-03-12',
            'performed_mileage_km' => 140000,
            'version' => 1,
        ]);

        $state = app(TelegramMiniAppSnapshot::class)->forTelegramUser(70003, (string) $vehicle->id);
        $card = $state['vehicles'][0];

        $this->assertSame('Volkswagen Polo', $card['title']);
        $this->assertSame('saved', $card['status']);
        $this->assertArrayHasKey('timeline', $card['tabs']['roadmap']);
        $oilState = collect($card['tabs']['state'])->firstWhere('key', 'engine_oil');
        $this->assertSame('12.03.2026 · 140 000 км', $oilState['last_service']);
        $this->assertTrue($state['agent']['editable']);
        $this->assertArrayHasKey('form', $state['agent']);
        $this->assertSame((string) $vehicle->id, $state['active_vehicle_id']);
    }

    /**
     * @param  array<string, string>  $fields
     */
    private function sign(array $fields): string
    {
        ksort($fields);
        $pairs = [];
        foreach ($fields as $key => $value) {
            $pairs[] = $key.'='.$value;
        }
        $secret = hash_hmac('sha256', 'TESTTOKEN', 'WebAppData', true);
        $fields['hash'] = hash_hmac('sha256', implode("\n", $pairs), $secret);

        return http_build_query($fields);
    }
}
