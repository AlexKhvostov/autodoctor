<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Http\Requests\StoreVehicleRequest;
use App\Models\AnonymousSession;
use App\Models\MileageObservation;
use App\Models\Vehicle;
use App\Models\VehicleConfiguration;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class VehicleService
{
    public function __construct(
        private readonly PlanCalculator $plans,
    ) {}

    public function create(AnonymousSession $session, array $data): Vehicle
    {
        $vin = $data['vin'] ?? null;
        $vinHash = $vin === null ? null : $this->vinHash($vin);

        if ($vinHash !== null && $this->duplicateVinExists($vinHash)) {
            throw new ApiException('DUPLICATE_VIN', __('api.errors.duplicate_vin'), 409);
        }

        $limit = (int) config('guest_bootstrap.capabilities.max_vehicles_per_user');
        if ($session->vehicles()->count() >= $limit) {
            throw new ApiException('VEHICLE_LIMIT_EXCEEDED', __('api.errors.vehicle_limit_exceeded'), 409);
        }

        return DB::transaction(function () use ($session, $data, $vin, $vinHash): Vehicle {
            $now = now();
            $configuration = VehicleConfiguration::query()->create(
                $this->configurationAttributes($data, $this->provenance(array_keys($data), $now->toISOString())),
            );

            $vehicle = Vehicle::query()->create([
                'anonymous_session_id' => $session->id,
                'user_id' => null,
                'configuration_id' => $configuration->id,
                'vin_ciphertext' => $vin,
                'vin_hash' => $vinHash,
                'vin_last4' => $vin === null ? null : substr($vin, -4),
                'production_year' => $data['production_year'],
                'first_use_date' => $data['first_use_date'] ?? null,
                'current_mileage' => data_get($data, 'mileage.value'),
                'mileage_unit' => data_get($data, 'mileage.unit'),
                'profile_status' => 'pending_review',
                'plan_eligibility' => 'universal_type_only',
                'version' => 1,
            ]);

            if (($data['mileage'] ?? null) !== null) {
                $this->recordMileage($vehicle, $data['mileage'], $now);
            }

            $vehicle->load('configuration');
            $this->plans->calculate($vehicle);

            return $vehicle;
        });
    }

    public function update(AnonymousSession $session, string $id, array $patch): Vehicle
    {
        return DB::transaction(function () use ($session, $id, $patch): Vehicle {
            $vehicle = $this->owned($session, $id, true);

            if ($vehicle->version !== $patch['version']) {
                throw new ApiException('VERSION_CONFLICT', __('api.errors.version_conflict'), 409);
            }

            $configuration = $vehicle->configuration;
            $current = $this->profileData($vehicle);
            $changes = array_diff_key($patch, ['version' => true]);
            $merged = array_replace($current, $changes);
            foreach (['engine', 'transmission'] as $field) {
                if (isset($changes[$field]) && is_array($current[$field])) {
                    $merged[$field] = array_replace($current[$field], $changes[$field]);
                }
            }

            $validator = Validator::make($merged, StoreVehicleRequest::profileRules($merged), [
                'engine.displacement_cc.required' => __('api.fields.displacement_required'),
                'engine.displacement_cc.prohibited' => __('api.fields.displacement_forbidden'),
            ]);
            if ($validator->fails()) {
                throw ValidationException::withMessages($validator->errors()->toArray());
            }

            $this->validateVinChange($vehicle, $changes);
            $this->validateMileageChange($vehicle, $changes);

            $now = now();
            $provenance = $configuration->field_provenance;
            foreach (array_keys($changes) as $field) {
                $provenance[$field] = ['source' => 'user', 'confirmed_at' => $now->toISOString()];
            }

            $configuration->fill($this->configurationAttributes($merged, $provenance))->save();

            $vehicleChanges = array_intersect_key($changes, array_flip([
                'production_year', 'first_use_date',
            ]));
            if (array_key_exists('vin', $changes) && $changes['vin'] !== $current['vin']) {
                $vehicleChanges = [
                    ...$vehicleChanges,
                    'vin_ciphertext' => $changes['vin'] === null ? null : Crypt::encryptString($changes['vin']),
                    'vin_hash' => $changes['vin'] === null ? null : $this->vinHash($changes['vin']),
                    'vin_last4' => $changes['vin'] === null ? null : substr($changes['vin'], -4),
                ];
            }
            if (array_key_exists('mileage', $changes)) {
                $vehicleChanges = [
                    ...$vehicleChanges,
                    'current_mileage' => data_get($changes, 'mileage.value'),
                    'mileage_unit' => data_get($changes, 'mileage.unit'),
                ];
            }
            $updated = Vehicle::query()
                ->whereKey($vehicle->id)
                ->where('version', $patch['version'])
                ->update([...$vehicleChanges, 'version' => $patch['version'] + 1, 'updated_at' => $now]);

            if ($updated !== 1) {
                throw new ApiException('VERSION_CONFLICT', __('api.errors.version_conflict'), 409);
            }

            if (($changes['mileage'] ?? null) !== null) {
                $this->recordMileage($vehicle, $changes['mileage'], $now);
            }

            $fresh = $vehicle->fresh('configuration');
            $this->plans->calculate($fresh);

            return $fresh;
        });
    }

    public function updateMileage(AnonymousSession $session, string $id, array $data): array
    {
        return DB::transaction(function () use ($session, $id, $data): array {
            $vehicle = $this->owned($session, $id, true);
            if ($vehicle->version !== $data['version']) {
                throw new ApiException('VERSION_CONFLICT', __('api.errors.version_conflict'), 409);
            }

            $currentKm = $vehicle->current_mileage === null
                ? null
                : $this->mileageInKilometres($vehicle->current_mileage, $vehicle->mileage_unit);
            $nextKm = $this->mileageInKilometres($data['mileage']['value'], $data['mileage']['unit']);
            if ($currentKm !== null && $nextKm < $currentKm
                && (($data['decrease_confirmed'] ?? false) !== true || blank($data['decrease_reason'] ?? null))) {
                throw ValidationException::withMessages([
                    'decrease_confirmed' => [__('api.fields.mileage_decrease_confirmation')],
                    'decrease_reason' => [__('api.fields.mileage_decrease_reason')],
                ]);
            }

            $updated = Vehicle::query()
                ->whereKey($vehicle->id)
                ->where('version', $data['version'])
                ->update([
                    'current_mileage' => $data['mileage']['value'],
                    'mileage_unit' => $data['mileage']['unit'],
                    'version' => $data['version'] + 1,
                    'updated_at' => now(),
                ]);
            if ($updated !== 1) {
                throw new ApiException('VERSION_CONFLICT', __('api.errors.version_conflict'), 409);
            }

            $observation = MileageObservation::query()->create([
                'vehicle_id' => $vehicle->id,
                'value' => $data['mileage']['value'],
                'unit' => $data['mileage']['unit'],
                'source' => 'manual',
                'observed_at' => $data['observed_at'],
            ]);
            $fresh = $vehicle->fresh('configuration');
            $snapshot = $this->plans->calculate($fresh);

            return [$fresh, $observation, $snapshot];
        });
    }

    public function delete(AnonymousSession $session, string $id): void
    {
        DB::transaction(function () use ($session, $id): void {
            $vehicle = $this->owned($session, $id, true);
            $configurationId = $vehicle->configuration_id;
            $vehicle->delete();
            VehicleConfiguration::query()->whereKey($configurationId)->delete();
        });
    }

    public function owned(AnonymousSession $session, string $id, bool $forUpdate = false): Vehicle
    {
        $query = Vehicle::query()
            ->with('configuration')
            ->where('anonymous_session_id', $session->id)
            ->whereKey($id);

        if ($forUpdate) {
            $query->lockForUpdate();
        }

        $vehicle = $query->first();
        if ($vehicle === null) {
            throw new ApiException('VEHICLE_NOT_FOUND', __('api.errors.vehicle_not_found'), 404);
        }

        return $vehicle;
    }

    private function configurationAttributes(array $data, array $provenance): array
    {
        return [
            'make' => $data['make'],
            'model' => $data['model'],
            'generation' => $data['generation'] ?? null,
            'engine_displacement_cc' => data_get($data, 'engine.displacement_cc'),
            'engine_code' => data_get($data, 'engine.engine_code'),
            'engine_power_kw' => data_get($data, 'engine.power_kw'),
            'fuel_type' => $data['fuel_type'],
            'transmission_type' => data_get($data, 'transmission.type'),
            'transmission_gears' => data_get($data, 'transmission.gears'),
            'drivetrain' => $data['drivetrain'] ?? null,
            'market' => $data['market'] ?? null,
            'field_provenance' => $provenance,
            'source' => 'user',
            'confirmed_at' => now(),
        ];
    }

    private function profileData(Vehicle $vehicle): array
    {
        $configuration = $vehicle->configuration;

        return [
            'make' => $configuration->make,
            'model' => $configuration->model,
            'generation' => $configuration->generation,
            'vin' => $vehicle->vin_ciphertext,
            'mileage' => $vehicle->current_mileage === null ? null : [
                'value' => $vehicle->current_mileage,
                'unit' => $vehicle->mileage_unit,
            ],
            'production_year' => $vehicle->production_year,
            'first_use_date' => $vehicle->first_use_date?->format('Y-m-d'),
            'fuel_type' => $configuration->fuel_type,
            'engine' => [
                'displacement_cc' => $configuration->engine_displacement_cc,
                'engine_code' => $configuration->engine_code,
                'power_kw' => $configuration->engine_power_kw === null
                    ? null
                    : (float) $configuration->engine_power_kw,
            ],
            'transmission' => $configuration->transmission_type === null ? null : [
                'type' => $configuration->transmission_type,
                'gears' => $configuration->transmission_gears,
            ],
            'drivetrain' => $configuration->drivetrain,
            'market' => $configuration->market,
        ];
    }

    private function provenance(array $fields, string $confirmedAt): array
    {
        return collect($fields)
            ->intersect([
                'vin', 'make', 'model', 'generation', 'production_year', 'mileage',
                'first_use_date', 'fuel_type', 'engine', 'transmission', 'drivetrain', 'market',
            ])
            ->mapWithKeys(fn (string $field): array => [
                $field => ['source' => 'user', 'confirmed_at' => $confirmedAt],
            ])
            ->all();
    }

    private function vinHash(string $vin): string
    {
        $key = (string) config('vehicle.vin_hash_key');
        if ($key === '') {
            throw new ApiException('INTERNAL_SERVER_ERROR', __('api.errors.internal_server_error'), 500);
        }

        return hash_hmac('sha256', $vin, $key);
    }

    private function duplicateVinExists(string $vinHash, ?string $exceptId = null): bool
    {
        return Vehicle::query()
            ->where('vin_hash', $vinHash)
            ->when($exceptId !== null, fn ($query) => $query->where('id', '!=', $exceptId))
            ->exists();
    }

    private function validateVinChange(Vehicle $vehicle, array $changes): void
    {
        if (! array_key_exists('vin', $changes) || $changes['vin'] === $vehicle->vin_ciphertext) {
            return;
        }

        if ($vehicle->vin_ciphertext !== null) {
            throw new ApiException('VIN_IMMUTABLE', __('api.errors.vin_immutable'), 409);
        }

        if ($changes['vin'] !== null && $this->duplicateVinExists(
            $this->vinHash($changes['vin']),
            $vehicle->id,
        )) {
            throw new ApiException('DUPLICATE_VIN', __('api.errors.duplicate_vin'), 409);
        }
    }

    private function validateMileageChange(Vehicle $vehicle, array $changes): void
    {
        if (! array_key_exists('mileage', $changes) || $changes['mileage'] === null) {
            return;
        }

        $baselineValue = $vehicle->current_mileage;
        $baselineUnit = $vehicle->mileage_unit;
        if ($baselineValue === null) {
            $lastObservation = $vehicle->mileageObservations()
                ->latest('observed_at')
                ->latest('created_at')
                ->first();
            $baselineValue = $lastObservation?->value;
            $baselineUnit = $lastObservation?->unit;
        }
        if ($baselineValue === null || $baselineUnit === null) {
            return;
        }

        $current = $this->mileageInKilometres($baselineValue, $baselineUnit);
        $next = $this->mileageInKilometres($changes['mileage']['value'], $changes['mileage']['unit']);
        if ($next < $current) {
            throw ValidationException::withMessages([
                'mileage.value' => [__('api.fields.mileage_decrease')],
            ]);
        }
    }

    private function mileageInKilometres(int $value, string $unit): float
    {
        return $unit === 'mi' ? $value * 1.609344 : $value;
    }

    private function recordMileage(Vehicle $vehicle, array $mileage, $observedAt): void
    {
        MileageObservation::query()->create([
            'vehicle_id' => $vehicle->id,
            'value' => $mileage['value'],
            'unit' => $mileage['unit'],
            'source' => 'manual',
            'observed_at' => $observedAt,
        ]);
    }
}
