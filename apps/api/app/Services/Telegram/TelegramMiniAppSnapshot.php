<?php

namespace App\Services\Telegram;

use App\Models\GuestProfile;
use App\Models\HistoryAnswer;
use App\Models\MaintenanceRule;
use App\Models\MileageObservation;
use App\Models\PlanItem;
use App\Models\ServiceRecord;
use App\Models\TelegramBotUser;
use App\Models\Vehicle;
use App\Models\WorkCatalogItem;
use App\Services\AgentProfileService;
use App\Services\GuestSkillProfileService;
use App\Services\PlanCalculator;
use Illuminate\Support\Collection;
use Throwable;

class TelegramMiniAppSnapshot
{
    public function __construct(
        private readonly PlanCalculator $plans,
        private readonly AgentProfileService $agentProfile,
        private readonly GuestSkillProfileService $skills,
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
                'Расскажите боту про машину — данные появятся здесь.',
                $this->vehiclesForGuest(null, $telegramUserId),
                null,
            );
        }

        return $this->response(
            'Выберите авто в шапке. Ниже — состояние, план и настройки AI.',
            $this->vehiclesForGuest($profile, $telegramUserId),
            $profile,
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
            null,
        );
    }

    /**
     * @param  list<array<string, mixed>>  $vehicles
     * @return array<string, mixed>
     */
    private function response(string $subtitle, array $vehicles, ?GuestProfile $profile): array
    {
        $activeVehicleId = null;
        foreach ($vehicles as $vehicle) {
            if (($vehicle['status'] ?? '') === 'saved' && filled($vehicle['id'] ?? null)) {
                $activeVehicleId = (string) $vehicle['id'];
                break;
            }
        }
        if ($activeVehicleId === null && $vehicles !== []) {
            $first = $vehicles[0];
            if (filled($first['id'] ?? null)) {
                $activeVehicleId = (string) $first['id'];
            } elseif (($first['status'] ?? '') === 'draft') {
                $activeVehicleId = 'draft';
            } else {
                $activeVehicleId = 'placeholder';
            }
        }

        return [
            'title' => 'AutoDoctor',
            'subtitle' => $subtitle,
            'active_vehicle_id' => $activeVehicleId,
            'user' => $this->userHeader($profile),
            'agent' => $this->agentTab($profile),
            'garage' => $this->garageMeta($vehicles),
            'vehicles' => $vehicles,
        ];
    }

    /**
     * @param  list<array<string, mixed>>  $vehicles
     * @return array<string, mixed>
     */
    private function garageMeta(array $vehicles): array
    {
        $savedCount = count(array_filter(
            $vehicles,
            fn (array $vehicle): bool => ($vehicle['status'] ?? '') === 'saved',
        ));

        return [
            'can_add' => $savedCount === 0,
            'add_hint' => 'Расскажите боту про машину — она появится в гараже.',
            'locked_hint' => 'В пилоте доступен один автомобиль. Второй слот появится позже.',
            'active_label' => 'Активна для AI и аналитики',
            'select_label' => 'Выбрать для AI',
            'detail_label' => 'Подробнее',
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function userHeader(?GuestProfile $profile): array
    {
        if ($profile === null) {
            return ['initial' => 'AD', 'display_name' => null];
        }

        $name = $profile->telegram_first_name ?: $profile->adminLabel();
        $initial = mb_strtoupper(mb_substr(trim($name, '@'), 0, 1));

        return [
            'initial' => $initial !== '' ? $initial : 'AD',
            'display_name' => $name,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function agentTab(?GuestProfile $profile): array
    {
        if ($profile === null) {
            return [
                'tokens_balance' => null,
                'tokens_label' => '—',
                'status' => 'unknown',
                'settings' => [],
                'hint' => 'Напишите боту /start — здесь появятся токены и настройки собеседника.',
            ];
        }

        $wallet = $this->agentProfile->wallet($profile);
        $balance = (int) $wallet->balance_ml;
        $prefs = $this->agentProfile->preferences($profile);
        $skill = $this->skills->toArray($this->skills->forProfile($profile));

        return [
            'tokens_balance' => $balance,
            'tokens_label' => number_format($balance, 0, '', ' '),
            'status' => $balance <= 0 ? 'empty' : ($balance <= (int) config('agent.fuel.low_balance_ml', 400) ? 'low' : 'ok'),
            'settings' => [
                [
                    'key' => 'knowledge',
                    'label' => 'Понимание авто',
                    'value' => $this->knowledgeLabel($skill['self_reported_band'] ?? $skill['band']),
                ],
                [
                    'key' => 'hands_on',
                    'label' => 'Готовность к проверкам',
                    'value' => $this->handsOnLabel($skill['hands_on_level'] ?? null, $skill['hands_on']),
                ],
                [
                    'key' => 'simplicity',
                    'label' => 'Простота ответов',
                    'value' => $this->scaleLabel((int) $prefs->simplicity),
                ],
                [
                    'key' => 'initiative',
                    'label' => 'Инициатива советов',
                    'value' => $this->scaleLabel((int) $prefs->initiative),
                ],
                [
                    'key' => 'instructions',
                    'label' => 'Ваши пожелания',
                    'value' => filled($prefs->custom_instructions) ? (string) $prefs->custom_instructions : null,
                ],
            ],
            'hint' => 'Собеседник в чате учитывает эти настройки. Пока правки — через бота; скоро можно будет менять здесь.',
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
            'tabs' => [
                'state' => $this->stateTab(null),
                'roadmap' => $this->roadmapTab(null),
                'analytics' => $this->analyticsTab(null),
            ],
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
            'tabs' => [
                'state' => $this->stateTab($vehicle),
                'roadmap' => $this->roadmapTab($vehicle),
                'analytics' => $this->analyticsTab($vehicle),
            ],
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
            'tabs' => [
                'state' => $this->stateTab(null),
                'roadmap' => $this->roadmapTab(null),
                'analytics' => $this->analyticsTab(null),
            ],
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

    /**
     * @return list<array<string, mixed>>
     */
    private function stateTab(?Vehicle $vehicle): array
    {
        if ($vehicle === null) {
            return array_map(fn (array $field): array => [
                'key' => $field['key'],
                'label' => $field['label'],
                'last_service' => $field['filled'] ? $field['value'] : null,
                'next_due' => null,
                'filled' => $field['filled'],
                'status' => $field['filled'] ? 'ok' : 'unknown',
                'wear_percent' => null,
                'remaining_percent' => null,
                'used_percent' => null,
                'metric_label' => $field['filled'] ? 'последнее обслуживание' : 'нет данных',
            ], $this->maintenanceFields(null));
        }

        try {
            $snapshot = $this->plans->calculate($vehicle->loadMissing('configuration'));
            $snapshot->load(['items.rule']);
        } catch (Throwable) {
            return [];
        }

        $items = [];
        foreach ($snapshot->items->sortBy(fn (PlanItem $item) => $item->rule?->work_code ?? '') as $item) {
            $rule = $item->rule;
            if ($rule === null) {
                continue;
            }
            $title = (string) ($rule->localized_content['title']['ru'] ?? $rule->work_code);
            $history = is_array($item->explanation['history_state'] ?? null)
                ? $item->explanation['history_state']
                : [];
            $lastService = $this->formatMaintenanceFacts(
                filled($history['performed_date'] ?? null)
                    ? date('d.m.Y', strtotime((string) $history['performed_date']))
                    : null,
                is_numeric($history['performed_mileage_km'] ?? null)
                    ? (int) $history['performed_mileage_km']
                    : null,
            );
            $observation = is_array($item->explanation['latest_observation'] ?? null)
                ? $item->explanation['latest_observation']
                : null;
            $wear = is_numeric($observation['wear_percent'] ?? null) ? (int) $observation['wear_percent'] : null;
            $usedFraction = is_numeric($item->explanation['effective_used_fraction'] ?? null)
                ? (float) $item->explanation['effective_used_fraction']
                : null;
            $usedPercent = $usedFraction !== null ? (int) round(min(1, max(0, $usedFraction)) * 100) : null;

            $items[] = [
                'key' => $rule->work_code,
                'label' => $title,
                'last_service' => $lastService,
                'next_due' => $this->nextDueLabel($item, $vehicle),
                'filled' => filled($lastService),
                'status' => $this->visualStatus($item),
                'wear_percent' => $wear,
                'remaining_percent' => $wear !== null ? max(0, 100 - $wear) : null,
                'used_percent' => $wear === null ? $usedPercent : null,
                'metric_label' => $this->stateMetricLabel($item, $wear, $usedPercent),
                'criticality' => $rule->criticality,
            ];
        }

        return $items;
    }

    /**
     * @return array<string, mixed>
     */
    private function roadmapTab(?Vehicle $vehicle): array
    {
        if ($vehicle === null) {
            return [
                'required' => [],
                'recommended' => array_map(fn (array $field): array => [
                    'key' => $field['key'],
                    'label' => $field['label'],
                    'detail' => 'уточните в чате',
                    'tone' => 'unknown',
                    'tier' => 'recommended',
                    'sort_days' => null,
                    'due_label' => null,
                ], $this->maintenanceFields(null)),
                'seasonal' => $this->seasonalTips(),
                'hint' => 'Запишите машину в боте — здесь появится дорожная карта обслуживания.',
            ];
        }

        try {
            $snapshot = $this->plans->calculate($vehicle->loadMissing('configuration'));
            $snapshot->load(['items.rule']);
        } catch (Throwable) {
            return [
                'required' => [],
                'recommended' => [],
                'seasonal' => $this->seasonalTips(),
                'hint' => 'План обслуживания готовится.',
            ];
        }

        $required = [];
        $recommended = [];
        foreach ($snapshot->items as $item) {
            $rule = $item->rule;
            if ($rule === null) {
                continue;
            }
            if (! in_array($item->status, ['overdue', 'soon', 'unknown', 'current'], true)
                && ! ($item->explanation['requires_check_now'] ?? false)) {
                continue;
            }
            if ($item->status === 'current' && ! ($item->explanation['requires_check_now'] ?? false)) {
                continue;
            }

            $row = [
                'key' => $rule->work_code,
                'label' => (string) ($rule->localized_content['title']['ru'] ?? $rule->work_code),
                'detail' => $this->roadmapDetail($item, $vehicle),
                'tone' => $this->roadmapTone($item),
                'tier' => $this->roadmapTier($rule, $item),
                'sort_days' => $this->roadmapSortDays($item, $vehicle),
                'due_label' => $this->roadmapDueLabel($item, $vehicle),
            ];

            if ($row['tier'] === 'required') {
                $required[] = $row;
            } else {
                $recommended[] = $row;
            }
        }

        usort($required, fn (array $a, array $b): int => ($a['sort_days'] ?? 9999) <=> ($b['sort_days'] ?? 9999));
        usort($recommended, fn (array $a, array $b): int => ($a['sort_days'] ?? 9999) <=> ($b['sort_days'] ?? 9999));

        return [
            'required' => $required,
            'recommended' => $recommended,
            'seasonal' => $this->seasonalTips(),
            'hint' => $required === [] && $recommended === []
                ? 'Пока всё спокойно — ближайших работ нет или данных мало.'
                : null,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function analyticsTab(?Vehicle $vehicle): array
    {
        if ($vehicle === null) {
            return [
                'points' => [],
                'hint' => 'Графики появятся после записи машины и пробега в чате с ботом.',
            ];
        }

        $points = MileageObservation::query()
            ->where('vehicle_id', $vehicle->id)
            ->orderBy('observed_at')
            ->limit(24)
            ->get()
            ->map(fn (MileageObservation $row): array => [
                'date' => $row->observed_at?->format('d.m.Y'),
                'mileage' => $row->value,
                'unit' => $row->unit,
            ])
            ->all();

        return [
            'points' => $points,
            'hint' => $points === []
                ? 'Пока мало точек для графика. Сообщайте пробег боту — линия вырастет.'
                : null,
        ];
    }

    private function visualStatus(PlanItem $item): string
    {
        if ($item->status === 'overdue' || $item->urgency === 'immediate') {
            return 'overdue';
        }
        if ($item->status === 'soon') {
            return 'soon';
        }
        if ($item->explanation['requires_check_now'] ?? false) {
            return 'unknown';
        }

        return 'ok';
    }

    private function roadmapDetail(PlanItem $item, Vehicle $vehicle): string
    {
        return $this->nextDueLabel($item, $vehicle) ?? match (true) {
            $item->explanation['requires_check_now'] ?? false => 'уточните в чате',
            $item->status === 'overdue' => 'просрочено',
            $item->status === 'soon' => 'скоро',
            default => 'уточните в чате',
        };
    }

    private function nextDueLabel(PlanItem $item, Vehicle $vehicle): ?string
    {
        if ($item->explanation['requires_check_now'] ?? false) {
            return 'нужна проверка';
        }
        if ($item->due_mileage_km !== null && $vehicle->current_mileage !== null) {
            $left = $item->due_mileage_km - (int) round(
                ($vehicle->mileage_unit ?? 'km') === 'mi'
                    ? $vehicle->current_mileage * 1.609344
                    : $vehicle->current_mileage,
            );
            if ($left > 0) {
                return 'через '.number_format($left, 0, '', ' ').' км';
            }

            return 'пора по пробегу';
        }
        if ($item->due_date !== null) {
            return 'до '.$item->due_date->format('d.m.Y');
        }

        return null;
    }

    private function roadmapDueLabel(PlanItem $item, Vehicle $vehicle): ?string
    {
        if ($item->due_date !== null) {
            return $item->due_date->format('d.m.Y');
        }
        if ($item->due_mileage_km !== null) {
            return number_format($item->due_mileage_km, 0, '', ' ').' км';
        }

        return null;
    }

    private function roadmapSortDays(PlanItem $item, Vehicle $vehicle): ?int
    {
        if ($item->status === 'overdue' || $item->urgency === 'immediate') {
            return -1;
        }
        if ($item->due_date !== null) {
            return (int) now()->startOfDay()->diffInDays($item->due_date, false);
        }
        if ($item->due_mileage_km !== null && $vehicle->current_mileage !== null) {
            $left = $item->due_mileage_km - (int) round(
                ($vehicle->mileage_unit ?? 'km') === 'mi'
                    ? $vehicle->current_mileage * 1.609344
                    : $vehicle->current_mileage,
            );
            if ($left <= 0) {
                return -1;
            }

            return (int) max(1, round($left / 40));
        }

        return 9999;
    }

    private function roadmapTone(PlanItem $item): string
    {
        if ($item->status === 'overdue' || $item->urgency === 'immediate') {
            return 'overdue';
        }
        if ($item->status === 'soon') {
            return 'soon';
        }
        if ($item->explanation['requires_check_now'] ?? false) {
            return 'unknown';
        }

        return 'soft';
    }

    private function roadmapTier(MaintenanceRule $rule, PlanItem $item): string
    {
        if (in_array($rule->criticality, ['safety_critical', 'high'], true)) {
            return 'required';
        }
        if ($rule->criticality === 'medium' && $rule->rule_kind === 'interval_based') {
            return 'required';
        }
        if ($item->status === 'overdue' || $item->urgency === 'immediate') {
            return 'required';
        }

        return 'recommended';
    }

    private function stateMetricLabel(PlanItem $item, ?int $wear, ?int $usedPercent): string
    {
        if ($wear !== null) {
            return 'износ';
        }
        if ($usedPercent !== null) {
            return 'ресурс';
        }
        if ($item->explanation['requires_check_now'] ?? false) {
            return 'нужна проверка';
        }

        return 'нет данных';
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function seasonalTips(): array
    {
        $month = (int) date('n');
        $tips = [];

        if (in_array($month, [12, 1, 2, 3], true)) {
            $tips[] = [
                'key' => 'winter_wash',
                'label' => 'Зимняя мойка',
                'detail' => 'Чаще мойте днище и арки — соль ускоряет коррозию',
                'tone' => 'soft',
                'tier' => 'recommended',
            ];
            $tips[] = [
                'key' => 'post_winter_brakes',
                'label' => 'Тормоза после зимы',
                'detail' => 'Проверьте колодки и диски после сезона',
                'tone' => 'soon',
                'tier' => 'required',
            ];
        }

        if (in_array($month, [3, 4, 5], true)) {
            $tips[] = [
                'key' => 'spring_cabin_filter',
                'label' => 'Салонный фильтр',
                'detail' => 'После зимы — свежий воздух в салоне',
                'tone' => 'soft',
                'tier' => 'recommended',
            ];
        }

        return $tips;
    }

    private function knowledgeLabel(?string $band): string
    {
        return match ($band) {
            'never_tools' => 'Не работал с инструментами',
            'scared' => 'Боюсь лезть под капот',
            'novice' => 'Новичок',
            'basic' => 'Базовый уровень',
            'curious' => 'Интересуюсь, учусь',
            'confident' => 'Уверенный',
            'advanced' => 'Продвинутый',
            'pro' => 'Профи',
            default => 'Не задано',
        };
    }

    private function handsOnLabel(?string $level, ?bool $legacy): string
    {
        return match ($level) {
            'never' => 'Не готов проверять сам',
            'outside' => 'Только снаружи',
            'sometimes' => 'Иногда сам',
            'often' => 'Часто сам',
            'always' => 'Всегда сам',
            default => match ($legacy) {
                true => 'Готов проверять',
                false => 'Не готов лезть под машину',
                default => 'Не задано',
            },
        };
    }

    private function scaleLabel(int $value): string
    {
        return match (true) {
            $value <= 2 => 'минимум',
            $value === 3 => 'средне',
            $value >= 4 => 'максимум',
            default => 'средне',
        };
    }
}
