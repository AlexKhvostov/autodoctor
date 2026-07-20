<?php

namespace Tests\Feature;

use App\Models\Vehicle;
use App\Services\PlanCalculator;
use Carbon\CarbonImmutable;
use Database\Seeders\MaintenanceV1Seeder;
use Database\Seeders\MaintenanceV2Seeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class MaintenancePlanApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        CarbonImmutable::setTestNow('2026-07-19 12:00:00');
        $this->seed(MaintenanceV1Seeder::class);
        $this->seed(MaintenanceV2Seeder::class);
    }

    protected function tearDown(): void
    {
        CarbonImmutable::setTestNow();
        parent::tearDown();
    }

    public function test_v3_matrix_is_exact_and_v1_remains_immutable(): void
    {
        $v1Hash = DB::table('ruleset_versions')->where('version', 'by-pilot-baseline-1')->value('content_hash');
        $v1Rules = DB::table('maintenance_rules')
            ->where('ruleset_version_id', DB::table('ruleset_versions')->where('version', 'by-pilot-baseline-1')->value('id'))
            ->get()->map(fn ($row) => (array) $row)->all();
        $expected = ['petrol' => 13, 'diesel' => 12, 'hybrid' => 13, 'electric' => 7, 'lpg' => 13, 'other' => 7];

        foreach ($expected as $fuel => $count) {
            $headers = $this->sessionHeaders('en');
            $vehicle = $this->createVehicle($headers, $fuel, 20000);
            $this->withHeaders($headers)
                ->getJson("/api/v1/vehicles/{$vehicle}/maintenance-plan")
                ->assertOk()
                ->assertJsonPath('ruleset_version', 'by-pilot-baseline-2')
                ->assertJsonPath('algorithm_version', 'maintenance-v3')
                ->assertJsonPath('config_version', 'condition-wear-v1')
                ->assertJsonCount($count, 'items');
        }

        $this->seed(MaintenanceV2Seeder::class);
        $this->assertSame($v1Hash, DB::table('ruleset_versions')->where('version', 'by-pilot-baseline-1')->value('content_hash'));
        $this->assertSame($v1Rules, DB::table('maintenance_rules')
            ->where('ruleset_version_id', DB::table('ruleset_versions')->where('version', 'by-pilot-baseline-1')->value('id'))
            ->get()->map(fn ($row) => (array) $row)->all());
        $this->assertDatabaseCount('maintenance_sources', 2);
        $this->assertDatabaseCount('ruleset_versions', 2);
        $this->assertDatabaseCount('maintenance_rules', 19);
    }

    public function test_unknown_history_is_check_now_but_never_overdue(): void
    {
        $headers = $this->sessionHeaders('ru');
        $vehicle = $this->createVehicle($headers, 'petrol', null);
        $plan = $this->withHeaders($headers)
            ->getJson("/api/v1/vehicles/{$vehicle}/maintenance-plan")
            ->assertOk()
            ->assertJsonPath('warnings', ['EDITORIAL_BASELINE_ONLY', 'HISTORY_REQUIRED', 'MILEAGE_NOT_PROVIDED'])
            ->assertJsonCount(13, 'items');

        foreach ($plan->json('items') as $item) {
            $this->assertSame('unknown', $item['status']);
            $this->assertTrue($item['requires_check_now']);
            $this->assertNull($item['due']['date']);
            $this->assertNull($item['due']['mileage']);
            $this->assertNull($item['history_state']['answer']);
            $this->assertFalse($item['source']['official_oem']);
            $this->assertNull($item['source']['url']);
        }
    }

    public function test_history_answers_validate_ownership_shape_and_idempotency(): void
    {
        $headers = $this->sessionHeaders('en');
        $vehicle = $this->createVehicle($headers, 'petrol', 20000);
        $url = "/api/v1/vehicles/{$vehicle}/history-answers";

        $this->withHeader('X-Session-Token', $headers['X-Session-Token'])
            ->postJson($url, ['answers' => [['work_code' => 'engine_oil', 'answer' => 'done_known']]])
            ->assertUnprocessable();
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson($url, ['answers' => [
                ['work_code' => 'engine_oil', 'answer' => 'unknown'],
                ['work_code' => 'engine_oil', 'answer' => 'not_done'],
            ]])->assertUnprocessable();
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson($url, ['answers' => [[
                'work_code' => 'engine_oil',
                'answer' => 'done_known',
                'performed_mileage_km' => 20001,
            ]]])->assertUnprocessable();

        $payload = ['answers' => [[
            'work_code' => 'engine_oil',
            'answer' => 'done_known',
            'performed_date' => '2026-06-01',
        ]]];
        $first = $this->withHeaders($headers)->postJson($url, $payload)->assertOk();
        $second = $this->withHeaders($headers)->postJson($url, $payload)->assertOk();
        $this->assertSame($first->json(), $second->json());
        $this->assertDatabaseCount('history_answers', 1);

        $this->withHeaders($headers)
            ->postJson($url, ['answers' => [['work_code' => 'engine_oil', 'answer' => 'not_done']]])
            ->assertConflict()
            ->assertJsonPath('error.code', 'IDEMPOTENCY_KEY_CONFLICT');

        $other = $this->sessionHeaders('en');
        $this->withHeaders($other)->postJson($url, $payload)
            ->assertNotFound()
            ->assertJsonPath('error.code', 'VEHICLE_NOT_FOUND');
    }

    public function test_petrol_oil_uses_confirmed_date_and_mileage_for_due_and_fractions(): void
    {
        $headers = $this->sessionHeaders('en');
        $vehicle = $this->createVehicle($headers, 'petrol', 19000);
        $this->submit($headers, $vehicle, [[
            'work_code' => 'engine_oil',
            'answer' => 'done_known',
            'performed_date' => '2026-04-19',
            'performed_mileage_km' => 10000,
        ]]);

        $plan = $this->withHeaders($headers)->getJson("/api/v1/vehicles/{$vehicle}/maintenance-plan")->assertOk();
        $oil = collect($plan->json('items'))->firstWhere('work_code', 'engine_oil');
        $this->assertSame('soon', $oil['status']);
        $this->assertSame(20000, $oil['due']['mileage']['value']);
        $this->assertSame('2027-04-19', $oil['due']['date']);
        $this->assertFalse($oil['requires_check_now']);

        $consumables = $this->withHeaders($headers)->getJson("/api/v1/vehicles/{$vehicle}/consumables")->assertOk();
        $oilProjection = collect($consumables->json('items'))->firstWhere('work_code', 'engine_oil');
        $this->assertEqualsWithDelta(0.9, $oilProjection['presentation']['mileage']['used_fraction'], 0.0001);
        $this->assertEqualsWithDelta(91 / 365, $oilProjection['presentation']['time']['used_fraction'], 0.0001);
        $this->assertEqualsWithDelta(0.9, $oilProjection['presentation']['effective_used_fraction'], 0.0001);
        $this->assertSame('mileage', $oilProjection['presentation']['effective_trigger']);
        $this->assertSame('warning', $oilProjection['presentation']['derived_state']);
    }

    public function test_partial_baselines_soon_overdue_and_condition_semantics_are_honest(): void
    {
        $headers = $this->sessionHeaders('en');
        $vehicle = $this->createVehicle($headers, 'petrol', 25000);
        $this->submit($headers, $vehicle, [
            ['work_code' => 'engine_oil', 'answer' => 'done_known', 'performed_mileage_km' => 10000],
            ['work_code' => 'cabin_filter', 'answer' => 'done_known', 'performed_date' => '2026-07-01'],
            ['work_code' => 'brake_fluid', 'answer' => 'done_known', 'performed_mileage_km' => 20000],
            ['work_code' => 'timing_drive', 'answer' => 'not_applicable'],
            ['work_code' => 'brake_pads', 'answer' => 'not_done'],
        ]);

        $plan = $this->withHeaders($headers)->getJson("/api/v1/vehicles/{$vehicle}/maintenance-plan")->assertOk();
        $items = collect($plan->json('items'))->keyBy('work_code');
        $this->assertSame('overdue', $items['engine_oil']['status']);
        $this->assertNull($items['engine_oil']['due']['date']);
        $this->assertSame('current', $items['cabin_filter']['status']);
        $this->assertNull($items['cabin_filter']['due']['mileage']);
        $this->assertSame('current', $items['brake_fluid']['status']);
        $this->assertSame('not_applicable', $items['timing_drive']['status']);
        $this->assertSame('unknown', $items['brake_pads']['status']);
        $this->assertNotSame('overdue', $items['brake_pads']['status']);
        $this->assertTrue($items['brake_pads']['requires_check_now']);

        $projection = $this->withHeaders($headers)->getJson("/api/v1/vehicles/{$vehicle}/consumables")->json('items');
        $brakeFluid = collect($projection)->firstWhere('work_code', 'brake_fluid');
        $this->assertSame('completed', $brakeFluid['presentation']['inspection_state']);
        $this->assertNull($brakeFluid['presentation']['latest_observation']);
        $this->assertNull($brakeFluid['presentation']['thresholds']);
        $this->assertSame('unknown', $brakeFluid['presentation']['derived_state']);
        $this->assertArrayNotHasKey('used_fraction', $brakeFluid['presentation']);

        $timeline = $this->withHeaders($headers)->getJson("/api/v1/vehicles/{$vehicle}/timeline")->assertOk();
        $this->assertNull(collect($timeline->json('items'))->first(
            fn ($item) => $item['plan_item']['work_code'] === 'timing_drive',
        ));
        $pads = collect($timeline->json('items'))->first(
            fn ($item) => $item['plan_item']['work_code'] === 'brake_pads',
        );
        $this->assertSame('critical', $pads['presentation']['action_level']);
        $this->assertSame('missing_data', $pads['presentation']['basis']);
        $oil = collect($timeline->json('items'))->first(
            fn ($item) => $item['plan_item']['work_code'] === 'engine_oil',
        );
        $this->assertSame('required', $oil['presentation']['action_level']);
        $this->assertSame('confirmed', $oil['presentation']['basis']);
        $this->assertArrayNotHasKey('status', $oil['presentation']);
        $this->assertArrayNotHasKey('importance', $oil['presentation']);
    }

    public function test_all_items_resolved_removes_only_history_warning_and_localizes_current_history(): void
    {
        $headers = $this->sessionHeaders('ru');
        $vehicle = $this->createVehicle($headers, 'petrol', 30000);
        $codes = $this->withHeaders($headers)
            ->getJson("/api/v1/vehicles/{$vehicle}/maintenance-plan")
            ->json('items');
        $answers = collect($codes)->map(fn ($item): array => $item['work_code'] === 'engine_oil'
            ? [
                'work_code' => $item['work_code'],
                'answer' => 'done_known',
                'performed_mileage_km' => 25000,
            ]
            : ['work_code' => $item['work_code'], 'answer' => 'not_applicable'])->all();
        $this->submit($headers, $vehicle, $answers);

        $ru = $this->withHeaders($headers)->getJson("/api/v1/vehicles/{$vehicle}/maintenance-plan")
            ->assertJsonPath('warnings', ['EDITORIAL_BASELINE_ONLY']);
        $en = $this->withHeaders([...$headers, 'Accept-Language' => 'en-US'])
            ->getJson("/api/v1/vehicles/{$vehicle}/maintenance-plan");
        $this->assertSame($ru->json('id'), $en->json('id'));
        $this->assertStringContainsString('подтверждено', collect($ru->json('items'))->firstWhere('work_code', 'engine_oil')['history_impact']);
        $this->assertStringContainsString('confirmed', collect($en->json('items'))->firstWhere('work_code', 'engine_oil')['history_impact']);
    }

    public function test_snapshot_reuses_same_input_and_new_answer_or_day_creates_immutable_snapshot(): void
    {
        $headers = $this->sessionHeaders('en');
        $vehicleId = $this->createVehicle($headers, 'petrol', 10000);
        $vehicle = Vehicle::query()->findOrFail($vehicleId);
        $calculator = app(PlanCalculator::class);
        $first = $calculator->calculate($vehicle, CarbonImmutable::parse('2026-07-19'));
        $same = $calculator->calculate($vehicle, CarbonImmutable::parse('2026-07-19'));
        $this->assertSame($first->id, $same->id);

        $this->submit($headers, $vehicleId, [[
            'work_code' => 'engine_oil',
            'answer' => 'done_known',
            'performed_date' => '2026-07-01',
        ]]);
        $afterAnswer = $calculator->calculate($vehicle->fresh(), CarbonImmutable::parse('2026-07-19'));
        $nextDay = $calculator->calculate($vehicle->fresh(), CarbonImmutable::parse('2026-07-20'));
        $this->assertNotSame($first->id, $afterAnswer->id);
        $this->assertNotSame($afterAnswer->id, $nextDay->id);
        $this->assertDatabaseCount('maintenance_plan_snapshots', 3);
        $this->assertDatabaseHas('maintenance_plan_snapshots', ['id' => $first->id]);
    }

    private function submit(array $headers, string $vehicle, array $answers)
    {
        return $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson("/api/v1/vehicles/{$vehicle}/history-answers", ['answers' => $answers])
            ->assertOk();
    }

    private function sessionHeaders(string $locale): array
    {
        $session = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => $locale,
                'platform' => 'android',
            ])->assertCreated();

        return [
            'X-Session-Token' => $session->json('session_token'),
            'Idempotency-Key' => (string) Str::uuid(),
            'Accept-Language' => $locale,
        ];
    }

    private function createVehicle(array $headers, string $fuelType, ?int $mileage): string
    {
        return $this->withHeaders($headers)->postJson('/api/v1/vehicles', array_filter([
            'make' => 'Other',
            'model' => 'Test vehicle',
            'production_year' => 2022,
            'fuel_type' => $fuelType,
            'engine' => in_array($fuelType, ['electric', 'other'], true) ? [] : ['displacement_cc' => 1600],
            'mileage' => $mileage === null ? null : ['value' => $mileage, 'unit' => 'km'],
        ], fn ($value): bool => $value !== null))->assertCreated()->json('id');
    }
}
