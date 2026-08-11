<?php

return [
    /*
    | Fuel wallet: abstract "milliliters" of agent fuel.
    | Starting tank is granted on first wallet creation (demo credit).
    */
    'fuel' => [
        // Absolute energy units (no hard "full tank" for the user).
        'starting_balance_ml' => (int) env('AGENT_FUEL_STARTING_ML', 5000),
        'capacity_ml' => (int) env('AGENT_FUEL_CAPACITY_ML', 5000), // legacy; not a purchase cap
        'ml_per_1k_tokens' => (float) env('AGENT_FUEL_ML_PER_1K_TOKENS', 40),
        'ml_per_user_message_proxy' => (int) env('AGENT_FUEL_ML_PER_MESSAGE', 80),
        'min_charge_ml' => (int) env('AGENT_FUEL_MIN_CHARGE_ML', 20),
        // Soft "running low" warning (absolute units / ~replies left).
        'low_balance_ml' => (int) env('AGENT_FUEL_LOW_ML', 400),
        'low_approx_replies' => (int) env('AGENT_FUEL_LOW_REPLIES', 5),
        'refuel_stub_packages_ml' => [2000, 5000, 10000],
    ],

    /*
    | Rough cost estimate in local currency (for transparency UI).
    | Tunable without mobile release.
    */
    'pricing' => [
        'currency' => env('AGENT_PRICE_CURRENCY', 'BYN'),
        'cost_per_1k_prompt_tokens' => (float) env('AGENT_COST_PER_1K_PROMPT', 0.004),
        'cost_per_1k_completion_tokens' => (float) env('AGENT_COST_PER_1K_COMPLETION', 0.012),
        'cost_per_proxy_message' => (float) env('AGENT_COST_PER_PROXY_MESSAGE', 0.02),
    ],
];
