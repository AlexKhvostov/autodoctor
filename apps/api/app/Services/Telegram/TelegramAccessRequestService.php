<?php

namespace App\Services\Telegram;

use App\Models\TelegramBotUser;
use Illuminate\Support\Carbon;

class TelegramAccessRequestService
{
    public function __construct(private readonly TelegramBotClient $bot) {}

    public function handle(TelegramInboundUpdate $update, TelegramBotUser $user): void
    {
        if ($update->callbackQueryId) {
            $this->bot->answerCallbackQuery($update->callbackQueryId);
        }

        $ownerId = (int) config('telegram.owner_chat_id');
        if ($ownerId <= 0) {
            $this->bot->sendMessage(
                $update->chatId,
                (string) config('telegram.messages.access_request_owner_unavailable'),
            );

            return;
        }

        $cooldown = max(1, (int) config('telegram.access_request_cooldown_minutes', 60));
        if ($user->access_requested_at !== null
            && $user->access_requested_at->gt(Carbon::now()->subMinutes($cooldown))
        ) {
            $this->bot->sendMessage(
                $update->chatId,
                (string) config('telegram.messages.access_request_already'),
            );

            return;
        }

        $this->bot->sendMessage($ownerId, $this->ownerText($user, $update));
        $user->forceFill(['access_requested_at' => Carbon::now()])->save();
        $this->bot->sendMessage(
            $update->chatId,
            (string) config('telegram.messages.access_request_sent'),
        );
    }

    private function ownerText(TelegramBotUser $user, TelegramInboundUpdate $update): string
    {
        $nick = filled($update->username) ? '@'.$update->username : (filled($user->username) ? '@'.$user->username : 'нет');
        $name = trim(implode(' ', array_filter([$update->firstName ?? $user->first_name, $update->lastName ?? $user->last_name])));
        if ($name === '') {
            $name = 'не указано';
        }
        $link = filled($update->username)
            ? 'https://t.me/'.$update->username
            : 'tg://user?id='.$update->telegramUserId;

        return implode("\n", [
            'Запрос доступа в AutoDoctor',
            '',
            'Имя: '.$name,
            'Ник: '.$nick,
            'Telegram ID: '.$update->telegramUserId,
            'Написать: '.$link,
            '',
            'В админке: Telegram → Писали боту — включите белый список.',
        ]);
    }
}
