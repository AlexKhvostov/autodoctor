<?php

return [
    'consents' => [
        'essential_processing' => [
            'title' => 'Essential data processing',
            'text' => 'Processing of data required for AutoDoctor to operate, including vehicle data.',
        ],
        'analytics' => [
            'title' => 'Usage analytics',
            'text' => 'Anonymized analytics helps us improve the product. Your decision does not affect core features.',
        ],
    ],
    'errors' => [
        'validation_failed' => 'Check the submitted fields.',
        'not_found' => 'Resource not found.',
        'internal_server_error' => 'Internal server error.',
        'session_token_required' => 'An anonymous session token is required.',
        'invalid_session_token' => 'The anonymous session token is invalid.',
        'session_revoked' => 'The anonymous session has been closed.',
        'session_expired' => 'The anonymous session has expired.',
        'idempotency_key_uuid' => 'The Idempotency-Key header must contain a UUID.',
        'idempotency_key_conflict' => 'This Idempotency-Key has already been used with a different request.',
        'duplicate_vin' => 'A vehicle with this VIN already exists.',
        'vin_immutable' => 'An assigned VIN cannot be changed or removed.',
        'vehicle_limit_exceeded' => 'The vehicle limit for this account has been reached.',
        'vehicle_not_found' => 'Vehicle not found.',
        'version_conflict' => 'The vehicle was changed by another request. Refresh it and try again.',
        'plan_preparing' => 'The maintenance plan is being prepared. Please try again.',
        'preference_version_conflict' => 'The preference was changed by another request. Refresh it and try again.',
    ],
    'fields' => [
        'unknown' => 'The field is not defined by the API contract.',
        'required_consent_decision' => 'A decision is required for mandatory consent :purpose.',
        'required_consent_granted' => 'Mandatory consent must be granted.',
        'stale_consent_version' => 'The consent version is not current.',
        'displacement_required' => 'Engine displacement is required for this fuel type.',
        'displacement_forbidden' => 'Engine displacement must be null for an electric vehicle.',
        'mileage_decrease' => 'Mileage can only be decreased through the dedicated confirmed operation.',
        'patch_empty' => 'At least one vehicle field must be changed.',
        'history_known_reference' => 'A known completion requires a performed date and/or mileage.',
        'history_reference_prohibited' => 'Performed date and mileage are only allowed for a known completion.',
        'history_mileage_above_current' => 'Performed mileage cannot exceed the current confirmed vehicle mileage.',
        'mileage_decrease_confirmation' => 'Confirm the mileage decrease explicitly.',
        'mileage_decrease_reason' => 'A reason is required for a mileage decrease.',
        'condition_mileage_above_current' => 'Observation mileage cannot exceed the current confirmed vehicle mileage.',
        'work_not_applicable' => 'This work item is not applicable to the vehicle.',
    ],
];
