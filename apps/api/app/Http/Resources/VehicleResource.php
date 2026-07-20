<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class VehicleResource extends JsonResource
{
    public static $wrap = null;

    public function toArray(Request $request): array
    {
        $configuration = $this->configuration;

        return [
            'id' => $this->id,
            'vin_masked' => $this->vin_ciphertext === null
                ? null
                : substr($this->vin_ciphertext, 0, 3).str_repeat('*', 10).$this->vin_last4,
            'make' => $configuration->make,
            'model' => $configuration->model,
            'generation' => $configuration->generation,
            'mileage' => $this->current_mileage === null ? null : [
                'value' => $this->current_mileage,
                'unit' => $this->mileage_unit,
            ],
            'production_year' => $this->production_year,
            'first_use_date' => $this->first_use_date?->format('Y-m-d'),
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
            'profile_status' => $this->profile_status,
            'recommendation_scope' => $this->plan_eligibility,
            'provenance' => $configuration->field_provenance,
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
            'version' => $this->version,
        ];
    }
}
