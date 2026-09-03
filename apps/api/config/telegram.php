<?php

return [
    'bot_token' => env('TELEGRAM_BOT_TOKEN'),
    'webhook_secret' => env('TELEGRAM_WEBHOOK_SECRET'),
    'api_base' => env('TELEGRAM_API_BASE', 'https://api.telegram.org'),

    /**
     * Comma-separated numeric Telegram user IDs (optional backup).
     * Main allowlist is the admin: Telegram → Писали боту / Белый список.
     * Empty env together with nobody flagged in admin means nobody is allowed.
     */
    'allowlist_ids' => env('TELEGRAM_ALLOWLIST_IDS', ''),

    'messages' => [
        'closed_pilot' => 'AutoDoctor сейчас в закрытом пилоте. Если ждали доступ — напишите нам.',
        'start' => implode("\n\n", [
            'AutoDoctor — журнал обслуживания авто в переписке.',
            'Пишите боту: мы обрабатываем сообщения, чтобы вести карточку машины и историю работ.',
            'Расскажите про машину — что помните: марка, год, пробег.',
        ]),
        'continue' => 'Принял. Разбор текста нейросетью подключим следующим шагом. Пока можете дописать, что помните про машину: марка, год, пробег.',
    ],
];
