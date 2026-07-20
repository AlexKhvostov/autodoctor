<?php

return [
    'api_version' => env('AUTODOCTOR_API_VERSION', '0.4.0-draft'),
    'session_ttl_days' => 30,
    'capabilities' => [
        'public_browse' => true,
        'anonymous_sessions' => true,
        'social_auth_providers' => ['telegram', 'google', 'apple'],
        'email_password_auth' => false,
        'max_vehicles_per_user' => 1,
    ],
    'consent_documents' => [
        [
            'purpose' => 'essential_processing',
            'version' => '2026-07-17',
            'translation_key' => 'api.consents.essential_processing',
            'required' => true,
            'effective_at' => '2026-07-17T00:00:00Z',
        ],
        [
            'purpose' => 'analytics',
            'version' => '2026-07-17',
            'translation_key' => 'api.consents.analytics',
            'required' => false,
            'effective_at' => '2026-07-17T00:00:00Z',
        ],
    ],
];
