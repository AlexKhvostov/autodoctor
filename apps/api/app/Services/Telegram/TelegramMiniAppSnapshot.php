<?php

namespace App\Services\Telegram;

use App\Models\GuestProfile;
use App\Models\ServiceRecord;
use App\Models\TelegramBotUser;
use App\Models\Vehicle;

class TelegramMiniAppSnapshot
{
    /**
     * @var list<array{key: string, label: string}>
     */
    private const VEHICLE_FIELDS = [
        ['key' => 'make', 'label' => 'Марка'],
        ['key' => 'model', 'label' => 'Модель'],
        ['key' => 'year', 'label' => 'Год выпуска'],
        ['key' => 'fuel', 'label' => 'Топливо'],
        ['key' => 'mileage', 'label' => 'Пробег'],
        ['key' => 'vin', 'label' => 'VIN'],
    ];

    /**
     * @return array<string, mixed>
     */
    public function emptyVehicleCard(): array
    {
        return [
            'status' => 'empty',
            'status_label' => 'Не записано',
            'fields' => $this->formatFields([]),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function emptyWorksJournal(string $hint): array
    {
        return [
            'items' => [],
            'empty_hint' => $hint,
        ];
    }

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
                'subtitle' => 'Журнал авто в Telegram. Расскажите боту про машину — здесь появится карточка.',
                'vehicle_card' => $this->emptyVehicleCard(),
                'works_journal' => $this->emptyWorksJournal('Сначала запишите машину в чате с ботом.'),
            ];
        }

        $vehicle = $profile->vehicles()->with('configuration')->orderByDesc('created_at')->first();
        $draft = $this->pendingVehicleDraft($telegramUserId);

        if ($vehicle !== null) {
            return [
                'allowed' => true,
                'greeting' => $profile->adminLabel(),
                'subtitle' => 'Что уже собрали в чате. Пустые поля можно дописать боту.',
                'vehicle_card' => $this->vehicleCardFromSaved($vehicle),
                'works_journal' => $this->worksJournal($vehicle),
            ];
        }

        if ($draft !== null) {
            return [
                'allowed' => true,
                'greeting' => $profile->adminLabel(),
                'subtitle' => 'Черновик из чата. Нажмите «Записать» в боте, когда всё верно.',
                'vehicle_card' => $this->vehicleCardFromDraft($draft),
                'works_journal' => $this->emptyWorksJournal('Журнал откроется после записи машины.'),
            ];
        }

        return [
            'allowed' => true,
            'greeting' => $profile->adminLabel(),
            'subtitle' => 'Расскажите боту про машину — ниже видно, какие данные мы собираем.',
            'vehicle_card' => $this->emptyVehicleCard(),
            'works_journal' => $this->emptyWorksJournal('Сначала запишите машину в чате с ботом.'),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function vehicleCardFromSaved(Vehicle $vehicle): array
    {
        $configuration = $vehicle->configuration;
        $vin = $vehicle->vin_ciphertext;

        return [
            'status' => 'saved',
            'status_label' => 'Записано',
            'fields' => $this->formatFields([
                'make' => $this->textValue($configuration?->make),
                'model' => $this->textValue($configuration?->model),
                'year' => $vehicle->production_year !== null ? (string) $vehicle->production_year : null,
                'fuel' => $this->fuelLabel($configuration?->fuel_type),
                'mileage' => $this->formatMileage($vehicle->current_mileage, $vehicle->mileage_unit),
                'vin' => is_string($vin) && $vin !== '' ? strtoupper($vin) : null,
            ]),
        ];
    }

    /**
     * @param  array<string, mixed>  $draft
     * @return array<string, mixed>
     */
    private function vehicleCardFromDraft(array $draft): array
    {
        $vin = strtoupper(trim((string) ($draft['vin'] ?? '')));
        if ($vin !== '' && preg_match('/^[A-HJ-NPR-Z0-9]{17}$/', $vin) !== 1) {
            $vin = '';
        }

        return [
            'status' => 'draft',
            'status_label' => 'Черновик',
            'fields' => $this->formatFields([
                'make' => $this->textValue($draft['make'] ?? null),
                'model' => $this->textValue($draft['model'] ?? null),
                'year' => is_numeric($draft['production_year'] ?? null)
                    ? (string) (int) $draft['production_year']
                    : null,
                'fuel' => $this->fuelLabel(is_string($draft['fuel_type'] ?? null) ? $draft['fuel_type'] : null),
                'mileage' => is_numeric($draft['mileage_km'] ?? null)
                    ? $this->formatMileage((int) $draft['mileage_km'], 'km')
                    : null,
                'vin' => $vin !== '' ? $vin : null,
            ]),
        ];
    }

    /**
     * @param  array<string, string|null>  $values
     * @return list<array{key: string, label: string, value: ?string, filled: bool}>
     */
    private function formatFields(array $values): array
    {
        $fields = [];
        foreach (self::VEHICLE_FIELDS as $field) {
            $value = $values[$field['key']] ?? null;
            $filled = filled($value);
            $fields[] = [
                'key' => $field['key'],
                'label' => $field['label'],
                'value' => $filled ? (string) $value : null,
                'filled' => $filled,
            ];
        }

        return $fields;
    }

    /**
     * @return array<string, mixed>
     */
    private function worksJournal(Vehicle $vehicle): array
    {
        $records = ServiceRecord::query()
            ->with('items.workCatalogItem')
            ->where('vehicle_id', $vehicle->id)
            ->orderByDesc('service_date')
            ->orderByDesc('created_at')
            ->limit(8)
            ->get();

        if ($records->isEmpty()) {
            return $this->emptyWorksJournal('Пока нет записанных работ. Расскажите боту, что делали с машиной.');
        }

        return [
            'items' => $records->map(function (ServiceRecord $record): array {
                $titles = $record->items
                    ->map(fn ($item): string => (string) ($item->workCatalogItem->localized_name['ru'] ?? $item->workCatalogItem->code))
                    ->filter()
                    ->values()
                    ->all();
                $title = $titles !== [] ? implode(', ', $titles) : 'Работа';
                $parts = [$record->service_date?->format('d.m.Y'), $title];
                if (is_numeric($record->mileage_value)) {
                    $parts[] = number_format((int) $record->mileage_value, 0, '', ' ').' км';
                }
                $note = trim((string) ($record->note ?? ''));
                if ($note !== '' && $note !== $title) {
                    $parts[] = $note;
                }

                return [
                    'date' => $record->service_date?->format('d.m.Y'),
                    'title' => $title,
                    'detail' => implode(' · ', array_filter($parts)),
                ];
            })->all(),
            'empty_hint' => null,
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    private function pendingVehicleDraft(int $telegramUserId): ?array
    {
        $draft = TelegramBotUser::query()
            ->where('telegram_user_id', $telegramUserId)
            ->value('pending_vehicle_draft');

        return is_array($draft) ? $draft : null;
    }

    private function textValue(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text !== '' ? $text : null;
    }

    private function formatMileage(?int $value, ?string $unit): ?string
    {
        if ($value === null) {
            return null;
        }

        $suffix = ($unit ?? 'km') === 'mi' ? ' mi' : ' км';

        return number_format($value, 0, '', ' ').$suffix;
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
