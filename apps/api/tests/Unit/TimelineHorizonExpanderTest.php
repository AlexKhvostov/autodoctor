<?php

namespace Tests\Unit;

use App\Services\TimelineHorizonExpander;
use Carbon\CarbonImmutable;
use Tests\TestCase;

class TimelineHorizonExpanderTest extends TestCase
{
    public function test_projects_interval_work_across_horizon(): void
    {
        $row = [
            'type' => 'plan_item',
            'plan_item' => [
                'work_code' => 'engine_oil',
                'status' => 'overdue',
                'requires_check_now' => false,
                'due' => [
                    'date' => null,
                    'mileage' => ['value' => 20000, 'unit' => 'km'],
                ],
                'interval' => [
                    'mileage_km' => 10000,
                    'days' => 365,
                ],
            ],
            'presentation' => [
                'basis' => 'confirmed',
                'action_level' => 'required',
            ],
        ];

        $expanded = (new TimelineHorizonExpander())->expand(
            $row,
            'interval_based',
            25000,
            CarbonImmutable::parse('2026-08-26'),
        );

        $this->assertGreaterThanOrEqual(8, count($expanded));
        $this->assertSame(20000, $expanded[0]['plan_item']['due']['mileage']['value']);
        $this->assertSame('confirmed', $expanded[0]['presentation']['basis']);
        $this->assertSame('forecast', $expanded[1]['presentation']['basis']);
        $this->assertSame(30000, $expanded[1]['plan_item']['due']['mileage']['value']);
    }

    public function test_synthesizes_forecast_when_due_is_unknown(): void
    {
        $row = [
            'type' => 'plan_item',
            'plan_item' => [
                'work_code' => 'cabin_filter',
                'status' => 'unknown',
                'requires_check_now' => true,
                'due' => ['date' => null, 'mileage' => null],
                'interval' => [
                    'mileage_km' => 15000,
                    'days' => 365,
                ],
            ],
            'presentation' => [
                'basis' => 'missing_data',
                'action_level' => 'required',
            ],
        ];

        $expanded = (new TimelineHorizonExpander())->expand(
            $row,
            'interval_based',
            40000,
            CarbonImmutable::parse('2026-08-26'),
        );

        $this->assertGreaterThan(1, count($expanded));
        $this->assertFalse($expanded[0]['plan_item']['requires_check_now']);
        $this->assertSame('forecast', $expanded[0]['presentation']['basis']);
        $this->assertSame(55000, $expanded[0]['plan_item']['due']['mileage']['value']);
        $this->assertSame('2027-08-26', $expanded[0]['plan_item']['due']['date']);
    }
}
