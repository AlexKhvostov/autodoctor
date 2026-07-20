<?php

namespace Tests\Feature;

use Database\Seeders\MaintenanceV1Seeder;
use Database\Seeders\MaintenanceV2Seeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class VehicleApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(MaintenanceV1Seeder::class);
        $this->seed(MaintenanceV2Seeder::class);
    }

    public function test_minimal_vehicle_can_be_created_without_optional_fields_or_vin_key(): void
    {
        config(['vehicle.vin_hash_key' => '']);

        $created = $this->withHeaders($this->sessionHeaders())
            ->postJson('/api/v1/vehicles', $this->minimalVehiclePayload())
            ->assertCreated()
            ->assertJsonPath('vin_masked', null)
            ->assertJsonPath('mileage', null)
            ->assertJsonPath('transmission', null)
            ->assertJsonPath('profile_status', 'pending_review')
            ->assertJsonPath('recommendation_scope', 'universal_type_only');

        $this->assertDatabaseHas('vehicles', [
            'id' => $created->json('id'),
            'vin_ciphertext' => null,
            'vin_hash' => null,
            'vin_last4' => null,
            'current_mileage' => null,
            'mileage_unit' => null,
        ]);
        $this->assertDatabaseCount('mileage_observations', 0);
    }

    public function test_vehicle_crud_and_vin_secrecy(): void
    {
        $headers = $this->sessionHeaders();
        $payload = $this->vehiclePayload();

        $created = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', $payload)
            ->assertCreated()
            ->assertJsonPath('vin_masked', 'WVG**********3456')
            ->assertJsonPath('profile_status', 'pending_review')
            ->assertJsonPath('recommendation_scope', 'universal_type_only')
            ->assertJsonPath('version', 1)
            ->assertJsonPath('provenance.vin.source', 'user')
            ->assertJsonMissing(['vin' => $payload['vin']]);

        $vehicleId = $created->json('id');
        $body = json_encode($created->json(), JSON_THROW_ON_ERROR);
        $this->assertStringNotContainsString($payload['vin'], $body);

        $stored = DB::table('vehicles')->where('id', $vehicleId)->first();
        $this->assertNotSame($payload['vin'], $stored->vin_ciphertext);
        $this->assertStringNotContainsString($payload['vin'], $stored->vin_ciphertext);
        $this->assertSame(hash_hmac('sha256', $payload['vin'], 'deterministic-test-vin-hash-key'), $stored->vin_hash);
        $this->assertDatabaseHas('mileage_observations', [
            'vehicle_id' => $vehicleId,
            'value' => 84200,
            'unit' => 'km',
            'source' => 'manual',
        ]);

        $this->withHeader('X-Session-Token', $headers['X-Session-Token'])
            ->getJson('/api/v1/vehicles/'.$vehicleId)
            ->assertOk()
            ->assertJsonPath('make', 'Volkswagen');

        $this->withHeader('X-Session-Token', $headers['X-Session-Token'])
            ->getJson('/api/v1/vehicles')
            ->assertOk()
            ->assertJsonCount(1, 'items')
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('meta.total_pages', 1);

        $patched = $this->withHeaders([
            'X-Session-Token' => $headers['X-Session-Token'],
            'Idempotency-Key' => (string) Str::uuid(),
        ])->patchJson('/api/v1/vehicles/'.$vehicleId, [
            'make' => ' Volkswagen AG ',
            'engine' => ['displacement_cc' => 1498],
            'version' => 1,
        ])->assertOk()
            ->assertJsonPath('make', 'Volkswagen AG')
            ->assertJsonPath('engine.displacement_cc', 1498)
            ->assertJsonPath('version', 2)
            ->assertJsonPath('provenance.engine.source', 'user');

        $this->assertNotNull($patched->json('provenance.engine.confirmed_at'));
        $this->assertDatabaseCount('mileage_observations', 1);

        $deleteHeaders = [
            'X-Session-Token' => $headers['X-Session-Token'],
            'Idempotency-Key' => (string) Str::uuid(),
        ];
        $this->withHeaders($deleteHeaders)
            ->deleteJson('/api/v1/vehicles/'.$vehicleId)
            ->assertNoContent();
        $this->withHeaders($deleteHeaders)
            ->deleteJson('/api/v1/vehicles/'.$vehicleId)
            ->assertNoContent();
        $this->assertDatabaseCount('vehicles', 0);
        $this->assertDatabaseCount('vehicle_configurations', 0);
        $this->assertDatabaseCount('mileage_observations', 0);
    }

    public function test_create_is_idempotent_and_conflicting_payload_is_rejected(): void
    {
        $headers = $this->sessionHeaders();
        $payload = $this->vehiclePayload();

        $first = $this->withHeaders($headers)->postJson('/api/v1/vehicles', $payload)->assertCreated();
        $second = $this->withHeaders($headers)->postJson('/api/v1/vehicles', $payload)->assertCreated();

        $this->assertSame($first->json(), $second->json());
        $this->assertDatabaseCount('vehicles', 1);
        $this->assertDatabaseCount('mileage_observations', 1);
        $this->assertStringNotContainsString(
            $payload['vin'],
            (string) DB::table('idempotency_records')->where('operation', 'createVehicle')->value('response_body'),
        );

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [...$payload, 'model' => 'Touareg'])
            ->assertConflict()
            ->assertJsonPath('error.code', 'IDEMPOTENCY_KEY_CONFLICT');
    }

    public function test_duplicate_vin_and_session_vehicle_limit_have_safe_codes(): void
    {
        $headers = $this->sessionHeaders();
        $this->withHeaders($headers)->postJson('/api/v1/vehicles', $this->vehiclePayload())->assertCreated();

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson('/api/v1/vehicles', $this->vehiclePayload())
            ->assertConflict()
            ->assertJsonPath('error.code', 'DUPLICATE_VIN');

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson('/api/v1/vehicles', $this->vehiclePayload([
                'vin' => 'WAUZZZ8V5KA654321',
            ]))
            ->assertConflict()
            ->assertJsonPath('error.code', 'VEHICLE_LIMIT_EXCEEDED');
    }

    public function test_session_ownership_prevents_idor(): void
    {
        $owner = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($owner)
            ->postJson('/api/v1/vehicles', $this->vehiclePayload())
            ->assertCreated()
            ->json('id');
        $other = $this->sessionHeaders();

        $this->withHeader('X-Session-Token', $other['X-Session-Token'])
            ->getJson('/api/v1/vehicles/'.$vehicleId)
            ->assertNotFound()
            ->assertJsonPath('error.code', 'VEHICLE_NOT_FOUND');
        $this->withHeaders($other)
            ->patchJson('/api/v1/vehicles/'.$vehicleId, ['make' => 'Audi', 'version' => 1])
            ->assertNotFound();
        $this->withHeaders([...$other, 'Idempotency-Key' => (string) Str::uuid()])
            ->deleteJson('/api/v1/vehicles/'.$vehicleId)
            ->assertNotFound();
    }

    public function test_stale_version_and_closed_patch_shape_are_rejected(): void
    {
        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', $this->vehiclePayload())
            ->assertCreated()
            ->json('id');

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->patchJson('/api/v1/vehicles/'.$vehicleId, ['make' => 'VW', 'version' => 7])
            ->assertConflict()
            ->assertJsonPath('error.code', 'VERSION_CONFLICT');

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->patchJson('/api/v1/vehicles/'.$vehicleId, [
                'unsupported_field' => true,
                'version' => 1,
            ])->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_FAILED')
            ->assertJsonPath('error.fields.unsupported_field.0', 'Поле не предусмотрено контрактом.');
    }

    public function test_conditional_engine_and_transmission_rules_validate_create_and_merged_patch(): void
    {
        config(['guest_bootstrap.capabilities.max_vehicles_per_user' => 4]);
        $headers = $this->sessionHeaders();

        $displacementResponse = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', $this->vehiclePayload([
                'engine' => ['engine_code' => 'CZDA'],
            ]))->assertUnprocessable();
        $this->assertSame(
            'Для этого типа топлива требуется объём двигателя.',
            $displacementResponse->json('error.fields')['engine.displacement_cc'][0],
        );

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson('/api/v1/vehicles', $this->minimalVehiclePayload([
                'transmission' => ['type' => 'automatic'],
            ]))->assertCreated()
            ->assertJsonPath('transmission.type', 'automatic')
            ->assertJsonPath('transmission.gears', null);

        $vehicleId = $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson('/api/v1/vehicles', $this->vehiclePayload())
            ->assertCreated()
            ->json('id');

        $electricResponse = $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->patchJson('/api/v1/vehicles/'.$vehicleId, [
                'fuel_type' => 'electric',
                'version' => 1,
            ])->assertUnprocessable();
        $this->assertSame(
            'Для электромобиля объём двигателя должен быть null.',
            $electricResponse->json('error.fields')['engine.displacement_cc'][0],
        );

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson('/api/v1/vehicles', $this->minimalVehiclePayload([
                'fuel_type' => 'electric',
                'engine' => [],
            ]))->assertCreated()
            ->assertJsonPath('engine.displacement_cc', null);

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson('/api/v1/vehicles', $this->minimalVehiclePayload([
                'transmission' => ['type' => 'cvt'],
            ]))->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');
    }

    public function test_patch_can_add_optional_data_clear_nullable_fields_and_cannot_reduce_mileage(): void
    {
        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', $this->minimalVehiclePayload())
            ->assertCreated()
            ->json('id');

        $updated = $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->patchJson('/api/v1/vehicles/'.$vehicleId, [
                'vin' => 'WVGZZZ5NZKW123456',
                'mileage' => ['value' => 1000, 'unit' => 'km'],
                'transmission' => ['type' => 'manual'],
                'version' => 1,
            ])->assertOk()
            ->assertJsonPath('vin_masked', 'WVG**********3456')
            ->assertJsonPath('mileage.value', 1000)
            ->assertJsonPath('transmission.type', 'manual')
            ->assertJsonPath('transmission.gears', null);

        $this->assertDatabaseCount('mileage_observations', 1);

        $decrease = $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->patchJson('/api/v1/vehicles/'.$vehicleId, [
                'mileage' => ['value' => 999, 'unit' => 'km'],
                'version' => $updated->json('version'),
            ])->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');
        $this->assertSame(
            'Снижение пробега доступно только через отдельную операцию с подтверждением.',
            $decrease->json('error.fields')['mileage.value'][0],
        );

        $cleared = $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->patchJson('/api/v1/vehicles/'.$vehicleId, [
                'mileage' => null,
                'transmission' => null,
                'version' => $updated->json('version'),
            ])->assertOk()
            ->assertJsonPath('mileage', null)
            ->assertJsonPath('transmission', null);

        $this->assertSame(3, $cleared->json('version'));
        $this->assertDatabaseCount('mileage_observations', 1);

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->patchJson('/api/v1/vehicles/'.$vehicleId, [
                'mileage' => ['value' => 900, 'unit' => 'km'],
                'version' => 3,
            ])->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');
    }

    public function test_vin_is_addable_once_then_immutable_and_duplicate_safe(): void
    {
        config(['guest_bootstrap.capabilities.max_vehicles_per_user' => 2]);
        $headers = $this->sessionHeaders();
        $firstId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', $this->minimalVehiclePayload())
            ->assertCreated()
            ->json('id');
        $secondId = $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->postJson('/api/v1/vehicles', $this->minimalVehiclePayload(['model' => 'Golf']))
            ->assertCreated()
            ->json('id');

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->patchJson('/api/v1/vehicles/'.$firstId, [
                'vin' => 'WVGZZZ5NZKW123456',
                'version' => 1,
            ])->assertOk();

        $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
            ->patchJson('/api/v1/vehicles/'.$secondId, [
                'vin' => 'WVGZZZ5NZKW123456',
                'version' => 1,
            ])->assertConflict()
            ->assertJsonPath('error.code', 'DUPLICATE_VIN');

        foreach ([null, 'WAUZZZ8V5KA654321'] as $vin) {
            $this->withHeaders([...$headers, 'Idempotency-Key' => (string) Str::uuid()])
                ->patchJson('/api/v1/vehicles/'.$firstId, [
                    'vin' => $vin,
                    'version' => 2,
                ])->assertConflict()
                ->assertJsonPath('error.code', 'VIN_IMMUTABLE');
        }
    }

    public function test_vehicle_errors_are_localized_in_english_and_russian(): void
    {
        $headers = $this->sessionHeaders();
        $this->withHeaders($headers)->postJson('/api/v1/vehicles', $this->vehiclePayload())->assertCreated();

        $this->withHeaders([
            'X-Session-Token' => $headers['X-Session-Token'],
            'Idempotency-Key' => (string) Str::uuid(),
            'Accept-Language' => 'en-US',
        ])->postJson('/api/v1/vehicles', $this->vehiclePayload([
            'vin' => 'WAUZZZ8V5KA654321',
        ]))->assertConflict()
            ->assertJsonPath('error.code', 'VEHICLE_LIMIT_EXCEEDED')
            ->assertJsonPath('error.message', 'The vehicle limit for this account has been reached.')
            ->assertJsonStructure(['error' => ['code', 'message', 'request_id']]);

        $this->withHeaders([
            'X-Session-Token' => $headers['X-Session-Token'],
            'Idempotency-Key' => (string) Str::uuid(),
            'Accept-Language' => 'ru',
        ])->postJson('/api/v1/vehicles', $this->vehiclePayload([
            'vin' => 'WAUZZZ8V5KA654322',
        ]))->assertConflict()
            ->assertJsonPath('error.message', 'Достигнут лимит автомобилей для этой учётной записи.');
    }

    private function sessionHeaders(): array
    {
        $response = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
            ])->assertCreated();

        return [
            'X-Session-Token' => $response->json('session_token'),
            'Idempotency-Key' => (string) Str::uuid(),
            'Accept-Language' => 'ru',
        ];
    }

    private function vehiclePayload(array $overrides = []): array
    {
        return array_replace([
            'vin' => 'WVGZZZ5NZKW123456',
            'make' => ' Volkswagen ',
            'model' => ' Tiguan ',
            'generation' => 'II',
            'fuel_type' => 'petrol',
            'engine' => [
                'displacement_cc' => 1395,
                'engine_code' => 'CZDA',
                'power_kw' => 110,
            ],
            'transmission' => [
                'type' => 'automatic',
                'gears' => 6,
            ],
            'mileage' => ['value' => 84200, 'unit' => 'km'],
            'production_year' => 2019,
            'first_use_date' => '2019-05-20',
            'drivetrain' => 'awd',
            'market' => 'EU',
        ], $overrides);
    }

    private function minimalVehiclePayload(array $overrides = []): array
    {
        return array_replace([
            'make' => 'Other',
            'model' => 'Other model',
            'production_year' => 2020,
            'fuel_type' => 'petrol',
            'engine' => ['displacement_cc' => 1600],
        ], $overrides);
    }
}
