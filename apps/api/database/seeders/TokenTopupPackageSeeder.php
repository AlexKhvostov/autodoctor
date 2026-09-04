<?php

namespace Database\Seeders;

use App\Models\TokenTopupPackage;
use Illuminate\Database\Seeder;

class TokenTopupPackageSeeder extends Seeder
{
    public function run(): void
    {
        $packages = [
            [
                'key' => 'stars_pack_s',
                'type' => TokenTopupPackage::TYPE_STARS,
                'title' => 'Пакет Starter',
                'subtitle' => 'Небольшой запас на короткие ответы в чате',
                'icon' => '⭐',
                'tokens_amount' => 5000,
                'stars_price' => 50,
                'cooldown_hours' => null,
                'badge' => 'скоро',
                'enabled' => true,
                'sort_order' => 10,
            ],
            [
                'key' => 'stars_pack_m',
                'type' => TokenTopupPackage::TYPE_STARS,
                'title' => 'Пакет Drive',
                'subtitle' => 'Оптимально на неделю активного диалога',
                'icon' => '⭐',
                'tokens_amount' => 20000,
                'stars_price' => 150,
                'cooldown_hours' => null,
                'badge' => 'скоро',
                'enabled' => true,
                'sort_order' => 20,
            ],
            [
                'key' => 'stars_pack_l',
                'type' => TokenTopupPackage::TYPE_STARS,
                'title' => 'Пакет Garage',
                'subtitle' => 'Запас на долгие разборы и несколько авто',
                'icon' => '⭐',
                'tokens_amount' => 60000,
                'stars_price' => 350,
                'cooldown_hours' => null,
                'badge' => 'скоро',
                'enabled' => true,
                'sort_order' => 30,
            ],
            [
                'key' => 'mileage',
                'type' => TokenTopupPackage::TYPE_MILEAGE,
                'title' => 'Обновить пробег',
                'subtitle' => 'Небольшой бонус за актуальный одометр, не чаще раза в сутки',
                'icon' => '🛣️',
                'tokens_amount' => 500,
                'stars_price' => 0,
                'cooldown_hours' => 24,
                'badge' => null,
                'enabled' => true,
                'sort_order' => 40,
            ],
            [
                'key' => 'invite',
                'type' => TokenTopupPackage::TYPE_INVITE,
                'title' => 'Пригласить друга',
                'subtitle' => 'Вы и друг получаете бонус после первого диалога друга с ботом',
                'icon' => '👥',
                'tokens_amount' => null,
                'stars_price' => 0,
                'cooldown_hours' => null,
                'badge' => 'скоро',
                'enabled' => true,
                'sort_order' => 50,
            ],
        ];

        foreach ($packages as $package) {
            TokenTopupPackage::query()->updateOrCreate(
                ['key' => $package['key']],
                $package,
            );
        }
    }
}
