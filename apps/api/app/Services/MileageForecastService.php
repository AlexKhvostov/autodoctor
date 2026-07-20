<?php

namespace App\Services;

use App\Http\Resources\MileageObservationResource;
use App\Models\Vehicle;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;

class MileageForecastService
{
    public const ALGORITHM_VERSION = 'mileage-forecast-v1';

    public function make(Vehicle $vehicle, Request $request): array
    {
        $observations = $vehicle->mileageObservations()
            ->orderBy('observed_at')
            ->orderBy('created_at')
            ->orderBy('id')
            ->get();
        $canonical = $observations->map(fn ($item): array => [
            'id' => $item->id,
            'value_km' => $this->km($item->value, $item->unit),
            'observed_at' => $item->observed_at->toISOString(),
        ])->values();
        $usable = $canonical->filter(function (array $item, int $index) use ($canonical): bool {
            if ($index === 0) {
                return true;
            }
            $previous = $canonical[$index - 1];

            return $item['observed_at'] > $previous['observed_at']
                && $item['value_km'] >= $previous['value_km'];
        })->values();

        $method = 'default_assumption';
        $annual = 10000;
        $confidence = 'low';
        if ($usable->count() >= 2) {
            $first = $usable->first();
            $last = $usable->last();
            $days = CarbonImmutable::parse($first['observed_at'])
                ->diffInDays(CarbonImmutable::parse($last['observed_at']));
            if ($days > 0) {
                $method = 'empirical';
                $annual = max(0, (int) round(($last['value_km'] - $first['value_km']) * 365 / $days));
                $confidence = $days >= 365 && $usable->count() >= 3
                    ? 'high'
                    : ($days >= 90 ? 'medium' : 'low');
            }
        }

        $input = [
            'algorithm_version' => self::ALGORITHM_VERSION,
            'observations' => $canonical->all(),
        ];
        $lastModel = $observations->last();

        return [
            'vehicle_id' => $vehicle->id,
            'annual_distance' => ['value' => $annual, 'unit' => 'km'],
            'method' => $method,
            'confidence' => $confidence,
            'observation_count' => $usable->count(),
            'estimate_label' => app()->getLocale() === 'en'
                ? ($method === 'empirical' ? 'Estimate based on confirmed mileage' : 'Estimate based on assumption')
                : ($method === 'empirical' ? 'Оценка по подтверждённому пробегу' : 'Оценка на основе допущения'),
            'next_work_window' => null,
            'algorithm_version' => self::ALGORITHM_VERSION,
            'input_hash' => 'sha256:'.hash('sha256', json_encode($input, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES)),
            'calculated_at' => now()->toISOString(),
            'last_confirmed_observation' => $lastModel === null
                ? null
                : (new MileageObservationResource($lastModel))->resolve($request),
        ];
    }

    private function km(int $value, string $unit): int
    {
        return $unit === 'mi' ? (int) round($value * 1.609344) : $value;
    }
}
