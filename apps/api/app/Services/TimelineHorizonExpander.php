<?php

namespace App\Services;

use Carbon\CarbonImmutable;

class TimelineHorizonExpander
{
    /**
     * @param  array<string, mixed>  $row
     * @return list<array<string, mixed>>
     */
    public function expand(
        array $row,
        string $ruleKind,
        ?int $currentMileageKm,
        CarbonImmutable $asOf,
    ): array {
        $intervalKm = data_get($row, 'plan_item.interval.mileage_km');
        $intervalDays = data_get($row, 'plan_item.interval.days');
        $intervalKm = is_numeric($intervalKm) ? (int) $intervalKm : null;
        $intervalDays = is_numeric($intervalDays) ? (int) $intervalDays : null;

        if ($ruleKind === 'condition_based' || ($intervalKm === null && $intervalDays === null)) {
            return [$row];
        }

        $dueDateRaw = data_get($row, 'plan_item.due.date');
        $dueMileageRaw = data_get($row, 'plan_item.due.mileage.value');
        $date = is_string($dueDateRaw) && $dueDateRaw !== ''
            ? CarbonImmutable::parse($dueDateRaw)
            : null;
        $km = is_numeric($dueMileageRaw) ? (int) $dueMileageRaw : null;
        $synthesized = false;

        if ($date === null && $km === null) {
            if ($intervalDays !== null) {
                $date = $asOf->addDays($intervalDays);
            }
            if ($intervalKm !== null && $currentMileageKm !== null) {
                $km = $currentMileageKm + $intervalKm;
            }
            $synthesized = $date !== null || $km !== null;
        }

        if ($date === null && $km === null) {
            return [$row];
        }

        $horizonYears = (int) config('maintenance.timeline_horizon.years', 5);
        $horizonKmDelta = (int) config('maintenance.timeline_horizon.mileage_km', 120000);
        $maxOccurrences = (int) config('maintenance.timeline_horizon.max_per_item', 16);
        $horizonDate = $asOf->addYears($horizonYears);
        $horizonKm = $currentMileageKm !== null ? $currentMileageKm + $horizonKmDelta : null;

        $occurrences = [];
        for ($index = 0; $index < $maxOccurrences; $index++) {
            if (! $this->withinHorizon($date, $km, $horizonDate, $horizonKm)) {
                break;
            }

            $occurrences[] = $this->cloneOccurrence($row, $date, $km, $index, $synthesized);

            $advanced = false;
            if ($intervalDays !== null && $date !== null) {
                $date = $date->addDays($intervalDays);
                $advanced = true;
            }
            if ($intervalKm !== null && $km !== null) {
                $km += $intervalKm;
                $advanced = true;
            }
            if (! $advanced) {
                break;
            }
        }

        return $occurrences === [] ? [$row] : $occurrences;
    }

    private function withinHorizon(
        ?CarbonImmutable $date,
        ?int $km,
        CarbonImmutable $horizonDate,
        ?int $horizonKm,
    ): bool {
        $dateOk = $date === null || $date->lte($horizonDate);
        $kmOk = $km === null || $horizonKm === null || $km <= $horizonKm;

        if ($date !== null && $km !== null) {
            return $dateOk || $kmOk;
        }

        return $dateOk && $kmOk;
    }

    /**
     * @param  array<string, mixed>  $row
     * @return array<string, mixed>
     */
    private function cloneOccurrence(
        array $row,
        ?CarbonImmutable $date,
        ?int $km,
        int $index,
        bool $synthesized,
    ): array {
        /** @var array<string, mixed> $clone */
        $clone = json_decode(json_encode($row), true);
        $clone['plan_item']['due']['date'] = $date?->format('Y-m-d');
        $clone['plan_item']['due']['mileage'] = $km === null ? null : [
            'value' => $km,
            'unit' => 'km',
        ];
        $clone['plan_item']['requires_check_now'] = false;
        $clone['presentation']['temporal'] = $date === null ? null : [
            'kind' => 'moment',
            'at' => $date->format('Y-m-d'),
        ];
        $clone['presentation']['mileage'] = $km === null ? null : [
            'value' => $km,
            'unit' => 'km',
        ];

        if ($index > 0 || $synthesized) {
            $clone['plan_item']['status'] = 'current';
            $clone['presentation']['basis'] = 'forecast';
            $clone['presentation']['action_level'] = 'recommendation';
        }

        return $clone;
    }
}
