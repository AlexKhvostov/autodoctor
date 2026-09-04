<?php

return [
    /*
    | Firebase project (same as mobile google-services.json → project_id).
    */
    'project_id' => env('FIREBASE_PROJECT_ID', 'autodoctor-by'),

    /*
    | Absolute or storage-relative path to a service account JSON
    | with role "Firebase Remote Config Admin" (or Editor).
    | Example: storage/app/firebase-service-account.json
    */
    'credentials' => env('FIREBASE_CREDENTIALS', 'storage/app/firebase-service-account.json'),

    /*
    | Remote Config parameter key for monetization JSON (string value in Console).
    */
    'monetization_key' => env('FIREBASE_MONETIZATION_KEY', 'monetization_v1'),

    /*
    | How long Laravel caches the fetched Remote Config template.
    */
    'cache_seconds' => (int) env('FIREBASE_REMOTE_CONFIG_CACHE_SECONDS', 300),

    /*
    | CA bundle for Google OAuth / Remote Config HTTPS (Windows-friendly).
    | Falls back to AI_CA_BUNDLE / storage/certs/cacert.pem in code if empty.
    */
    'ca_bundle' => env('FIREBASE_CA_BUNDLE', env('AI_CA_BUNDLE', storage_path('certs/cacert.pem'))),

    /*
    | When true, always use bundled defaults (useful in phpunit / offline).
    */
    'force_defaults' => (bool) env('FIREBASE_FORCE_DEFAULTS', false),
];
