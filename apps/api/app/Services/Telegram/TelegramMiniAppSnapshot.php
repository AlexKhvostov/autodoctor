<?php

namespace App\Services\Telegram;

use App\Models\GuestProfile;
use App\Models\HistoryAnswer;
use App\Models\ServiceRecord;
use App\Models\TelegramBotUser;
use App\Models\Vehicle;
use App\Models\WorkCatalogItem;
use App\Services\PlanCalculator;
use Illuminate\Support\Collection;

class TelegramMiniAppSnapshot
{
    public function __construct(
        private readonly PlanCalculator $plans,
    ) {}

    /**
     * @var list<array{key: string, label: string}>
     */
    private const PROFILE_FIELDS = [
        ['key' => 'make', 'label' => 'Марка'],
        ['key' => 'model', 'label' => 'Модель'],
        ['key' => 'generation', 'label' => 'Поколение'],
        ['key' => 'year', 'label' => 'Год выпуска'],
        ['key' => 'first_use_date', 'label' => 'Начало эксплуатации'],
        ['key' => 'fuel', 'label' => 'Топливо'],
        ['key' => 'engine_displacement', 'label' => 'Объём двигателя'],
        ['key' => 'engine_code', 'label' => 'Код двигателя'],
        ['key' => 'engine_power', 'label' => 'Мощность'],
        ['key' => 'transmission', 'label' => 'Коробка передач'],
        ['key' => 'drivetrain', 'label' => 'Привод'],
        ['key' => 'market', 'label' => 'Рынок'],
        ['key' => 'mileage', 'label' => 'Пробег'],
        ['key' => 'vin', 'label' => 'VIN'],
    ];

    /**
     * @return array<string, mixed>
     */
    public function forTelegramUser(int $telegramUserId): array
    {
        $profile = GuestProfile::query()
            ->where('telegram_id', $telegramUserId)
            ->first();

        if ($profile === null) {
            return $this->response(
                'Расскажите боту про машину — здесь появится карточка.',
                $this->vehiclesForGuest(null, $telegramUserId),
            );
        }

        return $this->response(
            'Нажмите на автомобиль, чтобы раскрыть все поля. Пустое — допишите боту.',
            $this->vehiclesForGuest($profile, $telegramUserId),
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function deniedResponse(): array
    {
        return $this->response(
            'Сейчас закрытый пилот. Напишите боту и нажмите «Запросить доступ».',
            [$this->placeholderCard()],
        );
    }

    /**
     * @param  list<array<string, mixed>>  $vehicles
     * @return array<string, mixed>
     */
    private function response(string $subtitle, array $vehicles): array
    {
        return [
            'title' => 'AutoDoctor',
            'subtitle' => $subtitle,
            'vehicles' => $vehicles,
        ];
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function vehiclesForGuest(?GuestProfile $profile, int $telegramUserId): array
    {
        $vehicles = [];

        if ($profile !== null) {
            $saved = $profile->vehicles()
                ->with([
                    'configuration',
                    'historyAnswers.workCatalogItem',
                    'serviceRecords.items.workCatalogItem',
                ])
                ->orderByDesc('created_at')
                ->get();

            foreach ($saved as $vehicle) {
                $vehicles[] = $this->cardFromVehicle($vehicle);
            }
        }

        $draft = $this->pendingVehicleDraft($telegramUserId);
        if ($draft !== null && ! $this->draftAlreadySaved($draft, $vehicles)) {
            array_unshift($vehicles, $this->cardFromDraft($draft));
        }

        if ($vehicles === []) {
            return [$this->placeholderCard()];
        }

        return $vehicles;
    }

    /**
     * @return array<string, mixed>
     */
    private function placeholderCard(): array
    {
        return [
            'id' => null,
            'title' => 'Автомобиль',
            'summary' => null,
            'status' => 'placeholder',
            'sections' => $this->buildSections([], null),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function cardFromVehicle(Vehicle $vehicle): array
    {
        $configuration = $vehicle->configuration;
        $vin = $vehicle->vin_ciphertext;
        $values = [
            'make' => $this->textValue($configuration?->make),
            'model' => $this->textValue($configuration?->model),
            'generation' => $this->textValue($configuration?->generation),
            'year' => $vehicle->production_year !== null ? (string) $vehicle->production_year : null,
            'first_use_date' => $vehicle->first_use_date?->format('d.m.Y'),
            'fuel' => $this->fuelLabel($configuration?->fuel_type),
            'engine_displacement' => is_numeric($configuration?->engine_displacement_cc)
                ? (int) $configuration->engine_displacement_cc.' см³'
                : null,
            'engine_code' => $this->textValue($configuration?->engine_code),
            'engine_power' => is_numeric($configuration?->engine_power_kw)
                ? (string) $configuration->engine_power_kw.' кВт'
                : null,
            'transmission' => $this->transmissionLabel($configuration?->transmission_type, $configuration?->transmission_gears),
            'drivetrain' => $this->drivetrainLabel($configuration?->drivetrain),
            'market' => $this->textValue($configuration?->market),
            'mileage' => $this->formatMileage($vehicle->current_mileage, $vehicle->mileage_unit),
            'vin' => is_string($vin) && $vin !== '' ? strtoupper($vin) : null,
        ];

        return [
            'id' => $vehicle->id,
            'title' => $this->vehicleTitle($values),
            'summary' => $this->vehicleSummary($values),
            'status' => 'saved',
            'sections' => $this->buildSections($values, $vehicle),
        ];
    }

    /**
     * @param  array<string, mixed>  $draft
     * @return array<string, mixed>
     */
    private function cardFromDraft(array $draft): array
    {
        $vin = strtoupper(trim((string) ($draft['vin'] ?? '')));
        if ($vin !== '' && preg_match('/^[A-HJ-NPR-Z0-9]{17}$/', $vin) !== 1) {
            $vin = '';
        }

        $values = [
            'make' => $this->textValue($draft['make'] ?? null),
            'model' => $this->textValue($draft['model'] ?? null),
            'generation' => null,
            'year' => is_numeric($draft['production_year'] ?? null)
                ? (string) (int) $draft['production_year']
                : null,
            'first_use_date' => null,
            'fuel' => $this->fuelLabel(is_string($draft['fuel_type'] ?? null) ? $draft['fuel_type'] : null),
            'engine_displacement' => is_numeric($draft['displacement_cc'] ?? null)
                ? (int) $draft['displacement_cc'].' см³'
                : null,
            'engine_code' => null,
            'engine_power' => null,
            'transmission' => null,
            'drivetrain' => null,
            'market' => null,
            'mileage' => is_numeric($draft['mileage_km'] ?? null)
                ? $this->formatMileage((int) $draft['mileage_km'], 'km')
                : null,
            'vin' => $vin !== '' ? $vin : null,
        ];

        return [
            'id' => null,
            'title' => $this->vehicleTitle($values, 'Автомобиль'),
            'summary' => $this->vehicleSummary($values),
            'status' => 'draft',
            'sections' => $this->buildSections($values, null),
        ];
    }

    /**
     * @param  array<string, string|null>  $values
     * @return list<array<string, mixed>>
     */
    private function buildSections(array $values, ?Vehicle $vehicle): array
    {
        return [
            [
                'key' => 'profile',
                'title' => 'Данные автомобиля',
                'fields' => $this->formatProfileFields($values),
            ],
            [
                'key' => 'maintenance',
                'title' => 'История обслуживания',
                'fields' => $this->maintenanceFields($vehicle),
            ],
        ];
    }

    /**
     * @param  array<string, string|null>  $values
     * @return list<array{key: string, label: string, value: ?string, filled: bool}>
     */
    private function formatProfileFields(array $values): array
    {
        $fields = [];
        foreach (self::PROFILE_FIELDS as $field) {
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
     * @return list<array{key: string, label: string, value: ?string, filled: bool}>
     */
    private function maintenanceFields(?Vehicle $vehicle): array
    {
        $catalog = WorkCatalogItem::query()->orderBy('code')->get();
        if ($catalog->isEmpty()) {
            return [];
        }

        $applicable = $vehicle !== null
            ? $this->plans->applicableWorkCodes($vehicle)->all()
            : $catalog->pluck('code')->all();

        $answers = $vehicle !== null
            ? $vehicle->historyAnswers->keyBy(fn (HistoryAnswer $answer) => $answer->workCatalogItem?->code)
            : collect();
        $latestServices = $vehicle !== null
            ? $this->latestServicesByWorkCode($vehicle)
            : collect();

        $fields = [];
        foreach ($catalog as $item) {
            if (! in_array($item->code, $applicable, true)) {
                continue;
            }

            $label = (string) ($item->localized_name['ru'] ?? $item->code);
            $value = $this->maintenanceValue(
                $answers->get($item->code),
                $latestServices->get($item->code),
            );
            $fields[] = [
                'key' => $item->code,
                'label' => $label,
                'value' => $value,
                'filled' => filled($value),
            ];
        }

        return $fields;
    }

    private function maintenanceValue(?HistoryAnswer $answer, ?ServiceRecord $latestService): ?string
    {
        if ($answer !== null) {
            $formatted = $this->formatMaintenanceFacts(
                $answer->performed_date?->format('d.m.Y'),
                $answer->performed_mileage_km,
            );
            if ($formatted !== null) {
                return $formatted;
            }

            return match ((string) $answer->answer) {
                'done_unknown' => 'делали, дата неизвестна',
                'not_done' => 'не делали',
                'not_applicable' => 'не применимо',
                'unknown' => 'не знаем',
                default => null,
            };
        }

        if ($latestService !== null) {
            return $this->formatMaintenanceFacts(
                $latestService->service_date?->format('d.m.Y'),
                is_numeric($latestService->mileage_value) ? (int) $latestService->mileage_value : null,
            );
        }

        return null;
    }

    private function formatMaintenanceFacts(?string $date, ?int $mileageKm): ?string
    {
        $parts = array_filter([
            $date,
            $mileageKm !== null ? number_format($mileageKm, 0, '', ' ').' км' : null,
        ]);

        return $parts === [] ? null : implode(' · ', $parts);
    }

    /**
     * @return Collection<string, ServiceRecord>
     */
    private function latestServicesByWorkCode(Vehicle $vehicle): Collection
    {
        $latest = [];
        foreach ($vehicle->serviceRecords as $record) {
            foreach ($record->items as $item) {
                $code = $item->workCatalogItem?->code;
                if ($code === null) {
                    continue;
                }
                if (! isset($latest[$code])) {
                    $latest[$code] = $record;

                    continue;
                }
                $current = $latest[$code];
                $recordKey = ($record->service_date?->format('Y-m-d') ?? '').$record->id;
                $currentKey = ($current->service_date?->format('Y-m-d') ?? '').$current->id;
                if ($recordKey > $currentKey) {
                    $latest[$code] = $record;
                }
            }
        }

        return collect($latest);
    }

    /**
     * @param  array<string, string|null>  $values
     */
    private function vehicleTitle(array $values, string $fallback = 'Автомобиль'): string
    {
        $title = trim(($values['make'] ?? '').' '.($values['model'] ?? ''));

        return $title !== '' ? $title : $fallback;
    }

    /**
     * @param  array<string, string|null>  $values
     */
    private function vehicleSummary(array $values): ?string
    {
        $parts = array_filter([
            $values['year'] ?? null,
            $values['fuel'] ?? null,
            $values['mileage'] ?? null,
        ]);

        return $parts === [] ? null : implode(' · ', $parts);
    }

    /**
     * @param  list<array<string, mixed>>  $vehicles
     * @param  array<string, mixed>  $draft
     */
    private function draftAlreadySaved(array $draft, array $vehicles): bool
    {
        $draftMake = $this->textValue($draft['make'] ?? null);
        $draftModel = $this->textValue($draft['model'] ?? null);
        $draftYear = is_numeric($draft['production_year'] ?? null) ? (string) (int) $draft['production_year'] : null;

        foreach ($vehicles as $vehicle) {
            if (($vehicle['status'] ?? '') !== 'saved') {
                continue;
            }
            $fields = collect($vehicle['sections'][0]['fields'] ?? [])->keyBy('key');
            $sameMake = ($fields->get('make')['value'] ?? null) === $draftMake;
            $sameModel = ($fields->get('model')['value'] ?? null) === $draftModel;
            $sameYear = ($fields->get('year')['value'] ?? null) === $draftYear;
            if ($draftMake !== null && $draftModel !== null && $sameMake && $sameModel && $sameYear) {
                return true;
            }
        }

        return false;
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

    private function transmissionLabel(?string $type, ?int $gears): ?string
    {
        $label = match ($type) {
            'manual' => 'механика',
            'automatic' => 'автомат',
            default => null,
        };
        if ($label === null) {
            return null;
        }
        if ($gears !== null) {
            return $label.', '.$gears.' ст.';
        }

        return $label;
    }

    private function drivetrainLabel(?string $value): ?string
    {
        return match ($value) {
            'fwd' => 'передний',
            'rwd' => 'задний',
            'awd' => 'полный',
            'four_wd' => '4×4',
            'other' => 'другое',
            default => null,
        };
    }
}
