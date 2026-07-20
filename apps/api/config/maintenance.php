<?php

return [
    'ruleset_version' => 'by-pilot-baseline-2',
    'algorithm_version' => 'maintenance-v3',
    'config_version' => 'condition-wear-v1',
    'soon_threshold' => [
        'mileage_km' => 1500,
        'days' => 30,
    ],
    'consumable_thresholds' => [
        'warning_at' => 0.8,
        'danger_at' => 1.0,
    ],
    'condition_wear_thresholds' => [
        'brake_pads' => ['warning_percent' => 70, 'action_percent' => 85],
        'brake_discs' => ['warning_percent' => 70, 'action_percent' => 90],
        'tire_condition_inspection' => ['warning_percent' => 60, 'action_percent' => 80],
    ],
];
