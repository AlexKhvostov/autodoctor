<?php

namespace App\Services\Telegram;

use App\Models\GuestProfile;
use App\Models\ServiceRecord;
use App\Models\Vehicle;

class TelegramMiniAppSnapshot
{
    /**
     * @return array<string, mixed>
     */
    public function forTelegramUser(int $telegramUserId): array
    {
        $profile = GuestProfile::query()
            ->where('telegram_id', $telegramUserId)
            ->first();

        if ($profile === null) {
            return [
                'allowed' => app(TelegramAllowlist::class)->allows($telegramUserId),
                'greeting' => 'AutoDoctor',
                'subtitle' => 'Журнал авто в Telegram. Пока это заставка — учёт ведём в чате с ботом.',
                'vehicle' => null,
                'works' => [],
            ];
        }

        $vehicle = $profile->vehicles()->with('configuration')->orderByDesc('created_at')->first();

        return [
            'allowed' => true,
            'greeting' => $profile->adminLabel(),
            'subtitle' => $vehicle === null
                ? 'Машину ещё не записали. Напишите боту марку, год и пробег, затем нажмите «Записать».'
                : 'То, что уже собрали. Позже здесь появится полный гараж.',
            'vehicle' => $vehicle === null ? null : $this->vehicleCard($vehicle),
            'works' => $vehicle === null ? [] : $this->recentWorks($vehicle),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function vehicleCard(Vehicle $vehicle): array
    {
        $configuration = $vehicle->configuration;
        $title = trim(($configuration?->make ?? '').' '.($configuration?->model ?? ''));

        return [
            'title' => $title !== '' ? $title : 'Авто',
            'year' => $vehicle->production_year,
            'mileage' => $vehicle->current_mileage,
            'fuel' => $this->fuelLabel($configuration?->fuel_type),
        ];
    }

    /**
     * @return list<array{date: ?string, note: string}>
     */
    private function recentWorks(Vehicle $vehicle): array
    {
        return ServiceRecord::query()
            ->where('vehicle_id', $vehicle->id)
            ->orderByDesc('service_date')
            ->limit(5)
            ->get()
            ->map(fn (ServiceRecord $record): array => [
                'date' => $record->service_date?->format('d.m.Y'),
                'note' => filled($record->note) ? (string) $record->note : 'Работа',
            ])
            ->all();
    }

    private function fuelLabel(?string $fuel): ?string
    {
        return match ($fuel) {
            'petrol' => 'бензин',
            'diesel' => 'дизель',
            'hybrid' => 'гибрид',
            'electric' => 'электро',
            'lpg' => 'газ',
            'other' => 'другое',
            default => null,
        };
    }
}
