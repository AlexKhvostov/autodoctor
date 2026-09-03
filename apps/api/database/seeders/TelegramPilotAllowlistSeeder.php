<?php

namespace Database\Seeders;

use App\Models\TelegramBotUser;
use Illuminate\Database\Seeder;

class TelegramPilotAllowlistSeeder extends Seeder
{
    public function run(): void
    {
        $user = TelegramBotUser::query()->firstOrNew([
            'telegram_user_id' => 287536885,
        ]);
        $user->username = 'LihachOK';
        $user->note = 'Владелец продукта, пилот @AutoDoctorPilotBot';
        $user->save();
        $user->setAllowlisted(true);
    }
}
