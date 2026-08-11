<?php

return [
    /*
    | Absolute path to CA bundle for HTTPS LLM calls.
    | Fixes common Windows PHP error "unable to get local issuer certificate".
    */
    'ca_bundle' => env('AI_CA_BUNDLE', storage_path('certs/cacert.pem')),

    'providers' => [
        'abacus' => [
            'label' => 'Abacus RouteLLM',
            'base_url' => env('AI_ABACUS_BASE_URL', 'https://routellm.abacus.ai'),
            'api_key' => env('AI_ABACUS_API_KEY'),
            'default_model' => env('AI_ABACUS_MODEL', 'route-llm'),
        ],
        'deepseek' => [
            'label' => 'DeepSeek',
            'base_url' => env('AI_DEEPSEEK_BASE_URL', 'https://api.deepseek.com'),
            'api_key' => env('AI_DEEPSEEK_API_KEY'),
            'default_model' => env('AI_DEEPSEEK_MODEL', 'deepseek-chat'),
        ],
    ],

    'whitelist' => ['abacus', 'deepseek'],
];
