<?php

namespace App\Services\Monetization;

use App\Models\MileageObservation;
use App\Models\Vehicle;
use App\Services\Firebase\FirebaseRemoteConfigClient;
use Illuminate\Support\Facades\Log;

class MonetizationCatalogService
{
    public function __construct(
        private readonly FirebaseRemoteConfigClient $remoteConfig,
    ) {}

    /**
     * Top-up sheet payload for Telegram Mini App.
     *
     * @return array<string, mixed>
     */
    public function topupCatalog(?Vehicle $vehicle = null): array
    {
        $config = $this->resolvedConfig();
        $mileage = $this->mileageBonusState($vehicle, $config);
        $packs = collect($config['packs'] ?? [])
            ->filter(fn ($pack): bool => is_array($pack) && ($pack['enabled'] ?? true))
            ->sortBy(fn (array $pack): int => (int) ($pack['sort_order'] ?? 100))
            ->values();

        $options = [];
        foreach ($packs as $pack) {
            $type = (string) ($pack['type'] ?? 'stars');
            if ($type === 'mileage') {
                $options[] = [
                    'key' => (string) ($pack['key'] ?? 'mileage'),
                    'icon' => (string) ($pack['icon'] ?? '🛣️'),
                    'title' => (string) ($pack['title'] ?? 'Обновить пробег'),
                    'subtitle' => $mileage['subtitle'],
                    'tokens_label' => $mileage['reward_label'],
                    'price_label' => $this->starsLabel($pack['stars_price'] ?? 0),
                    'badge' => $mileage['badge'],
                    'enabled' => $mileage['can_open'],
                    'action' => 'mileage',
                    'tokens_amount' => $mileage['reward_tokens'],
                    'stars_price' => (int) ($pack['stars_price'] ?? 0),
                ];

                continue;
            }

            $options[] = [
                'key' => (string) ($pack['key'] ?? $type),
                'icon' => (string) ($pack['icon'] ?? ($type === 'stars' ? '⭐' : '⚡')),
                'title' => (string) ($pack['title'] ?? 'Пакет'),
                'subtitle' => (string) ($pack['subtitle'] ?? ''),
                'tokens_label' => $this->tokensLabel($pack['tokens_amount'] ?? null, $type),
                'price_label' => $this->starsLabel($pack['stars_price'] ?? null),
                'badge' => isset($pack['badge']) && is_string($pack['badge']) ? $pack['badge'] : null,
                'enabled' => true,
                'action' => 'soon',
                'tokens_amount' => is_numeric($pack['tokens_amount'] ?? null) ? (int) $pack['tokens_amount'] : null,
                'stars_price' => is_numeric($pack['stars_price'] ?? null) ? (int) $pack['stars_price'] : null,
            ];
        }

        return [
            'button_label' => (string) ($config['button_label'] ?? 'Добавить токены'),
            'button_sub' => (string) ($config['button_sub'] ?? 'Stars или бонус за пробег'),
            'sheet_title' => (string) ($config['sheet_title'] ?? 'Как получить токены'),
            'sheet_intro' => (string) ($config['sheet_intro'] ?? ''),
            'soon_toast' => (string) ($config['soon_toast'] ?? 'Этот способ скоро подключим'),
            'mileage' => $mileage,
            'source' => $config['_source'] ?? 'defaults',
            'options' => $options,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function resolvedConfig(): array
    {
        $defaults = $this->defaultConfig();
        $key = (string) config('firebase.monetization_key', 'monetization_v1');
        $raw = $this->remoteConfig->getParameterString($key);
        if ($raw === null) {
            return [...$defaults, '_source' => 'defaults'];
        }

        try {
            $decoded = json_decode($raw, true, 512, JSON_THROW_ON_ERROR);
        } catch (\JsonException $e) {
            Log::warning('Invalid monetization Remote Config JSON: '.$e->getMessage());

            return [...$defaults, '_source' => 'defaults_invalid_json'];
        }

        if (! is_array($decoded) || ! isset($decoded['packs']) || ! is_array($decoded['packs'])) {
            return [...$defaults, '_source' => 'defaults_invalid_shape'];
        }

        return [
            ...$defaults,
            ...$decoded,
            'packs' => array_values(array_filter($decoded['packs'], 'is_array')),
            '_source' => 'firebase',
        ];
    }

    /**
     * @param  array<string, mixed>  $config
     * @return array<string, mixed>
     */
    public function mileageBonusState(?Vehicle $vehicle, ?array $config = null): array
    {
        $config ??= $this->resolvedConfig();
        $mileagePack = collect($config['packs'] ?? [])
            ->first(fn ($pack): bool => is_array($pack) && ($pack['type'] ?? '') === 'mileage');

        $reward = (int) (is_array($mileagePack) ? ($mileagePack['tokens_amount'] ?? 500) : 500);
        $cooldownHours = (int) (is_array($mileagePack) ? ($mileagePack['cooldown_hours'] ?? 24) : 24);
        if ($cooldownHours < 1) {
            $cooldownHours = 24;
        }

        $base = [
            'reward_tokens' => $reward,
            'reward_label' => $this->tokensLabel($reward, 'mileage') ?? '+'.$reward,
            'cooldown_hours' => $cooldownHours,
            'available' => false,
            'can_open' => false,
            'badge' => 'нет авто',
            'subtitle' => 'Сначала добавьте автомобиль — потом можно обновлять пробег и получать бонус.',
            'available_label' => null,
            'cooldown_ends_at' => null,
            'current_value' => null,
            'unit' => 'km',
        ];

        if ($vehicle === null) {
            return $base;
        }

        $vehicle->loadMissing('mileageObservations');

        $lastUserUpdate = $vehicle->mileageObservations
            ->filter(fn (MileageObservation $row): bool => ($row->source ?? '') !== 'service')
            ->sortByDesc(fn (MileageObservation $row) => $row->observed_at?->timestamp ?? $row->created_at?->timestamp ?? 0)
            ->first();

        $lastAt = $lastUserUpdate?->observed_at ?? $lastUserUpdate?->created_at;
        $cooldownEnds = $lastAt?->copy()->addHours($cooldownHours);
        $available = $cooldownEnds === null || $cooldownEnds->isPast();
        $hoursLeft = (! $available && $cooldownEnds !== null)
            ? max(1, (int) ceil(now()->diffInMinutes($cooldownEnds) / 60))
            : null;

        return [
            'reward_tokens' => $reward,
            'reward_label' => $this->tokensLabel($reward, 'mileage') ?? '+'.$reward,
            'cooldown_hours' => $cooldownHours,
            'available' => $available,
            'can_open' => true,
            'badge' => $available ? '0 ⭐' : ('через '.$hoursLeft.' ч'),
            'subtitle' => $available
                ? 'Введите актуальный пробег. Небольшой бонус раз в '.$cooldownHours.' ч — без Stars.'
                : 'Пробег можно обновить сейчас, а бонус токенов снова через '.$hoursLeft.' ч.',
            'available_label' => $available
                ? 'бонус доступен'
                : ('бонус через '.$hoursLeft.' ч'),
            'cooldown_ends_at' => $cooldownEnds?->toIso8601String(),
            'current_value' => $vehicle->current_mileage,
            'unit' => $vehicle->mileage_unit ?? 'km',
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function defaultConfig(): array
    {
        $path = resource_path('firebase/monetization_v1.example.json');
        if (is_file($path)) {
            $decoded = json_decode((string) file_get_contents($path), true);
            if (is_array($decoded)) {
                return $decoded;
            }
        }

        return [
            'version' => 1,
            'button_label' => 'Добавить токены',
            'button_sub' => 'Stars или бонус за пробег',
            'sheet_title' => 'Как получить токены',
            'sheet_intro' => '',
            'soon_toast' => 'Этот способ скоро подключим',
            'packs' => [],
        ];
    }

    private function tokensLabel(mixed $amount, string $type): ?string
    {
        if ($amount === null || $amount === '') {
            return $type === 'invite' ? '+бонус' : null;
        }
        if (! is_numeric($amount)) {
            return null;
        }

        return '+'.number_format((int) $amount, 0, '', ' ');
    }

    private function starsLabel(mixed $price): string
    {
        if ($price === null || $price === '') {
            return 'скоро';
        }
        $value = (int) $price;
        if ($value === 0) {
            return '0 ⭐';
        }

        return $value.' ⭐';
    }
}
