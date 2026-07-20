<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class UpdateVehicleRequest extends FormRequest
{
    private const FIELDS = [
        'vin', 'make', 'model', 'generation', 'mileage', 'production_year', 'first_use_date',
        'fuel_type', 'engine', 'transmission', 'drivetrain', 'market', 'version',
    ];

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $normalized = [];
        foreach (['make', 'model'] as $field) {
            if (is_string($this->input($field))) {
                $normalized[$field] = trim($this->input($field));
            }
        }
        if (is_string($this->input('vin'))) {
            $normalized['vin'] = strtoupper(trim($this->input('vin')));
        }
        $this->merge($normalized);
    }

    public function rules(): array
    {
        return [
            'vin' => ['sometimes', 'nullable', 'string', 'regex:/^[A-HJ-NPR-Z0-9]{17}$/'],
            'make' => ['sometimes', 'string', 'min:1', 'max:100'],
            'model' => ['sometimes', 'string', 'min:1', 'max:100'],
            'generation' => ['sometimes', 'nullable', 'string', 'max:100'],
            'mileage' => ['sometimes', 'nullable', 'array:value,unit'],
            'mileage.value' => ['required_with:mileage', 'integer', 'min:0'],
            'mileage.unit' => ['required_with:mileage', Rule::in(['km', 'mi'])],
            'production_year' => ['sometimes', 'integer', 'between:1886,2100'],
            'first_use_date' => ['sometimes', 'nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'fuel_type' => ['sometimes', Rule::in(['petrol', 'diesel', 'hybrid', 'electric', 'lpg', 'other'])],
            'engine' => ['sometimes', 'array:displacement_cc,engine_code,power_kw'],
            'engine.displacement_cc' => ['nullable', 'integer', 'between:1,20000'],
            'engine.engine_code' => ['nullable', 'string', 'max:100'],
            'engine.power_kw' => ['nullable', 'numeric', 'gt:0', 'max:2000'],
            'transmission' => ['sometimes', 'nullable', 'array:type,gears'],
            'transmission.type' => ['required_with:transmission', Rule::in(['manual', 'automatic'])],
            'transmission.gears' => ['nullable', 'integer', 'between:1,12'],
            'drivetrain' => ['sometimes', 'nullable', Rule::in(['fwd', 'rwd', 'awd', 'four_wd', 'other'])],
            'market' => ['sometimes', 'nullable', 'string', 'max:100'],
            'version' => ['required', 'integer', 'min:1'],
        ];
    }

    public function after(): array
    {
        return [
            function (Validator $validator): void {
                foreach (array_diff(array_keys($this->all()), self::FIELDS) as $field) {
                    $validator->errors()->add($field, __('api.fields.unknown'));
                }

                if (count(array_diff(array_keys($this->all()), ['version'])) === 0) {
                    $validator->errors()->add('version', __('api.fields.patch_empty'));
                }
            },
        ];
    }
}
