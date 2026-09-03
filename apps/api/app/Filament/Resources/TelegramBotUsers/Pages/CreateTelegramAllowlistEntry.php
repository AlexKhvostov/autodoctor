<?php

namespace App\Filament\Resources\TelegramBotUsers\Pages;

use App\Filament\Resources\TelegramBotUsers\TelegramAllowlistResource;
use App\Models\TelegramBotUser;
use Filament\Resources\Pages\CreateRecord;

class CreateTelegramAllowlistEntry extends CreateRecord
{
    protected static string $resource = TelegramAllowlistResource::class;

    protected function handleRecordCreation(array $data): TelegramBotUser
    {
        $user = TelegramBotUser::query()->firstOrNew([
            'telegram_user_id' => $data['telegram_user_id'],
        ]);
        if (filled($data['username'] ?? null)) {
            $user->username = $data['username'];
        }
        if (array_key_exists('note', $data)) {
            $user->note = $data['note'];
        }
        $user->save();
        $user->setAllowlisted(true);

        return $user;
    }
}
