<?php

namespace App\Services\Telegram;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class TelegramBotClient
{
    public function sendMessage(int $chatId, string $text): void
    {
        $token = (string) config('telegram.bot_token');
        if ($token === '' || $chatId === 0) {
            Log::warning('telegram.send_skipped', [
                'reason' => $token === '' ? 'missing_bot_token' : 'empty_chat',
                'chat_id' => $chatId,
            ]);

            return;
        }

        $base = rtrim((string) config('telegram.api_base'), '/');
        $url = "{$base}/bot{$token}/sendMessage";

        $response = Http::timeout(10)->acceptJson()->post($url, [
            'chat_id' => $chatId,
            'text' => $text,
        ]);

        if ($response->failed()) {
            Log::error('telegram.send_failed', [
                'chat_id' => $chatId,
                'status' => $response->status(),
                'body' => mb_substr($response->body(), 0, 500),
            ]);
        }
    }
}
