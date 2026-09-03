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
            ->assertSee('garage-btn', false)
            ->assertSee('nav-agent', false)
            ->assertSee('panel-agent', false);
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
            ->assertJsonPath('vehicles.0.sections.0.fields.0.label', 'Марка')
            ->assertJsonPath('vehicles.0.sections.0.fields.0.filled', false)
            ->assertJsonPath('vehicles.0.sections.1.title', 'История обслуживания')
            ->assertJsonPath('vehicles.0.sections.1.fields.0.filled', false)
            ->assertJsonStructure(['vehicles' => [['tabs' => ['state', 'roadmap', 'analytics']]]])
            ->assertJsonStructure(['agent' => ['tokens_label', 'settings', 'hint']])
            ->assertJsonPath('user.initial', 'A');
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
            ->assertJsonPath('vehicles.0.sections.0.fields.0.value', 'Volkswagen')
            ->assertJsonPath('vehicles.0.sections.0.fields.12.filled', true)
            ->assertJsonPath('vehicles.0.sections.0.fields.13.filled', false)
            ->assertJsonPath('vehicles.0.tabs.roadmap.0.tone', 'unknown')
            ->assertJsonStructure(['agent' => ['tokens_label', 'settings', 'hint']]);
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

        $state = app(TelegramMiniAppSnapshot::class)->forTelegramUser(70003);
        $card = $state['vehicles'][0];

        $this->assertSame('Volkswagen Polo', $card['title']);
        $this->assertSame('saved', $card['status']);
        $this->assertSame('Volkswagen', $card['sections'][0]['fields'][0]['value']);
        $this->assertFalse($card['sections'][0]['fields'][2]['filled']);
        $maintenance = collect($card['sections'][1]['fields'])->firstWhere('key', 'engine_oil');
        $this->assertSame('12.03.2026 · 140 000 км', $maintenance['value']);
        $this->assertArrayHasKey('tabs', $card);
        $this->assertNotEmpty($card['tabs']['state']);
        $this->assertArrayHasKey('agent', $state);
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
