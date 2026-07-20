<?php

namespace Tests\Feature;

use App\Models\Vehicle;
use Carbon\CarbonImmutable;
use Database\Seeders\MaintenanceV2Seeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Tests\TestCase;

class PlanV3ApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        CarbonImmutable::setTestNow('2026-07-20 12:00:00');
        $this->seed(MaintenanceV2Seeder::class);
    }

    protected function tearDown(): void
    {
        CarbonImmutable::setTestNow();
        parent::tearDown();
    }

    public function test_condition_observations_are_append_only_validated_idempotent_and_feed_latest_plan(): void
    {
        $headers = $this->headers('en');
        $vehicle = $this->vehicle($headers, 50000);
        $url = "/api/v1/vehicles/{$vehicle}/condition-observations";
        $payload = [
            'work_code' => 'brake_pads',
            'wear_percent' => 69,
            'observed_at' => '2026-07-19',
            'mileage' => ['value' => 49000, 'unit' => 'km'],
            'source' => 'workshop',
            'note' => 'Measured',
        ];
        $first = $this->withHeaders($headers)->postJson($url, $payload)->assertCreated();
        $replay = $this->withHeaders($headers)->postJson($url, $payload)->assertCreated();
        $this->assertSame($first->json(), $replay->json());
        $this->assertDatabaseCount('condition_observations', 1);

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson($url, [...$payload, 'wear_percent' => 101])->assertUnprocessable();
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson($url, [...$payload, 'observed_at' => '2026-07-21'])->assertUnprocessable();
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson($url, [...$payload, 'mileage' => ['value' => 50001, 'unit' => 'km']])
            ->assertUnprocessable();

        $newer = [...$payload, 'wear_percent' => 85, 'observed_at' => '2026-07-20'];
        $secondObservation = $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson($url, $newer)->assertCreated();
        $this->assertNotSame($first->json('maintenance_plan_id'), $secondObservation->json('maintenance_plan_id'));
        $list = $this->withHeaders($headers)->getJson($url)->assertOk()->json('items');
        $this->assertSame([85, 69], array_column($list, 'wear_percent'));
        $this->assertSame(15, $list[0]['remaining_percent']);

        $plan = $this->withHeaders($headers)->getJson("/api/v1/vehicles/{$vehicle}/maintenance-plan");
        $pads = collect($plan->json('items'))->firstWhere('work_code', 'brake_pads');
        $this->assertSame('overdue', $pads['status']);
        $this->assertSame('immediate', $pads['urgency']);
        $this->assertNull($pads['due']['mileage']);
        $this->assertNull($pads['due']['date']);
        $timelinePads = collect($this->withHeaders($headers)
            ->getJson("/api/v1/vehicles/{$vehicle}/timeline")->json('items'))
            ->first(fn (array $item): bool => ($item['plan_item']['work_code'] ?? null) === 'brake_pads');
        $this->assertSame('critical', $timelinePads['presentation']['action_level']);
        $this->assertSame('confirmed', $timelinePads['presentation']['basis']);
        $projection = collect($this->withHeaders($headers)
            ->getJson("/api/v1/vehicles/{$vehicle}/consumables")->json('items'))
            ->firstWhere('work_code', 'brake_pads');
        $this->assertSame(85, $projection['presentation']['latest_observation']['wear_percent']);
        $this->assertSame('danger', $projection['presentation']['derived_state']);

        $other = $this->headers('en');
        $this->withHeaders($other)->getJson($url)
            ->assertNotFound()
            ->assertJsonPath('error.code', 'VEHICLE_NOT_FOUND');
    }

    public function test_all_condition_threshold_boundaries_and_no_fake_percent(): void
    {
        foreach ([
            'brake_pads' => [69, 70, 85],
            'brake_discs' => [69, 70, 90],
            'tire_condition_inspection' => [59, 60, 80],
        ] as $code => $values) {
            foreach (array_combine($values, ['normal', 'warning', 'danger']) as $wear => $state) {
                $headers = $this->headers('en');
                $vehicle = $this->vehicle($headers, 10000);
                $this->withHeaders($headers)->postJson("/api/v1/vehicles/{$vehicle}/condition-observations", [
                    'work_code' => $code,
                    'wear_percent' => $wear,
                    'observed_at' => '2026-07-20',
                    'source' => 'self',
                ])->assertCreated();
                $item = collect($this->withHeaders($headers)
                    ->getJson("/api/v1/vehicles/{$vehicle}/consumables")->json('items'))
                    ->firstWhere('work_code', $code);
                $this->assertSame($state, $item['presentation']['derived_state']);
            }
        }

        $headers = $this->headers('en');
        $vehicle = $this->vehicle($headers, null);
        $pads = collect($this->withHeaders($headers)
            ->getJson("/api/v1/vehicles/{$vehicle}/consumables")->json('items'))
            ->firstWhere('work_code', 'brake_pads');
        $this->assertNull($pads['presentation']['latest_observation']);
        $this->assertSame('unknown', $pads['presentation']['derived_state']);
    }

    public function test_plan_item_ui_preferences_are_dormant_and_routes_are_unavailable(): void
    {
        $headers = $this->headers('ru');
        $vehicle = $this->vehicle($headers, 10000);
        $url = "/api/v1/vehicles/{$vehicle}/plan-item-ui-preferences";

        $this->assertTrue(Schema::hasTable('vehicle_plan_item_ui_preferences'));
        $this->withHeaders($headers)->getJson($url)->assertNotFound();
        $this->withHeaders($headers)->putJson($url, [
            'work_code' => 'brake_pads',
            'collapsed' => true,
            'version' => 0,
        ])->assertNotFound();
        $this->assertDatabaseCount('vehicle_plan_item_ui_preferences', 0);
    }

    public function test_forecast_default_empirical_unit_conversion_and_no_plan_side_effect(): void
    {
        $headers = $this->headers('en');
        $vehicle = $this->vehicle($headers, null);
        $url = "/api/v1/vehicles/{$vehicle}/mileage-forecast";
        $default = $this->withHeaders($headers)->getJson($url)->assertOk();
        $default->assertJsonPath('annual_distance.value', 10000)
            ->assertJsonPath('method', 'default_assumption')
            ->assertJsonPath('confidence', 'low')
            ->assertJsonPath('observation_count', 0);
        $planCount = Vehicle::findOrFail($vehicle)->maintenancePlanSnapshots()->count();

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->putJson("/api/v1/vehicles/{$vehicle}/mileage", [
                'mileage' => ['value' => 10000, 'unit' => 'mi'],
                'observed_at' => '2025-07-20T10:00:00Z',
                'version' => 1,
            ])->assertOk();
        $this->withHeaders($headers)->getJson($url)
            ->assertJsonPath('method', 'default_assumption')
            ->assertJsonPath('observation_count', 1)
            ->assertJsonPath('annual_distance.value', 10000);
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->putJson("/api/v1/vehicles/{$vehicle}/mileage", [
                'mileage' => ['value' => 16214, 'unit' => 'mi'],
                'observed_at' => '2026-07-20T10:00:00Z',
                'version' => 2,
            ])->assertOk();
        $empirical = $this->withHeaders($headers)->getJson($url)->assertOk();
        $empirical->assertJsonPath('method', 'empirical')->assertJsonPath('observation_count', 2);
        $this->assertEqualsWithDelta(10000, $empirical->json('annual_distance.value'), 2);
        $this->assertSame(2, Vehicle::findOrFail($vehicle)->mileageObservations()->count());
        $this->assertGreaterThanOrEqual($planCount, Vehicle::findOrFail($vehicle)->maintenancePlanSnapshots()->count());
        $beforeRead = Vehicle::findOrFail($vehicle)->maintenancePlanSnapshots()->count();
        $this->withHeaders($headers)->getJson($url)->assertOk();
        $this->assertSame($beforeRead, Vehicle::findOrFail($vehicle)->maintenancePlanSnapshots()->count());
    }

    private function headers(string $locale): array
    {
        $session = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', ['locale' => $locale, 'platform' => 'android'])
            ->assertCreated();

        return [
            'X-Session-Token' => $session->json('session_token'),
            'Idempotency-Key' => (string) Str::uuid(),
            'Accept-Language' => $locale,
        ];
    }

    private function vehicle(array $headers, ?int $mileage): string
    {
        return $this->withHeaders($headers)->postJson('/api/v1/vehicles', array_filter([
            'make' => 'Other',
            'model' => 'Plan v3',
            'production_year' => 2022,
            'fuel_type' => 'petrol',
            'engine' => ['displacement_cc' => 1600],
            'mileage' => $mileage === null ? null : ['value' => $mileage, 'unit' => 'km'],
        ], fn ($value): bool => $value !== null))->assertCreated()->json('id');
    }
}
