<?php

return [
    'bot_token' => env('TELEGRAM_BOT_TOKEN'),
    'webhook_secret' => env('TELEGRAM_WEBHOOK_SECRET'),
    'api_base' => env('TELEGRAM_API_BASE', 'https://api.telegram.org'),
    'owner_chat_id' => (int) env('TELEGRAM_OWNER_CHAT_ID', 287536885),
    'access_request_cooldown_minutes' => (int) env('TELEGRAM_ACCESS_REQUEST_COOLDOWN_MINUTES', 60),

    /**
     * Comma-separated numeric Telegram user IDs (optional backup).
     * Main allowlist is the admin: Telegram → Писали боту / Белый список.
     * Empty env together with nobody flagged in admin means nobody is allowed.
     */
    'allowlist_ids' => env('TELEGRAM_ALLOWLIST_IDS', ''),
    'mini_app_url' => env('TELEGRAM_MINI_APP_URL', rtrim((string) env('APP_URL', 'http://localhost'), '/').'/telegram/app'),

    'messages' => [
        'closed_pilot' => 'AutoDoctor сейчас в закрытом пилоте. Если ждали доступ — нажмите кнопку ниже.',
        'access_request_button' => 'Запросить доступ',
        'access_request_sent' => 'Заявку отправили. Когда доступ откроют — напишите боту ещё раз.',
        'access_request_already' => 'Заявку уже отправили. Подождите, пожалуйста.',
        'access_request_owner_unavailable' => 'Сейчас не можем отправить заявку. Напишите нам позже.',
        'start' => implode("\n\n", [
            'AutoDoctor — журнал обслуживания авто в переписке.',
            'Пишите боту: мы обрабатываем сообщения, чтобы вести карточку машины и историю работ.',
            'Расскажите про машину — что помните: марка, год, пробег.',
        ]),
        'ai_unavailable' => 'Ассистент сейчас недоступен. Попробуйте чуть позже.',
        'save_vehicle_button' => 'Записать',
        'open_app_button' => 'Открыть приложение',
        'open_app_menu' => 'Открыть',
    ],
];
