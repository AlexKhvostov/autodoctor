<?php

namespace App\Services\Ai;

use App\Models\AssistantThread;
use App\Models\GuestProfile;
use App\Models\GuestSkillProfile;
use App\Models\MaintenancePlanSnapshot;
use App\Models\Vehicle;
use App\Models\VehicleIssue;
use App\Models\WorkCatalogItem;
use App\Services\AgentProfileService;
use App\Services\GuestSkillProfileService;
use Illuminate\Support\Collection;

/**
 * Полный снимок пользователя и машины для AI: все накопленные факты,
 * включая явно пустые поля («не задано» / «не отвечал»).
 */
class VehicleUserDossierBuilder
{
    private const NOTES_LIMIT = 80;

    private const SERVICE_RECORDS_LIMIT = 100;

    private const CONDITION_LIMIT = 100;

    private const MILEAGE_LOG_LIMIT = 50;

    public function __construct(
        private readonly GuestSkillProfileService $skills,
        private readonly AgentProfileService $agents,
    ) {}

    public function build(GuestProfile $profile, Vehicle $vehicle): string
    {
        $locale = app()->getLocale() === 'en' ? 'en' : 'ru';

        $profile->loadMissing(['aiNotes', 'user', 'skillProfile', 'agentPreference']);
        $vehicle->loadMissing([
            'configuration',
            'serviceRecords.items.workCatalogItem',
            'conditionObservations.workCatalogItem',
            'historyAnswers.workCatalogItem',
            'mileageObservations',
            'aiNotes',
            'issues.sourceThread',
        ]);

        $lines = [];
        $lines[] = '### Досье AutoDoctor (полный снимок; «не задано» / «не отвечал» — тоже факты)';
        $lines = array_merge($lines, $this->userSection($profile));
        $lines = array_merge($lines, $this->skillSection($profile));
        $lines = array_merge($lines, $this->agentPreferencesSection($profile));
        $lines = array_merge($lines, $this->vehicleCardSection($vehicle));
        $lines = array_merge($lines, $this->configurationSection($vehicle));
        $lines = array_merge($lines, $this->notesSection(
            'Заметки о пользователе',
            $profile->aiNotes,
            'пока нет (по умолчанию обращение «вы»).',
        ));
        $lines = array_merge($lines, $this->notesSection(
            'Заметки о машине',
            $vehicle->aiNotes,
            'пока нет.',
        ));
        $lines = array_merge($lines, $this->issuesSection($vehicle));
        $lines = array_merge($lines, $this->historySection($vehicle, $locale));
        $lines = array_merge($lines, $this->serviceJournalSection($vehicle, $locale));
        $lines = array_merge($lines, $this->conditionSection($vehicle, $locale));
        $lines = array_merge($lines, $this->mileageLogSection($vehicle));
        $lines = array_merge($lines, $this->planSection($vehicle, $locale));
        $lines[] = 'Подсказка: опирайся на досье целиком; не говори «не знаю», если поле есть (даже как «не задано»). Говори «в ваших записях».';
        $lines[] = 'Важно: в ответах пользователю используй только человеческие формулировки из досье'
            .' (названия работ, статусы, срочность). Не произноси служебные коды вроде'
            .' immediate, high, overdue, brake_fluid, open, watching — переводи «по-человечески».';

        return implode("\n", $lines);
    }

    /**
     * @return list<string>
     */
    private function userSection(GuestProfile $profile): array
    {
        $user = $profile->user;
        $lines = ['## Пользователь'];
        if ($user === null) {
            $lines[] = 'Аккаунт: гость (Google не привязан).';
            $lines[] = 'Имя: не задано';
            $lines[] = 'Email: не задан';
        } else {
            $lines[] = 'Аккаунт: привязан Google.';
            $lines[] = 'Имя: '.$this->display($user->name);
            $lines[] = 'Email: '.$this->display($user->email);
        }
        $lines[] = 'Язык интерфейса: '.(app()->getLocale() === 'en' ? 'en' : 'ru');

        return $lines;
    }

    /**
     * @return list<string>
     */
    private function skillSection(GuestProfile $profile): array
    {
        $skill = $profile->skillProfile ?? $this->skills->forProfile($profile);
        $band = $skill->band();
        $handsOn = $skill->hands_on;
        $handsText = match ($handsOn) {
            true => 'да, готов к простым проверкам',
            false => 'нет, не готов лезть под капот/машину',
            default => 'неизвестно',
        };

        $rule = match ($band) {
            GuestSkillProfile::BAND_NOVICE => 'новичок: только простой язык; без узких терминов без перевода «по-человечески»; '
                .'сначала бытовые причины и безопасные проверки из салона/снаружи; не просить лезть под капот/машину'
                .($handsOn === false ? '; только сервис / безопасные внешние проверки' : '')
                .'; при неясности/критичности — СТО + короткий текст для мастера.',
            GuestSkillProfile::BAND_BASIC => 'базовый: простой язык; можно чуть подробнее; диагностика от простого к сложному; '
                .'сложные узлы — после исключения бытового'
                .($handsOn === false ? '; не просить лезть под машину/капот' : '')
                .'.',
            default => 'уверенный: можно чуть техничнее, но без жаргона ради жаргона; всё равно от простого к сложному'
                .($handsOn === true ? '; допустимы аккуратные проверки под капотом/у колёс при безопасности' : '')
                .($handsOn === false ? '; не просить лезть под машину/капот' : '')
                .'.',
        };

        return [
            '## Уровень владельца',
            'уровень знаний: '.$this->skillBandLabel($band),
            'оценка: '.(int) $skill->overall_score,
            'готовность к проверкам руками: '.$handsText,
            'уровень практики: '.$this->handsOnLevelLabel($skill->resolvedHandsOnLevel()),
            'самооценка: '.$this->skillBandLabel($skill->self_reported_band),
            'правило: '.$rule,
        ];
    }

    /**
     * @return list<string>
     */
    private function agentPreferencesSection(GuestProfile $profile): array
    {
        $prefs = $profile->agentPreference ?? $this->agents->preferences($profile);
        $instructions = filled($prefs->custom_instructions)
            ? trim((string) $prefs->custom_instructions)
            : 'не заданы';

        return [
            '## Настройки агента от пользователя',
            'простота: '.(int) $prefs->simplicity.'/10 (0 = максимально просто; 10 = можно техничнее; не нарушай уровень владельца)',
            'краткость: '.(int) $prefs->verbosity.'/10 (0 = очень коротко; 10 = подробнее)',
            'прямота: '.(int) $prefs->directness.'/10 (0 = мягко; 10 = прямее про риски)',
            'инициативность: '.(int) $prefs->initiative.'/10 (0 = ждёт; 10 = сам уточняет)',
            'инструкции: '.$instructions,
            'правило: уважай слайдеры и инструкции пользователя, но безопасность и уровень владельца важнее стиля.',
        ];
    }

    /**
     * @return list<string>
     */
    private function vehicleCardSection(Vehicle $vehicle): array
    {
        $configuration = $vehicle->configuration;
        $make = $configuration?->make ?? '';
        $model = $configuration?->model ?? '';

        $lines = ['## Карточка автомобиля'];
        $lines[] = 'Профиль авто: '.$this->display(trim($make.' '.$model) !== '' ? trim($make.' '.$model) : null);
        $lines[] = 'Год выпуска: '.$this->display($vehicle->production_year);
        $lines[] = 'Текущий пробег: '.$this->mileageLine($vehicle->current_mileage, $vehicle->mileage_unit);
        $lines[] = 'Дата начала эксплуатации: '.$this->dateLine($vehicle->first_use_date);
        $lines[] = 'VIN: '.$this->vinLine($vehicle);
        $lines[] = 'Статус профиля: '.$this->profileStatusLabel($vehicle->profile_status);
        $lines[] = 'Область рекомендаций плана: '.$this->planEligibilityLabel($vehicle->plan_eligibility);

        return $lines;
    }

    /**
     * @return list<string>
     */
    private function configurationSection(Vehicle $vehicle): array
    {
        $configuration = $vehicle->configuration;
        $lines = ['## Конфигурация'];

        if ($configuration === null) {
            $lines[] = 'Конфигурация: не задана';

            return $lines;
        }

        $lines[] = 'Поколение: '.$this->display($configuration->generation);
        $lines[] = 'Топливо: '.$this->fuelTypeLabel($configuration->fuel_type);

        $engineParts = [];
        if ($configuration->engine_displacement_cc !== null) {
            $engineParts[] = $configuration->engine_displacement_cc.' см³';
        }
        if (filled($configuration->engine_code)) {
            $engineParts[] = 'код двигателя '.$configuration->engine_code;
        }
        if ($configuration->engine_power_kw !== null) {
            $hp = (int) round(((float) $configuration->engine_power_kw) * 1.35962);
            $engineParts[] = $configuration->engine_power_kw.' кВт (~'.$hp.' л.с.)';
        }
        $lines[] = 'Двигатель: '.($engineParts !== [] ? implode(', ', $engineParts) : 'не задано');

        if ($configuration->transmission_type === null) {
            $lines[] = 'Трансмиссия: не задано';
        } else {
            $transmission = $this->transmissionLabel($configuration->transmission_type);
            if ($configuration->transmission_gears !== null) {
                $transmission .= ', '.$configuration->transmission_gears.' передач';
            } else {
                $transmission .= ', число передач не задано';
            }
            $lines[] = 'Трансмиссия: '.$transmission;
        }

        $lines[] = 'Привод: '.$this->drivetrainLabel($configuration->drivetrain);
        $lines[] = 'Рынок: '.$this->display($configuration->market);

        return $lines;
    }

    /**
     * @param  Collection<int, mixed>  $notes
     * @return list<string>
     */
    private function notesSection(string $title, Collection $notes, string $emptyHint): array
    {
        $sorted = $notes->sortByDesc(fn ($note) => $note->created_at?->timestamp ?? 0)->values();
        $total = $sorted->count();
        $shown = $sorted->take(self::NOTES_LIMIT);

        if ($shown->isEmpty()) {
            return ["## {$title}", "{$title}: {$emptyHint}"];
        }

        $lines = ["## {$title}"];
        $lines[] = "{$title} (устойчивые факты — учитывай):";
        foreach ($shown as $note) {
            $lines[] = '- '.$note->body;
        }
        if ($total > self::NOTES_LIMIT) {
            $lines[] = '(показаны последние '.self::NOTES_LIMIT.' из '.$total.')';
        }

        return $lines;
    }

    /**
     * @return list<string>
     */
    private function issuesSection(Vehicle $vehicle): array
    {
        $open = $vehicle->issues
            ->filter(function (VehicleIssue $issue): bool {
                if (! $issue->isOpenLike()) {
                    return false;
                }
                // Кейсы из архивного чата не должны провоцировать follow-up.
                if ($issue->sourceThread?->status === AssistantThread::STATUS_ARCHIVED) {
                    return false;
                }

                return true;
            })
            ->sortByDesc(fn (VehicleIssue $issue) => $issue->last_touched_at?->timestamp ?? 0)
            ->values();
        $recentClosed = $vehicle->issues
            ->filter(function (VehicleIssue $issue): bool {
                if ($issue->isOpenLike()) {
                    return false;
                }
                $at = $issue->resolved_at ?? $issue->last_touched_at;
                if ($at === null) {
                    return true;
                }

                return $at->greaterThanOrEqualTo(now()->subDays(60));
            })
            ->sortByDesc(fn (VehicleIssue $issue) => $issue->last_touched_at?->timestamp ?? 0)
            ->take(10)
            ->values();

        $lines = ['## Кейсы жалоб / симптомов'];
        if ($open->isEmpty() && $recentClosed->isEmpty()) {
            $lines[] = 'Открытых и недавних кейсов нет.';

            return $lines;
        }

        if ($open->isNotEmpty()) {
            $stale = $open->filter(function (VehicleIssue $issue): bool {
                $at = $issue->last_touched_at ?? $issue->first_seen_at;

                return $at !== null && $at->lessThan(now()->subDays(3));
            });
            $lines[] = 'Открытые / на наблюдении:';
            foreach ($open as $issue) {
                $lines = array_merge($lines, $this->issueLines($issue));
            }
            if ($stale->isNotEmpty()) {
                $lines[] = 'Подсказка follow-up: есть кейсы без обновления ≥3 дней — мягко спроси, как сейчас с этой проблемой.';
            }
        } else {
            $lines[] = 'Открытых кейсов нет.';
        }

        if ($recentClosed->isNotEmpty()) {
            $lines[] = 'Недавно закрытые (для контекста):';
            foreach ($recentClosed as $issue) {
                $lines = array_merge($lines, $this->issueLines($issue));
            }
        }

        return $lines;
    }

    /**
     * @return list<string>
     */
    private function issueLines(VehicleIssue $issue): array
    {
        $lines = [];
        $lines[] = '- '.$issue->title
            .' — статус: '.$this->issueStatusLabel($issue->status)
            .', срочность: '.$this->issueUrgencyLabel($issue->urgency)
            .' (служебный id '.$issue->id.')';
        $lines[] = '  симптомы: '.$this->display($issue->symptoms);
        $suggested = is_array($issue->checks_suggested) ? $issue->checks_suggested : [];
        $done = is_array($issue->checks_done) ? $issue->checks_done : [];
        $lines[] = '  проверки предложены: '.($suggested !== [] ? implode('; ', $suggested) : 'не задано');
        $lines[] = '  проверки сделаны: '.($done !== [] ? implode('; ', $done) : 'не задано');
        $lines[] = '  рекомендации: '.$this->display($issue->recommendations);
        if ($issue->resolution_note) {
            $lines[] = '  итог: '.$issue->resolution_note;
        }
        $touched = $issue->last_touched_at?->format('Y-m-d') ?? 'не задано';
        $lines[] = '  обновлено: '.$touched;

        return $lines;
    }

    /**
     * @return list<string>
     */
    private function historySection(Vehicle $vehicle, string $locale): array
    {
        $catalog = WorkCatalogItem::query()->orderBy('code')->get();
        $byCode = $vehicle->historyAnswers->keyBy(fn ($answer) => $answer->workCatalogItem?->code);

        $lines = ['## История обслуживания (опрос при старте)'];
        $lines[] = 'Ниже все слоты каталога работ. «не отвечал» = пользователь ещё не отвечал на этот пункт.';

        if ($catalog->isEmpty()) {
            $lines[] = 'Каталог работ пуст.';

            return $lines;
        }

        foreach ($catalog as $item) {
            $code = $item->code;
            $name = $this->catalogName($item, $locale);
            $answer = $byCode->get($code);
            if ($answer === null) {
                $lines[] = '- '.$name.': не отвечал';

                continue;
            }

            $status = match ((string) $answer->answer) {
                'done_known' => 'сделано',
                'done_unknown' => 'сделано (дата неизвестна)',
                'not_done' => 'не делалось',
                'not_applicable' => 'не применимо',
                'unknown' => 'неизвестно (пользователь так отметил)',
                default => 'неизвестно',
            };
            $details = [];
            if ($answer->performed_date !== null) {
                $details[] = 'дата '.$answer->performed_date->format('Y-m-d');
            } else {
                $details[] = 'дата не задана';
            }
            if ($answer->performed_mileage_km !== null) {
                $details[] = 'пробег '.$answer->performed_mileage_km.' км';
            } else {
                $details[] = 'пробег не задан';
            }
            $lines[] = '- '.$name.': '.$status.'; '.implode(', ', $details);
        }

        return $lines;
    }

    /**
     * @return list<string>
     */
    private function serviceJournalSection(Vehicle $vehicle, string $locale): array
    {
        $sorted = $vehicle->serviceRecords
            ->sortByDesc(fn ($record) => $record->service_date?->format('Y-m-d').'-'.$record->id)
            ->values();
        $total = $sorted->count();
        $records = $sorted->take(self::SERVICE_RECORDS_LIMIT);

        $lines = ['## Журнал обслуживания'];
        if ($records->isEmpty()) {
            $lines[] = 'Записей пока нет (работы могли быть указаны только в опросе истории).';

            return $lines;
        }

        $lines[] = 'Записи (новые сверху):';
        foreach ($records as $record) {
            $works = $record->items
                ->map(function ($item) use ($locale): string {
                    $catalog = $item->workCatalogItem;
                    if ($catalog === null) {
                        return 'работа не указана';
                    }

                    return $this->catalogName($catalog, $locale);
                })
                ->filter()
                ->implode(', ');
            $lines[] = '- '.$this->dateLine($record->service_date).'; '
                .$this->mileageLine($record->mileage_value, $record->mileage_unit).'; '
                .'источник: '.$this->sourceLabel($record->evidence_source).'; '
                .'работы: '.($works !== '' ? $works : 'не указаны');
            if (filled($record->note)) {
                $lines[] = '  заметка: '.$record->note;
            } else {
                $lines[] = '  заметка: не задана';
            }
        }
        if ($total > self::SERVICE_RECORDS_LIMIT) {
            $lines[] = '(показаны последние '.self::SERVICE_RECORDS_LIMIT.' из '.$total.')';
        }

        return $lines;
    }

    /**
     * @return list<string>
     */
    private function conditionSection(Vehicle $vehicle, string $locale): array
    {
        $sorted = $vehicle->conditionObservations
            ->sortByDesc(fn ($item) => $item->observed_at?->format('Y-m-d').'-'.$item->id)
            ->values();
        $total = $sorted->count();
        $observations = $sorted->take(self::CONDITION_LIMIT);

        $lines = ['## Состояние (износ)'];
        if ($observations->isEmpty()) {
            $lines[] = 'Наблюдений пока нет.';

            return $lines;
        }

        $lines[] = 'Наблюдения (новые сверху):';
        foreach ($observations as $observation) {
            $catalog = $observation->workCatalogItem;
            $name = $catalog !== null
                ? $this->catalogName($catalog, $locale)
                : 'позиция не указана';
            $wear = $observation->wear_percent;
            $lines[] = '- '.$this->dateLine($observation->observed_at).'; '
                .$name.'; '
                .'износ: '.($wear === null ? 'не задано' : $wear.'%').'; '
                .$this->mileageLine($observation->mileage_value, $observation->mileage_unit).'; '
                .'источник: '.$this->sourceLabel($observation->source);
            if (filled($observation->note)) {
                $lines[] = '  заметка: '.$observation->note;
            } else {
                $lines[] = '  заметка: не задана';
            }
        }
        if ($total > self::CONDITION_LIMIT) {
            $lines[] = '(показаны последние '.self::CONDITION_LIMIT.' из '.$total.')';
        }

        return $lines;
    }

    /**
     * @return list<string>
     */
    private function mileageLogSection(Vehicle $vehicle): array
    {
        $sorted = $vehicle->mileageObservations
            ->sortByDesc(fn ($item) => $item->observed_at?->format('Y-m-d H:i:s').'-'.$item->id)
            ->values();
        $total = $sorted->count();
        $items = $sorted->take(self::MILEAGE_LOG_LIMIT);

        $lines = ['## Лог пробега'];
        if ($items->isEmpty()) {
            $lines[] = 'Отдельных наблюдений пробега пока нет (есть только текущий пробег в карточке, если задан).';

            return $lines;
        }

        $lines[] = 'Наблюдения (новые сверху):';
        foreach ($items as $item) {
            $when = $item->observed_at;
            $whenText = $when !== null
                ? (method_exists($when, 'format') ? $when->format('Y-m-d H:i') : (string) $when)
                : 'дата не задана';
            $lines[] = '- '.$whenText.'; '
                .$this->mileageLine($item->value, $item->unit).'; '
                .'источник: '.$this->sourceLabel($item->source);
        }
        if ($total > self::MILEAGE_LOG_LIMIT) {
            $lines[] = '(показаны последние '.self::MILEAGE_LOG_LIMIT.' из '.$total.')';
        }

        return $lines;
    }

    /**
     * @return list<string>
     */
    private function planSection(Vehicle $vehicle, string $locale): array
    {
        $snapshot = MaintenancePlanSnapshot::query()
            ->where('vehicle_id', $vehicle->id)
            ->orderByDesc('calculated_at')
            ->with(['items.rule', 'rulesetVersion'])
            ->first();

        $lines = ['## План ТО (актуальный снимок)'];
        if ($snapshot === null) {
            $lines[] = 'План ещё не рассчитывался.';

            return $lines;
        }

        $lines[] = 'Рассчитан: '.($snapshot->calculated_at?->toISOString() ?? 'не задано');
        $lines[] = 'Версия правил: '.$this->display($snapshot->rulesetVersion?->version);
        $lines[] = 'Алгоритм: '.$this->display($snapshot->algorithm_version);

        $items = $snapshot->items->sortBy(fn ($item) => $item->rule?->work_code ?? '');
        if ($items->isEmpty()) {
            $lines[] = 'Пунктов плана нет.';

            return $lines;
        }

        $lines[] = 'Пункты (говори пользователю только человеческие названия и формулировки ниже):';
        foreach ($items as $item) {
            $rule = $item->rule;
            $code = $rule?->work_code ?? 'unknown';
            $title = is_array($rule?->localized_content)
                ? ($rule->localized_content['title'][$locale] ?? $this->workCodeFallbackLabel($code))
                : $this->workCodeFallbackLabel($code);
            $dueParts = [];
            if ($item->due_mileage_km !== null) {
                $dueParts[] = 'к '.$item->due_mileage_km.' км';
            } else {
                $dueParts[] = 'пробег срока не задан';
            }
            if ($item->due_date !== null) {
                $dueParts[] = 'к '.$item->due_date->format('Y-m-d');
            } else {
                $dueParts[] = 'дата срока не задана';
            }
            $lines[] = '- '.$title.': статус «'.$this->planStatusLabel($item->status)
                .'», срочность «'.$this->planUrgencyLabel($item->urgency)
                .'»; '.implode(', ', $dueParts);
        }

        $warnings = is_array($snapshot->warnings) ? $snapshot->warnings : [];
        if ($warnings !== []) {
            $lines[] = 'Предупреждения плана: '.json_encode($warnings, JSON_UNESCAPED_UNICODE);
        }

        return $lines;
    }

    private function vinLine(Vehicle $vehicle): string
    {
        if ($vehicle->vin_last4 === null && $vehicle->vin_ciphertext === null) {
            return 'не задан (пользователь не указывал)';
        }

        $last4 = $vehicle->vin_last4 ?? '????';

        return 'задан, последние 4 символа: '.$last4.' (полный VIN в контексте не передаётся)';
    }

    private function display(mixed $value): string
    {
        if ($value === null || $value === '') {
            return 'не задано';
        }

        return (string) $value;
    }

    private function dateLine(mixed $date): string
    {
        if ($date === null) {
            return 'дата не задана';
        }
        if (method_exists($date, 'format')) {
            return $date->format('Y-m-d');
        }

        return (string) $date;
    }

    private function mileageLine(mixed $value, mixed $unit): string
    {
        if ($value === null) {
            return 'пробег не задан';
        }

        $unitLabel = match ((string) ($unit ?: 'km')) {
            'mi', 'mile', 'miles' => 'миль',
            default => 'км',
        };

        return $value.' '.$unitLabel;
    }

    private function catalogName(WorkCatalogItem $item, string $locale): string
    {
        $name = $item->localized_name;
        if (is_array($name) && filled($name[$locale] ?? null)) {
            return (string) $name[$locale];
        }

        return $this->workCodeFallbackLabel($item->code);
    }

    private function planStatusLabel(mixed $status): string
    {
        return match ((string) $status) {
            'current' => 'в норме / ещё не скоро',
            'soon' => 'скоро нужно',
            'overdue' => 'просрочено',
            'unknown' => 'недостаточно данных',
            'not_applicable' => 'не применимо',
            'completed' => 'выполнено',
            default => $this->display($status),
        };
    }

    private function planUrgencyLabel(mixed $urgency): string
    {
        return match ((string) $urgency) {
            'none' => 'обычная (без срочности)',
            'low' => 'низкая',
            'medium' => 'средняя',
            'high' => 'высокая',
            'immediate' => 'нужно срочно',
            'critical_attention' => 'критическое внимание',
            default => $this->display($urgency),
        };
    }

    private function issueStatusLabel(mixed $status): string
    {
        return match ((string) $status) {
            'open' => 'открыт',
            'watching' => 'на наблюдении',
            'resolved' => 'закрыт',
            'dismissed' => 'снят',
            default => $this->display($status),
        };
    }

    private function issueUrgencyLabel(mixed $urgency): string
    {
        return match ((string) $urgency) {
            'low' => 'низкая',
            'medium' => 'средняя',
            'high' => 'высокая',
            default => $this->display($urgency),
        };
    }

    private function skillBandLabel(mixed $band): string
    {
        return match ((string) $band) {
            GuestSkillProfile::BAND_NOVICE, 'novice' => 'новичок',
            GuestSkillProfile::BAND_BASIC, 'basic' => 'базовый',
            GuestSkillProfile::BAND_CONFIDENT, 'confident' => 'уверенный',
            default => $this->display($band),
        };
    }

    private function handsOnLevelLabel(mixed $level): string
    {
        return match ((string) $level) {
            'never' => 'никогда не делает сам',
            'rarely' => 'редко',
            'sometimes' => 'иногда',
            'often' => 'часто',
            'yes' => 'да',
            'no' => 'нет',
            default => $this->display($level),
        };
    }

    private function fuelTypeLabel(mixed $fuel): string
    {
        return match ((string) $fuel) {
            'petrol' => 'бензин',
            'diesel' => 'дизель',
            'hybrid' => 'гибрид',
            'electric' => 'электро',
            'lpg' => 'газ (LPG)',
            'other' => 'другое',
            default => $this->display($fuel),
        };
    }

    private function transmissionLabel(mixed $type): string
    {
        return match ((string) $type) {
            'manual' => 'механика',
            'automatic' => 'автомат',
            default => $this->display($type),
        };
    }

    private function drivetrainLabel(mixed $type): string
    {
        return match ((string) $type) {
            'fwd' => 'передний привод',
            'rwd' => 'задний привод',
            'awd' => 'полный привод',
            '4wd' => 'полный привод (4WD)',
            default => $this->display($type),
        };
    }

    private function profileStatusLabel(mixed $status): string
    {
        return match ((string) $status) {
            'pending_review' => 'ожидает проверки',
            'confirmed' => 'подтверждён',
            'incomplete' => 'неполный',
            default => $this->display($status),
        };
    }

    private function planEligibilityLabel(mixed $value): string
    {
        return match ((string) $value) {
            'universal_type_only' => 'только универсальные рекомендации',
            'specific_oem_allowed' => 'доступны рекомендации под модель',
            default => $this->display($value),
        };
    }

    private function sourceLabel(mixed $source): string
    {
        return match ((string) $source) {
            'manual' => 'вручную',
            'import' => 'импорт',
            'assistant' => 'из чата с ассистентом',
            'service_record' => 'из записи обслуживания',
            'odometer' => 'с одометра',
            default => $this->display($source),
        };
    }

    private function workCodeFallbackLabel(string $code): string
    {
        return match ($code) {
            'brake_system_inspection' => 'Проверка тормозной системы',
            'brake_fluid' => 'Тормозная жидкость',
            'brake_pads' => 'Тормозные колодки',
            'brake_discs' => 'Тормозные диски',
            'engine_oil' => 'Моторное масло',
            'oil_filter' => 'Масляный фильтр',
            'air_filter' => 'Воздушный фильтр',
            'cabin_filter' => 'Салонный фильтр',
            'spark_plugs' => 'Свечи зажигания',
            'coolant' => 'Охлаждающая жидкость',
            'timing_belt' => 'Ремень ГРМ',
            'battery' => 'Аккумулятор',
            'tires' => 'Шины',
            'unknown' => 'работа не указана',
            default => str_replace('_', ' ', $code),
        };
    }
}
