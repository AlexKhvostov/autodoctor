<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class SetTelegramWebhookCommand extends Command
{
    protected $signature = 'telegram:set-webhook';

    protected $description = 'Register HTTPS webhook URL and secret with Telegram.';

    public function handle(): int
    {
        $token = (string) config('telegram.bot_token');
        $secret = (string) config('telegram.webhook_secret');
        if ($token === '' || $secret === '') {
            $this->error('Set TELEGRAM_BOT_TOKEN and TELEGRAM_WEBHOOK_SECRET first.');

            return self::FAILURE;
        }

        $url = rtrim((string) config('app.url'), '/').'/telegram/webhook';
        $base = rtrim((string) config('telegram.api_base'), '/');
        $response = Http::timeout(15)->acceptJson()->post("{$base}/bot{$token}/setWebhook", [
            'url' => $url,
            'secret_token' => $secret,
            'allowed_updates' => ['message', 'callback_query'],
            'drop_pending_updates' => false,
        ]);

        if ($response->failed() || ! ($response->json('ok') ?? false)) {
            $this->error('Telegram rejected setWebhook: '.$response->body());

            return self::FAILURE;
        }

        $this->info('Webhook: '.$url);

        return self::SUCCESS;
    }
}
