<?php

namespace App\Services\Telegram;

use App\Exceptions\ApiException;
use App\Models\AiConfigVersion;
use App\Models\AssistantMessage;
use App\Models\GuestProfile;
use App\Models\Vehicle;
use App\Services\Ai\LlmClient;
use App\Services\VehicleService;
use Throwable;

class TelegramVehicleCommitService
{
    public function __construct(
        private readonly TelegramDialogueService $dialogue,
        private readonly VehicleService $vehicles,
        private readonly LlmClient $llm,
    ) {}

    public function commit(GuestProfile $profile): string
    {
        if ($this->dialogue->hasVehicle($profile)) {
            return 'Машина уже записана. Можно писать про работы.';
        }

        $draft = $this->extractDraft($profile);
        if (! is_array($draft)) {
            return 'Не смог собрать карточку из диалога. Напишите марку, модель и год — цифры сам не выдумаю.';
        }

        $make = trim((string) ($draft['make'] ?? ''));
        $model = trim((string) ($draft['model'] ?? ''));
        $year = $draft['production_year'] ?? null;
        if ($make === '' || $model === '') {
            return 'Чтобы записать, нужны марка и модель. Напишите, что помните.';
        }
        if (! is_numeric($year)) {
            return 'Чтобы записать, нужен год выпуска. Напишите год цифрами — сам не подставлю.';
        }

        $fuel = $this->fuelType($draft['fuel_type'] ?? null);
        $displacement = is_numeric($draft['displacement_cc'] ?? null)
            ? (int) $draft['displacement_cc']
            : null;
        if ($displacement === null && in_array($fuel, ['petrol', 'diesel', 'hybrid', 'lpg'], true)) {
            $fuel = 'other';
        }
        $payload = [
            'make' => $make,
            'model' => $model,
            'production_year' => (int) $year,
            'fuel_type' => $fuel,
            'engine' => [
                'displacement_cc' => $displacement,
                'engine_code' => null,
                'power_kw' => null,
            ],
        ];
        if (is_numeric($draft['mileage_km'] ?? null)) {
            $payload['mileage'] = [
                'value' => (int) $draft['mileage_km'],
                'unit' => 'km',
            ];
        }
        $vin = strtoupper(trim((string) ($draft['vin'] ?? '')));
        if (preg_match('/^[A-HJ-NPR-Z0-9]{17}$/', $vin) === 1) {
            $payload['vin'] = $vin;
        }

        $session = $this->dialogue->sessionFor($profile);
        $vehicle = $this->vehicles->create($session, $payload);
        $this->attachThread($profile, $vehicle);

        $yearLabel = (string) $payload['production_year'];

        return "Записал: {$make} {$model}, {$yearLabel}. Можно писать, что делали с машиной.";
    }

    /**
     * @return array<string, mixed>|null
     */
    private function extractDraft(GuestProfile $profile): ?array
    {
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

        try {
            $result = $this->llm->chat(
                $config->primary_provider,
                $config->primary_model,
                [
                    [
                        'role' => 'system',
                        'content' => 'Extract a car card from the chat. Reply with JSON only, no markdown. Keys: make, model, production_year, fuel_type, mileage_km, vin, displacement_cc. Use null when unknown. Never invent a year, VIN or mileage. fuel_type one of petrol,diesel,hybrid,electric,lpg,other,null.',
                    ],
                    ['role' => 'user', 'content' => $transcript],
                ],
                400,
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

    private function fuelType(mixed $value): string
    {
        $allowed = ['petrol', 'diesel', 'hybrid', 'electric', 'lpg', 'other'];
        $fuel = is_string($value) ? strtolower(trim($value)) : '';

        return in_array($fuel, $allowed, true) ? $fuel : 'other';
    }

    private function attachThread(GuestProfile $profile, Vehicle $vehicle): void
    {
        $thread = $profile->assistantThreads()
            ->where('status', 'active')
            ->orderByDesc('last_message_at')
            ->first();
        if ($thread !== null && $thread->vehicle_id === null) {
            $thread->vehicle_id = $vehicle->id;
            $thread->save();
        }
    }
}
