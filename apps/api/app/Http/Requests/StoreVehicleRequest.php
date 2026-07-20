<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreVehicleRequest extends FormRequest
{
    private const FIELDS = [
        'vin', 'make', 'model', 'generation', 'mileage', 'production_year',
        'first_use_date', 'fuel_type', 'engine', 'transmission', 'drivetrain', 'market',
    ];

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'vin' => is_string($this->vin) ? strtoupper(trim($this->vin)) : $this->vin,
            'make' => is_string($this->make) ? trim($this->make) : $this->make,
            'model' => is_string($this->model) ? trim($this->model) : $this->model,
        ]);
    }

    public function rules(): array
    {
        return self::profileRules($this->all());
    }

    public static function profileRules(array $data): array
    {
        return [
            'vin' => ['nullable', 'string', 'regex:/^[A-HJ-NPR-Z0-9]{17}$/'],
            'make' => ['required', 'string', 'min:1', 'max:100'],
            'model' => ['required', 'string', 'min:1', 'max:100'],
            'generation' => ['nullable', 'string', 'max:100'],
            'mileage' => ['nullable', 'array:value,unit'],
            'mileage.value' => ['required_with:mileage', 'integer', 'min:0'],
            'mileage.unit' => ['required_with:mileage', Rule::in(['km', 'mi'])],
            'production_year' => ['required', 'integer', 'between:1886,2100'],
            'first_use_date' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
            'fuel_type' => ['required', Rule::in(['petrol', 'diesel', 'hybrid', 'electric', 'lpg', 'other'])],
            'engine' => ['present', 'array:displacement_cc,engine_code,power_kw'],
            'engine.displacement_cc' => [
                'nullable',
                Rule::requiredIf(fn (): bool => in_array($data['fuel_type'] ?? null, ['petrol', 'diesel', 'hybrid', 'lpg'], true)),
                Rule::prohibitedIf(fn (): bool => ($data['fuel_type'] ?? null) === 'electric'),
                'integer',
                'between:1,20000',
            ],
            'engine.engine_code' => ['nullable', 'string', 'max:100'],
            'engine.power_kw' => ['nullable', 'numeric', 'gt:0', 'max:2000'],
            'transmission' => ['nullable', 'array:type,gears'],
            'transmission.type' => ['required_with:transmission', Rule::in(['manual', 'automatic'])],
            'transmission.gears' => ['nullable', 'integer', 'between:1,12'],
            'drivetrain' => ['nullable', Rule::in(['fwd', 'rwd', 'awd', 'four_wd', 'other'])],
            'market' => ['nullable', 'string', 'max:100'],
        ];
    }

    public function after(): array
    {
        return [
            function (Validator $validator): void {
                foreach (array_diff(array_keys($this->all()), self::FIELDS) as $field) {
                    $validator->errors()->add($field, __('api.fields.unknown'));
                }

            },
        ];
    }

    public function messages(): array
    {
        return [
            'engine.displacement_cc.required' => __('api.fields.displacement_required'),
            'engine.displacement_cc.prohibited' => __('api.fields.displacement_forbidden'),
        ];
    }
}
