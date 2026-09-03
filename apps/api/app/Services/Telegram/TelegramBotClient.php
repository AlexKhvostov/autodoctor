<?php

namespace App\Services\Telegram;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class TelegramBotClient
{
    /**
     * @param  array<string, mixed>|null  $replyMarkup
     */
    public function sendMessage(int $chatId, string $text, ?array $replyMarkup = null): void
    {
        $token = (string) config('telegram.bot_token');
        if ($token === '' || $chatId === 0) {
            Log::warning('telegram.send_skipped', [
                'reason' => $token === '' ? 'missing_bot_token' : 'empty_chat',
                'chat_id' => $chatId,
            ]);

            return;
        }

        $payload = [
            'chat_id' => $chatId,
            'text' => $text,
        ];
        if ($replyMarkup !== null) {
            $payload['reply_markup'] = $replyMarkup;
        }

        $response = Http::timeout(10)->acceptJson()->post($this->methodUrl('sendMessage'), $payload);

        if ($response->failed()) {
            Log::error('telegram.send_failed', [
                'chat_id' => $chatId,
                'status' => $response->status(),
                'body' => mb_substr($response->body(), 0, 500),
            ]);
        }
    }

    public function answerCallbackQuery(string $callbackQueryId, ?string $text = null): void
    {
        if ($callbackQueryId === '' || (string) config('telegram.bot_token') === '') {
            return;
        }

        $payload = ['callback_query_id' => $callbackQueryId];
        if (filled($text)) {
            $payload['text'] = $text;
        }

        Http::timeout(10)->acceptJson()->post($this->methodUrl('answerCallbackQuery'), $payload);
    }

    public function saveDraftKeyboard(string $callbackData = 'save_vehicle'): array
    {
        return [
            'inline_keyboard' => [[
                [
                    'text' => (string) config('telegram.messages.save_vehicle_button'),
                    'callback_data' => $callbackData,
                ],
            ]],
        ];
    }

    public function conversationKeyboard(bool $offerSave, string $callbackData = 'save_vehicle'): ?array
    {
        if (! $offerSave) {
            return $this->openAppReplyKeyboard();
        }

        return $this->saveDraftKeyboard($callbackData);
    }

    public function openAppReplyKeyboard(): ?array
    {
        $appUrl = $this->miniAppUrl();
        if ($appUrl === null) {
            return null;
        }

        return [
            'keyboard' => [[
                [
                    'text' => (string) config('telegram.messages.open_app_button'),
                    'web_app' => ['url' => $appUrl],
                ],
            ]],
            'resize_keyboard' => true,
            'is_persistent' => true,
        ];
    }

    public function attachOpenAppMenu(?int $chatId = null): void
    {
        $appUrl = $this->miniAppUrl();
        $token = (string) config('telegram.bot_token');
        if ($appUrl === null || $token === '') {
            return;
        }

        $payload = [
            'menu_button' => [
                'type' => 'web_app',
                'text' => (string) config('telegram.messages.open_app_menu'),
                'web_app' => ['url' => $appUrl],
            ],
        ];
        if ($chatId !== null && $chatId !== 0) {
            $payload['chat_id'] = $chatId;
        }

        Http::timeout(10)->acceptJson()->post($this->methodUrl('setChatMenuButton'), $payload);
    }

    public function miniAppUrl(): ?string
    {
        $url = trim((string) config('telegram.mini_app_url'));
        if ($url === '' || ! str_starts_with($url, 'https://')) {
            return null;
        }

        return $url;
    }

    public function accessRequestKeyboard(): array
    {
        return [
            'inline_keyboard' => [[
                [
                    'text' => (string) config('telegram.messages.access_request_button'),
                    'callback_data' => 'access_request',
                ],
            ]],
        ];
    }

    private function methodUrl(string $method): string
    {
        $base = rtrim((string) config('telegram.api_base'), '/');
        $token = (string) config('telegram.bot_token');

        return "{$base}/bot{$token}/{$method}";
    }
}
