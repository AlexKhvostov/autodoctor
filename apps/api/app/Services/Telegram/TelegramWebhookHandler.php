<?php

namespace App\Services\Telegram;

use App\Models\GuestProfile;
use App\Models\TelegramBotUser;
use Illuminate\Support\Facades\Log;

class TelegramWebhookHandler
{
    public function __construct(
        private readonly TelegramAllowlist $allowlist,
        private readonly TelegramBotClient $bot,
    ) {}

    public function handle(array $payload): void
    {
        $update = TelegramInboundUpdate::fromPayload($payload);
        if ($update === null || $update->isBot || ! $update->isPrivateChat()) {
            return;
        }

        $this->rememberBotUser($update);

        if (! $this->allowlist->allows($update->telegramUserId)) {
            Log::info('telegram.allowlist.denied', [
                'telegram_user_id' => $update->telegramUserId,
                'username' => $update->username,
            ]);
            $this->bot->sendMessage(
                $update->chatId,
                (string) config('telegram.messages.closed_pilot'),
            );

            return;
        }

        $this->rememberProfile($update);

        $text = $update->isStart
            ? (string) config('telegram.messages.start')
            : (string) config('telegram.messages.continue');

        $this->bot->sendMessage($update->chatId, $text);
    }

    private function rememberBotUser(TelegramInboundUpdate $update): void
    {
        $user = TelegramBotUser::query()->firstOrNew([
            'telegram_user_id' => $update->telegramUserId,
        ]);
        $user->username = $update->username ?: $user->username;
        $user->first_name = $update->firstName ?: $user->first_name;
        $user->last_name = $update->lastName ?: $user->last_name;
        $user->last_message_at = now();
        $user->message_count = (int) $user->message_count + 1;
        $user->save();
    }

    private function rememberProfile(TelegramInboundUpdate $update): void
    {
        $profile = GuestProfile::query()->firstOrNew([
            'telegram_id' => $update->telegramUserId,
        ]);
        $profile->telegram_username = $update->username;
        $profile->telegram_first_name = $update->firstName;
        $profile->save();
    }
}
