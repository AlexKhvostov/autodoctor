<?php

namespace App\Services\Telegram;

use App\Exceptions\ApiException;
use App\Models\AiConfigVersion;
use App\Models\AssistantMessage;
use App\Models\GuestProfile;
use App\Models\HistoryAnswer;
use App\Models\MileageObservation;
use App\Models\ServiceRecord;
use App\Models\TelegramBotUser;
use App\Models\Vehicle;
use App\Models\WorkCatalogItem;
use App\Services\Ai\LlmClient;
use App\Services\PlanCalculator;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Throwable;

class TelegramServiceRecordCommitService
{
    public function __construct(
        private readonly TelegramDialogueService $dialogue,
        private readonly PlanCalculator $plans,
        private readonly LlmClient $llm,
    ) {}

    public function offerSummary(GuestProfile $profile): ?string
    {
        if (! $this->dialogue->hasVehicle($profile)) {
            return null;
        }

        try {
            $draft = $this->extractDraft($profile);
        } catch (Throwable) {
            return null;
        }

        if (! $this->isCompleteDraft($profile, $draft)) {
            $this->storeDraft($profile, null);

            return null;
        }

        $this->storeDraft($profile, $draft);

        return $this->formatSummary($profile, $draft);
    }

    public function commit(GuestProfile $profile): string
    {
        $vehicle = $this->vehicleFor($profile);
        if ($vehicle === null) {
            return 'Сначала нужно записать машину — расскажите марку, модель и год.';
        }

        $draft = $this->cachedDraft($profile) ?? $this->extractDraft($profile);
        if (! $this->isCompleteDraft($profile, $draft)) {
            return 'Не смог собрать работу из диалога. Напишите, что сделали и когда — цифры сам не выдумаю.';
        }

        $record = $this->persistRecord($profile, $vehicle, $draft);
        $this->storeDraft($profile, null);

        $titles = $record->items
            ->map(fn ($item): string => (string) ($item->workCatalogItem->localized_name['ru'] ?? $item->workCatalogItem->code))
            ->implode(', ');
        $date = $record->service_date?->format('d.m.Y') ?? '';

        return "Записал в журнал: {$titles}, {$date}.";
    }

    /**
     * @param  array<string, mixed>|null  $draft
     */
    private function isCompleteDraft(GuestProfile $profile, ?array $draft): bool
    {
        if (! is_array($draft) || ! ($draft['has_work_event'] ?? false)) {
            return false;
        }

        $codes = $this->validWorkCodes($profile, $draft['work_codes'] ?? []);

        return $codes !== [];
    }

    /**
     * @param  array<string, mixed>  $draft
     */
    private function formatSummary(GuestProfile $profile, array $draft): string
    {
        $codes = $this->validWorkCodes($profile, $draft['work_codes'] ?? []);
        $catalog = WorkCatalogItem::query()->whereIn('code', $codes)->get()->keyBy('code');
        $lines = [
            (string) config('telegram.messages.save_work_summary_intro'),
            '',
        ];

        foreach ($codes as $code) {
            $title = (string) ($catalog[$code]->localized_name['ru'] ?? $code);
            $lines[] = '• '.$title;
        }

        $date = $this->resolveServiceDate($draft);
        if ($date !== null) {
            $lines[] = 'Дата: '.$date->format('d.m.Y');
        }
        if (is_numeric($draft['mileage_km'] ?? null)) {
            $lines[] = 'Пробег: '.(int) $draft['mileage_km'].' км';
        }
        $note = trim((string) ($draft['note'] ?? ''));
        if ($note !== '') {
            $lines[] = $note;
        }

        $lines[] = '';
        $lines[] = (string) config('telegram.messages.save_work_summary_outro');

        return implode("\n", $lines);
    }

    /**
     * @param  array<string, mixed>  $draft
     */
    private function persistRecord(GuestProfile $profile, Vehicle $vehicle, array $draft): ServiceRecord
    {
        return DB::transaction(function () use ($profile, $vehicle, $draft): ServiceRecord {
            $codes = $this->validWorkCodes($profile, $draft['work_codes'] ?? []);
            $catalog = WorkCatalogItem::query()->whereIn('code', $codes)->get()->keyBy('code');
            $serviceDate = $this->resolveServiceDate($draft)?->format('Y-m-d') ?? now()->format('Y-m-d');
            $mileage = is_numeric($draft['mileage_km'] ?? null)
                ? ['value' => (int) $draft['mileage_km'], 'unit' => 'km']
                : ($vehicle->current_mileage === null ? null : [
                    'value' => $vehicle->current_mileage,
                    'unit' => $vehicle->mileage_unit ?? 'km',
                ]);
            $note = trim((string) ($draft['note'] ?? ''));

            $record = ServiceRecord::query()->create([
                'vehicle_id' => $vehicle->id,
                'service_date' => $serviceDate,
                'mileage_value' => $mileage['value'] ?? null,
                'mileage_unit' => $mileage['unit'] ?? null,
                'evidence_source' => 'self',
                'note' => $note !== '' ? $note : null,
                'version' => 1,
            ]);
            foreach ($codes as $code) {
                $record->items()->create(['work_catalog_item_id' => $catalog[$code]->id]);
            }
            $record->load('items.workCatalogItem');
            $this->syncHistoryAnswers($vehicle, $record, $catalog);

            if ($mileage !== null) {
                $isNewCurrent = $vehicle->current_mileage === null
                    || $this->toKm($mileage['value'], $mileage['unit'])
                        > $this->toKm($vehicle->current_mileage, $vehicle->mileage_unit ?? 'km');
                if ($isNewCurrent) {
                    MileageObservation::query()->create([
                        'vehicle_id' => $vehicle->id,
                        'value' => $mileage['value'],
                        'unit' => $mileage['unit'],
                        'source' => 'service',
                        'observed_at' => now(),
                    ]);
                    $vehicle->forceFill([
                        'current_mileage' => $mileage['value'],
                        'mileage_unit' => $mileage['unit'],
                        'version' => $vehicle->version + 1,
                    ])->save();
                }
            }

            $this->plans->calculate($vehicle->fresh('configuration'));

            return $record;
        });
    }

    /**
     * @param  array<string, mixed>|null  $draft
     */
    private function resolveServiceDate(?array $draft): ?CarbonImmutable
    {
        $raw = trim((string) ($draft['service_date'] ?? ''));
        if ($raw === '') {
            return null;
        }

        try {
            return CarbonImmutable::parse($raw);
        } catch (Throwable) {
            return null;
        }
    }

    /**
     * @param  list<string>|mixed  $codes
     * @return list<string>
     */
    private function validWorkCodes(GuestProfile $profile, mixed $codes): array
    {
        if (! is_array($codes)) {
            return [];
        }

        $vehicle = $this->vehicleFor($profile);
        if ($vehicle === null) {
            return [];
        }

        $allowed = $this->plans->applicableWorkCodes($vehicle)->all();
        $valid = [];
        foreach ($codes as $code) {
            if (! is_string($code)) {
                continue;
            }
            $code = trim($code);
            if ($code !== '' && in_array($code, $allowed, true)) {
                $valid[] = $code;
            }
        }

        return array_values(array_unique($valid));
    }

    private function vehicleFor(GuestProfile $profile): ?Vehicle
    {
        return $profile->vehicles()->with('configuration')->orderByDesc('created_at')->first();
    }

    /**
     * @return array<string, mixed>|null
     */
    private function extractDraft(GuestProfile $profile): ?array
    {
        $vehicle = $this->vehicleFor($profile);
        if ($vehicle === null) {
            return null;
        }

        $config = AiConfigVersion::query()
            ->where('is_active', true)
            ->latest('id')
            ->first();
        if ($config === null || ! $config->enabled) {
            throw new ApiException('AI_NOT_CONFIGURED', (string) config('telegram.messages.ai_unavailable'), 503);
        }

        $thread = $profile->assistantThreads()->orderByDesc('last_message_at')->first();
        $lines = [];
        if ($thread !== null) {
            $messages = AssistantMessage::query()
                ->where('assistant_thread_id', $thread->id)
                ->orderBy('created_at')
                ->get();
            foreach ($messages as $message) {
                $lines[] = $message->role.': '.$message->content;
            }
        }
        $transcript = trim(implode("\n", $lines));
        if ($transcript === '') {
            return null;
        }

        $catalogLines = WorkCatalogItem::query()
            ->whereIn('code', $this->plans->applicableWorkCodes($vehicle)->all())
            ->get()
            ->map(fn (WorkCatalogItem $item): string => $item->code.': '.($item->localized_name['ru'] ?? $item->code))
            ->implode("\n");

        try {
            $result = $this->llm->chat(
                $config->primary_provider,
                $config->primary_model,
                [
                    [
                        'role' => 'system',
                        'content' => 'Extract a maintenance work event from the chat for AutoDoctor journal. '
                            .'Reply with JSON only, no markdown. Keys: has_work_event (bool), work_codes (array of catalog codes), '
                            .'service_date (YYYY-MM-DD or null), mileage_km (int or null), note (string or null). '
                            .'Set has_work_event true only when the user reports completed maintenance (replaced, changed, serviced). '
                            .'Not for complaints, questions or future plans. Never invent date, mileage or work. '
                            .'If user says today/сегодня, use today\'s date. Map tire/wheel replacement to tire_condition_inspection. '
                            ."Allowed work codes:\n".$catalogLines,
                    ],
                    ['role' => 'user', 'content' => $transcript],
                ],
                500,
            );
        } catch (Throwable) {
            return null;
        }

        $raw = trim($result['content']);
        if (preg_match('/\{.*\}/s', $raw, $match) === 1) {
            $raw = $match[0];
        }
        $decoded = json_decode($raw, true);

        return is_array($decoded) ? $decoded : null;
    }

    /**
     * @return array<string, mixed>|null
     */
    private function cachedDraft(GuestProfile $profile): ?array
    {
        $user = TelegramBotUser::query()
            ->where('telegram_user_id', $profile->telegram_id)
            ->first();
        $draft = $user?->pending_service_record_draft;

        return is_array($draft) ? $draft : null;
    }

    /**
     * @param  array<string, mixed>|null  $draft
     */
    private function storeDraft(GuestProfile $profile, ?array $draft): void
    {
        $user = TelegramBotUser::query()
            ->where('telegram_user_id', $profile->telegram_id)
            ->first();
        if ($user === null) {
            return;
        }

        $user->pending_service_record_draft = $draft;
        $user->save();
    }

    private function syncHistoryAnswers(Vehicle $vehicle, ServiceRecord $record, $catalog): void
    {
        foreach ($catalog as $item) {
            $this->writeHistoryFromLatest($vehicle, $item->id);
        }
    }

    private function writeHistoryFromLatest(Vehicle $vehicle, string $workCatalogItemId): void
    {
        $latest = ServiceRecord::query()
            ->where('vehicle_id', $vehicle->id)
            ->whereHas('items', fn ($query) => $query->where('work_catalog_item_id', $workCatalogItemId))
            ->orderByDesc('service_date')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->first();
        $answer = HistoryAnswer::query()
            ->where('vehicle_id', $vehicle->id)
            ->where('work_catalog_item_id', $workCatalogItemId)
            ->lockForUpdate()
            ->first();

        if ($latest === null) {
            if ($answer !== null) {
                $answer->fill([
                    'answer' => 'unknown',
                    'performed_date' => null,
                    'performed_mileage_km' => null,
                    'version' => $answer->version + 1,
                ])->save();
            }

            return;
        }

        $values = [
            'answer' => 'done_known',
            'performed_date' => $latest->service_date,
            'performed_mileage_km' => $latest->mileage_value === null
                ? null
                : (int) round($this->toKm($latest->mileage_value, $latest->mileage_unit ?? 'km')),
        ];
        if ($answer === null) {
            HistoryAnswer::query()->create([
                'vehicle_id' => $vehicle->id,
                'work_catalog_item_id' => $workCatalogItemId,
                ...$values,
                'version' => 1,
            ]);
        } else {
            $answer->fill([...$values, 'version' => $answer->version + 1])->save();
        }
    }

    private function toKm(int $value, string $unit): float
    {
        return $unit === 'mi' ? $value * 1.609344 : $value;
    }
}
