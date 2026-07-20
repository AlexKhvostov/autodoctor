<?php

namespace Tests\Feature;

use App\Models\MaintenancePlanSnapshot;
use App\Models\Vehicle;
use Carbon\CarbonImmutable;
use Database\Seeders\MaintenanceV1Seeder;
use Database\Seeders\MaintenanceV2Seeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class MileageServiceRecordApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        CarbonImmutable::setTestNow('2026-07-20 12:00:00');
        $this->seed(MaintenanceV1Seeder::class);
        $this->seed(MaintenanceV2Seeder::class);
    }

    protected function tearDown(): void
    {
        CarbonImmutable::setTestNow();
        parent::tearDown();
    }

    public function test_mileage_update_is_owned_versioned_idempotent_and_does_not_create_service(): void
    {
        $headers = $this->sessionHeaders();
        $vehicle = $this->createVehicle($headers, 1000);
        $url = "/api/v1/vehicles/{$vehicle}/mileage";
        $payload = [
            'mileage' => ['value' => 1200, 'unit' => 'km'],
            'observed_at' => '2026-07-20T09:30:00Z',
            'version' => 1,
        ];

        $this->withHeaders([
            'X-Session-Token' => $headers['X-Session-Token'],
            'Idempotency-Key' => '',
        ])
            ->putJson($url, $payload)
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');

        $first = $this->withHeaders($headers)->putJson($url, $payload)
            ->assertOk()
            ->assertJsonPath('vehicle_version', 2)
            ->assertJsonPath('current_mileage.value', 1200)
            ->assertJsonPath('observation.source', 'manual')
            ->assertJsonPath('observation.observed_at', '2026-07-20T09:30:00.000000Z');
        $this->assertNotNull($first->json('maintenance_plan_id'));
        $this->assertDatabaseCount('mileage_observations', 2);
        $this->assertDatabaseCount('service_records', 0);

        $this->withHeaders($headers)->putJson($url, $payload)
            ->assertOk()
            ->assertExactJson($first->json());
        $this->assertDatabaseCount('mileage_observations', 2);

        $this->withHeaders($headers)->putJson($url, [...$payload, 'version' => 2])
            ->assertConflict()
            ->assertJsonPath('error.code', 'IDEMPOTENCY_KEY_CONFLICT');
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->putJson($url, [...$payload, 'version' => 1])
            ->assertConflict()
            ->assertJsonPath('error.code', 'VERSION_CONFLICT');

        $decrease = [...$payload, 'mileage' => ['value' => 1100, 'unit' => 'km'], 'version' => 2];
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->putJson($url, $decrease)
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->putJson($url, [...$decrease, 'decrease_confirmed' => true])
            ->assertUnprocessable();
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->putJson($url, [
                ...$decrease,
                'decrease_confirmed' => true,
                'decrease_reason' => 'Odometer replacement',
            ])->assertOk()->assertJsonPath('vehicle_version', 3);

        $other = $this->sessionHeaders();
        $this->withHeaders($other)->putJson($url, [...$payload, 'version' => 3])
            ->assertNotFound()
            ->assertJsonPath('error.code', 'VEHICLE_NOT_FOUND');
    }

    public function test_service_create_defaults_mileage_syncs_history_and_replays_atomically(): void
    {
        $headers = $this->sessionHeaders('ru');
        $vehicle = $this->createVehicle($headers, 1000);
        $url = "/api/v1/vehicles/{$vehicle}/history";
        $payload = [
            'service_date' => '2026-07-20',
            'work_codes' => ['oil_filter', 'engine_oil'],
        ];

        $first = $this->withHeaders($headers)->postJson($url, $payload)
            ->assertCreated()
            ->assertJsonPath('service_record.mileage.value', 1000)
            ->assertJsonPath('service_record.evidence_source', 'self')
            ->assertJsonPath('service_record.note', null)
            ->assertJsonPath('service_record.items.0.work_code', 'engine_oil')
            ->assertJsonPath('mileage_observation', null);
        $this->assertNotNull($first->json('maintenance_plan_id'));
        $this->assertDatabaseCount('service_records', 1);
        $this->assertDatabaseCount('service_record_items', 2);
        $this->assertDatabaseHas('history_answers', [
            'vehicle_id' => $vehicle,
            'answer' => 'done_known',
            'performed_date' => '2026-07-20 00:00:00',
            'performed_mileage_km' => 1000,
        ]);
        $this->assertSame(1, Vehicle::query()->findOrFail($vehicle)->version);

        $this->withHeaders($headers)->postJson($url, $payload)
            ->assertCreated()
            ->assertExactJson($first->json());
        $this->assertDatabaseCount('service_records', 1);
        $this->assertDatabaseCount('history_answers', 2);
        $this->withHeaders($headers)->postJson($url, [...$payload, 'note' => 'Changed'])
            ->assertConflict()
            ->assertJsonPath('error.code', 'IDEMPOTENCY_KEY_CONFLICT');

        $plan = $this->withHeaders($headers)
            ->getJson("/api/v1/vehicles/{$vehicle}/maintenance-plan")
            ->assertOk();
        $oil = collect($plan->json('items'))->firstWhere('work_code', 'engine_oil');
        $this->assertSame('current', $oil['status']);
        $this->assertSame(11000, $oil['due']['mileage']['value']);
        $this->assertSame('2027-07-20', $oil['due']['date']);
    }

    public function test_service_chronology_higher_mileage_and_history_list_are_stable(): void
    {
        $headers = $this->sessionHeaders('en');
        $vehicle = $this->createVehicle($headers, 1000);
        $url = "/api/v1/vehicles/{$vehicle}/history";

        $older = $this->withHeaders($headers)->postJson($url, [
            'service_date' => '2026-06-01',
            'work_codes' => ['engine_oil'],
            'mileage' => ['value' => 900, 'unit' => 'km'],
            'note' => 'Older service',
        ])->assertCreated();
        $newer = $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson($url, [
                'service_date' => '2026-07-15',
                'work_codes' => ['engine_oil'],
                'mileage' => ['value' => 1100, 'unit' => 'km'],
            ])->assertCreated();

        $this->assertNotSame($older->json('service_record.id'), $newer->json('service_record.id'));
        $this->assertDatabaseCount('service_records', 2);
        $this->assertDatabaseHas('vehicles', ['id' => $vehicle, 'current_mileage' => 1100, 'version' => 2]);
        $this->assertDatabaseHas('history_answers', [
            'vehicle_id' => $vehicle,
            'performed_date' => '2026-07-15 00:00:00',
            'performed_mileage_km' => 1100,
        ]);

        $this->withHeaders($headers)->getJson($url.'?page=1&per_page=20')
            ->assertOk()
            ->assertJsonCount(2, 'items')
            ->assertJsonPath('items.0.service_date', '2026-07-15')
            ->assertJsonPath('items.0.items.0.title', 'Engine oil')
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('meta.total_pages', 1);
        $this->withHeaders($headers)->getJson($url.'?sort=asc')
            ->assertUnprocessable();
    }

    public function test_service_validation_applicability_and_ownership_are_enforced(): void
    {
        config(['guest_bootstrap.capabilities.max_vehicles_per_user' => 2]);
        $headers = $this->sessionHeaders();
        $vehicle = $this->createVehicle($headers, 1000);
        $url = "/api/v1/vehicles/{$vehicle}/history";

        $this->withHeaders($headers)->postJson($url, [
            'service_date' => '2026-07-21',
            'work_codes' => ['engine_oil'],
        ])->assertUnprocessable();
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson($url, [
                'service_date' => '2026-07-20',
                'work_codes' => ['engine_oil', 'engine_oil'],
            ])->assertUnprocessable();
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson($url, [
                'service_date' => '2026-07-20',
                'work_codes' => ['engine_oil'],
                'evidence_source' => 'workshop',
            ])->assertUnprocessable();

        $electric = $this->createVehicle(
            [...$headers, 'Idempotency-Key' => (string) Str::uuid()],
            null,
            'electric',
        );
        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson("/api/v1/vehicles/{$electric}/history", [
                'service_date' => '2026-07-20',
                'work_codes' => ['engine_oil'],
            ])->assertUnprocessable();

        $other = $this->sessionHeaders();
        $this->withHeaders($other)->postJson($url, [
            'service_date' => '2026-07-20',
            'work_codes' => ['engine_oil'],
        ])->assertNotFound();
        $this->withHeaders($other)->getJson($url)->assertNotFound();
    }

    public function test_snapshot_and_timeline_include_localized_service_history_without_fake_dates(): void
    {
        $headers = $this->sessionHeaders('ru');
        $vehicle = $this->createVehicle($headers, 1000);
        $this->withHeaders($headers)->postJson("/api/v1/vehicles/{$vehicle}/history", [
            'service_date' => '2026-07-15',
            'work_codes' => ['engine_oil'],
            'mileage' => ['value' => 1050, 'unit' => 'km'],
        ])->assertCreated();
        $answerResponse = $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson("/api/v1/vehicles/{$vehicle}/history-answers", [
                'answers' => [
                    ['work_code' => 'timing_drive', 'answer' => 'not_applicable'],
                    ['work_code' => 'engine_oil', 'answer' => 'not_applicable'],
                ],
            ])->assertOk();
        $this->assertDatabaseHas('history_answers', [
            'vehicle_id' => $vehicle,
            'answer' => 'not_applicable',
        ]);

        $snapshot = MaintenancePlanSnapshot::query()->findOrFail($answerResponse->json('maintenance_plan_id'));
        $this->assertSame('2026-07-15', $snapshot->input_snapshot['service_history'][0]['service_date']);
        $this->assertSame(['engine_oil'], $snapshot->input_snapshot['service_history'][0]['work_codes']);

        $timeline = $this->withHeaders($headers)
            ->getJson("/api/v1/vehicles/{$vehicle}/timeline")
            ->assertOk()
            ->assertJsonPath('items.0.type', 'service_record')
            ->assertJsonPath('items.0.occurred_at', '2026-07-15')
            ->assertJsonPath('items.0.presentation.primary_category', 'maintenance_repair')
            ->assertJsonPath('items.0.presentation.action_level', 'info')
            ->assertJsonPath('items.0.presentation.basis', 'confirmed');
        $this->assertArrayNotHasKey('secondary_indicators', $timeline->json('items.0.presentation'));
        $this->assertNull(collect($timeline->json('items'))->first(
            fn (array $item): bool => ($item['plan_item']['work_code'] ?? null) === 'timing_drive',
        ));
        $oil = collect($timeline->json('items'))->first(
            fn (array $item): bool => ($item['plan_item']['work_code'] ?? null) === 'engine_oil',
        );
        $this->assertSame('current', $oil['plan_item']['status']);
        $undated = collect($timeline->json('items'))->first(
            fn (array $item): bool => $item['type'] === 'plan_item'
                && $item['presentation']['temporal'] === null,
        );
        $this->assertArrayNotHasKey('occurred_at', $undated);

        $this->withHeaders([...$headers, 'Accept-Language' => 'en-US'])
            ->getJson("/api/v1/vehicles/{$vehicle}/history")
            ->assertOk()
            ->assertJsonPath('items.0.items.0.title', 'Engine oil');
        $this->withHeaders([...$headers, 'Accept-Language' => 'en-US'])
            ->getJson("/api/v1/vehicles/{$vehicle}/timeline")
            ->assertOk()
            ->assertJsonPath('items.0.presentation.title', 'Service: Engine oil');
    }

    private function sessionHeaders(string $locale = 'en'): array
    {
        $response = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => $locale,
                'platform' => 'android',
            ])->assertCreated();

        return [
            'X-Session-Token' => $response->json('session_token'),
            'Idempotency-Key' => (string) Str::uuid(),
            'Accept-Language' => $locale,
        ];
    }

    private function createVehicle(
        array $headers,
        ?int $mileage,
        string $fuel = 'petrol',
    ): string {
        return $this->withHeaders($headers)->postJson('/api/v1/vehicles', array_filter([
            'make' => 'Other',
            'model' => 'Test vehicle',
            'production_year' => 2022,
            'fuel_type' => $fuel,
            'engine' => $fuel === 'electric' ? [] : ['displacement_cc' => 1600],
            'mileage' => $mileage === null ? null : ['value' => $mileage, 'unit' => 'km'],
        ], fn ($value): bool => $value !== null))->assertCreated()->json('id');
    }
}
