<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\AgentFuelWallet;
use App\Models\AgentPreference;
use App\Models\AiUsageEvent;
use App\Models\GuestProfile;
use App\Models\Vehicle;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class AgentProfileService
{
    public function __construct(private readonly GuestSkillProfileService $skills) {}

    public function preferences(GuestProfile $profile): AgentPreference
    {
        return AgentPreference::query()->firstOrCreate(
            ['guest_profile_id' => $profile->id],
            [
                'simplicity' => 3,
                'verbosity' => 3,
                'directness' => 5,
                'initiative' => 4,
            ],
        );
    }

    public function wallet(GuestProfile $profile): AgentFuelWallet
    {
        $capacity = (int) config('agent.fuel.capacity_ml', 5000);
        $starting = (int) config('agent.fuel.starting_balance_ml', 5000);

        return AgentFuelWallet::query()->firstOrCreate(
            ['guest_profile_id' => $profile->id],
            [
                'balance_ml' => $starting,
                'capacity_ml' => $capacity,
                'currency' => (string) config('agent.pricing.currency', 'BYN'),
            ],
        );
    }

    /**
     * @param  array{
     *     simplicity?: int,
     *     verbosity?: int,
     *     directness?: int,
     *     initiative?: int,
     *     custom_instructions?: string|null
     * }  $data
     */
    public function updatePreferences(GuestProfile $profile, array $data): AgentPreference
    {
        $prefs = $this->preferences($profile);
        $payload = [];
        foreach (['simplicity', 'verbosity', 'directness', 'initiative'] as $key) {
            if (array_key_exists($key, $data)) {
                $payload[$key] = max(0, min(10, (int) $data[$key]));
            }
        }
        if (array_key_exists('custom_instructions', $data)) {
            $text = $data['custom_instructions'];
            if ($text === null || (is_string($text) && trim($text) === '')) {
                $payload['custom_instructions'] = null;
            } else {
                $payload['custom_instructions'] = mb_substr(trim((string) $text), 0, 800);
            }
        }
        if ($payload !== []) {
            $prefs->forceFill($payload)->save();
        }

        return $prefs->fresh();
    }

    public function assertHasFuel(GuestProfile $profile): void
    {
        $wallet = $this->wallet($profile);
        if ((int) $wallet->balance_ml <= 0) {
            throw new ApiException(
                'AGENT_FUEL_EMPTY',
                __('api.errors.agent_fuel_empty'),
                402,
            );
        }
    }

    /**
     * @param  array{
     *     prompt_tokens?: ?int,
     *     completion_tokens?: ?int,
     *     total_tokens?: ?int,
     *     provider?: ?string,
     *     model?: ?string
     * }  $usage
     */
    public function recordUsage(
        GuestProfile $profile,
        string $source,
        array $usage,
        ?Vehicle $vehicle = null,
        ?string $proxyHint = null,
    ): AiUsageEvent {
        $prompt = isset($usage['prompt_tokens']) && is_numeric($usage['prompt_tokens'])
            ? max(0, (int) $usage['prompt_tokens'])
            : null;
        $completion = isset($usage['completion_tokens']) && is_numeric($usage['completion_tokens'])
            ? max(0, (int) $usage['completion_tokens'])
            : null;
        $total = isset($usage['total_tokens']) && is_numeric($usage['total_tokens'])
            ? max(0, (int) $usage['total_tokens'])
            : (($prompt !== null || $completion !== null)
                ? (int) (($prompt ?? 0) + ($completion ?? 0))
                : null);

        $estimated = $total === null;
        $currency = (string) config('agent.pricing.currency', 'BYN');

        if ($estimated) {
            $fuelMl = max(
                (int) config('agent.fuel.min_charge_ml', 20),
                (int) config('agent.fuel.ml_per_user_message_proxy', 80),
            );
            $cost = (float) config('agent.pricing.cost_per_proxy_message', 0.02);
        } else {
            $per1k = (float) config('agent.fuel.ml_per_1k_tokens', 40);
            $fuelMl = max(
                (int) config('agent.fuel.min_charge_ml', 20),
                (int) round(($total / 1000) * $per1k),
            );
            $cost = (($prompt ?? 0) / 1000) * (float) config('agent.pricing.cost_per_1k_prompt_tokens', 0.004)
                + (($completion ?? 0) / 1000) * (float) config('agent.pricing.cost_per_1k_completion_tokens', 0.012);
        }

        return DB::transaction(function () use (
            $profile,
            $source,
            $vehicle,
            $usage,
            $prompt,
            $completion,
            $total,
            $fuelMl,
            $cost,
            $currency,
            $estimated,
            $proxyHint,
        ): AiUsageEvent {
            $wallet = AgentFuelWallet::query()
                ->where('guest_profile_id', $profile->id)
                ->lockForUpdate()
                ->first();
            if ($wallet === null) {
                $wallet = $this->wallet($profile);
                $wallet = AgentFuelWallet::query()
                    ->whereKey($wallet->id)
                    ->lockForUpdate()
                    ->firstOrFail();
            }

            $charged = min($fuelMl, (int) $wallet->balance_ml);
            $wallet->forceFill([
                'balance_ml' => max(0, (int) $wallet->balance_ml - $charged),
                'lifetime_consumed_ml' => (int) $wallet->lifetime_consumed_ml + $charged,
                'lifetime_prompt_tokens' => (int) $wallet->lifetime_prompt_tokens + ($prompt ?? 0),
                'lifetime_completion_tokens' => (int) $wallet->lifetime_completion_tokens + ($completion ?? 0),
                'lifetime_estimated_cost' => round((float) $wallet->lifetime_estimated_cost + $cost, 6),
                'currency' => $currency,
            ])->save();

            return AiUsageEvent::query()->create([
                'guest_profile_id' => $profile->id,
                'vehicle_id' => $vehicle?->id,
                'source' => $source,
                'provider' => is_string($usage['provider'] ?? null) ? $usage['provider'] : null,
                'model' => is_string($usage['model'] ?? null) ? $usage['model'] : ($proxyHint),
                'prompt_tokens' => $prompt,
                'completion_tokens' => $completion,
                'total_tokens' => $total,
                'fuel_ml' => $charged,
                'estimated_cost' => round($cost, 6),
                'currency' => $currency,
                'tokens_estimated' => $estimated,
            ]);
        });
    }

    /**
     * Stub refuel — grants package without payment.
     */
    public function refuelStub(GuestProfile $profile, int $packageMl): AgentFuelWallet
    {
        $allowed = array_map('intval', config('agent.fuel.refuel_stub_packages_ml', [2000, 5000, 10000]));
        if (! in_array($packageMl, $allowed, true)) {
            throw new ApiException(
                'VALIDATION_FAILED',
                __('api.errors.validation_failed'),
                422,
            );
        }

        return DB::transaction(function () use ($profile, $packageMl): AgentFuelWallet {
            $wallet = AgentFuelWallet::query()
                ->where('guest_profile_id', $profile->id)
                ->lockForUpdate()
                ->first();
            if ($wallet === null) {
                $wallet = $this->wallet($profile);
                $wallet = AgentFuelWallet::query()
                    ->whereKey($wallet->id)
                    ->lockForUpdate()
                    ->firstOrFail();
            }

            // Absolute wallet: purchases stack without a hard "full" cap.
            $newBalance = (int) $wallet->balance_ml + $packageMl;

            $wallet->forceFill([
                'balance_ml' => $newBalance,
                'capacity_ml' => max((int) $wallet->capacity_ml, $newBalance),
            ])->save();

            AiUsageEvent::query()->create([
                'guest_profile_id' => $profile->id,
                'source' => AiUsageEvent::SOURCE_REFUEL,
                'fuel_ml' => $packageMl,
                'estimated_cost' => 0,
                'currency' => $wallet->currency,
                'tokens_estimated' => false,
            ]);

            return $wallet->fresh();
        });
    }

    /**
     * @return array<string, mixed>
     */
    public function profilePayload(GuestProfile $profile, ?Vehicle $vehicle = null): array
    {
        $prefs = $this->preferences($profile);
        $wallet = $this->wallet($profile);
        $usage = $this->usageSummary($profile);
        $balance = (int) $wallet->balance_ml;
        $approxReplies = max(0, (int) floor(
            $balance / max(1, (int) config('agent.fuel.ml_per_user_message_proxy', 80)),
        ));
        $lowBalance = (int) config('agent.fuel.low_balance_ml', 400);
        $lowReplies = (int) config('agent.fuel.low_approx_replies', 5);
        $status = match (true) {
            $balance <= 0 => 'empty',
            $balance <= $lowBalance || $approxReplies <= $lowReplies => 'low',
            default => 'ok',
        };

        $userNotes = $profile->aiNotes()
            ->orderByDesc('created_at')
            ->limit(40)
            ->get(['id', 'body', 'source', 'created_at']);

        $vehicleNotes = [];
        if ($vehicle !== null) {
            $vehicleNotes = $vehicle->aiNotes()
                ->orderByDesc('created_at')
                ->limit(40)
                ->get(['id', 'body', 'source', 'created_at'])
                ->map(fn ($n) => [
                    'id' => $n->id,
                    'body' => $n->body,
                    'source' => $n->source,
                    'created_at' => $n->created_at?->toIso8601String(),
                ])
                ->values()
                ->all();
        }

        return [
            'preferences' => $this->preferencesToArray($prefs),
            'skill' => $this->skills->toArray($this->skills->forProfile($profile)),
            'fuel' => [
                'balance_ml' => $balance,
                'capacity_ml' => (int) $wallet->capacity_ml,
                'percent' => $wallet->percentFull(), // legacy; UI uses absolute balance
                'lifetime_consumed_ml' => (int) $wallet->lifetime_consumed_ml,
                'approx_replies_left' => $approxReplies,
                'typical_spend_ml' => (int) config('agent.fuel.ml_per_user_message_proxy', 80),
                'status' => $status,
                'low_balance_ml' => $lowBalance,
                'currency' => $wallet->currency,
                'lifetime_estimated_cost' => round((float) $wallet->lifetime_estimated_cost, 4),
                'lifetime_prompt_tokens' => (int) $wallet->lifetime_prompt_tokens,
                'lifetime_completion_tokens' => (int) $wallet->lifetime_completion_tokens,
            ],
            'usage' => $usage,
            'refuel_packages' => array_map(
                fn (int $ml): array => [
                    'ml' => $ml,
                    'label' => '+'.$ml.' ток.',
                    'payment_available' => false,
                ],
                array_map('intval', config('agent.fuel.refuel_stub_packages_ml', [2000, 5000, 10000])),
            ),
            'notes' => [
                'user' => $userNotes->map(fn ($n) => [
                    'id' => $n->id,
                    'body' => $n->body,
                    'source' => $n->source,
                    'created_at' => $n->created_at?->toIso8601String(),
                ])->values()->all(),
                'vehicle' => $vehicleNotes,
            ],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function preferencesToArray(AgentPreference $prefs): array
    {
        return [
            'simplicity' => (int) $prefs->simplicity,
            'verbosity' => (int) $prefs->verbosity,
            'directness' => (int) $prefs->directness,
            'initiative' => (int) $prefs->initiative,
            'custom_instructions' => $prefs->custom_instructions,
        ];
    }

    /**
     * @return array{
     *     today: array<string, mixed>,
     *     last_7_days: array<string, mixed>,
     *     all_time: array<string, mixed>,
     *     daily: list<array{date: string, spent_ml: int, refueled_ml: int}>
     * }
     */
    private function usageSummary(GuestProfile $profile): array
    {
        $spendSources = [
            AiUsageEvent::SOURCE_CHAT,
            AiUsageEvent::SOURCE_MEMORY,
            AiUsageEvent::SOURCE_TITLE,
        ];

        $aggregate = function (Carbon $from) use ($profile, $spendSources): array {
            $q = AiUsageEvent::query()
                ->where('guest_profile_id', $profile->id)
                ->whereIn('source', $spendSources);
            if ($from->timestamp > 0) {
                $q->where('created_at', '>=', $from);
            }
            $rows = $q->get(['fuel_ml', 'prompt_tokens', 'completion_tokens', 'estimated_cost', 'tokens_estimated']);

            return [
                'fuel_ml' => (int) $rows->sum('fuel_ml'),
                'prompt_tokens' => (int) $rows->sum(fn ($r) => (int) ($r->prompt_tokens ?? 0)),
                'completion_tokens' => (int) $rows->sum(fn ($r) => (int) ($r->completion_tokens ?? 0)),
                'estimated_cost' => round((float) $rows->sum('estimated_cost'), 4),
                'events' => $rows->count(),
                'tokens_are_estimates' => $rows->contains(fn ($r) => (bool) $r->tokens_estimated)
                    || $rows->every(fn ($r) => $r->prompt_tokens === null && $r->completion_tokens === null),
            ];
        };

        $wallet = $this->wallet($profile);
        $from = now()->subDays(6)->startOfDay();
        $events = AiUsageEvent::query()
            ->where('guest_profile_id', $profile->id)
            ->where('created_at', '>=', $from)
            ->get(['source', 'fuel_ml', 'created_at']);

        $daily = [];
        for ($i = 6; $i >= 0; $i--) {
            $day = now()->subDays($i)->startOfDay();
            $key = $day->toDateString();
            $dayEvents = $events->filter(
                fn ($e) => $e->created_at !== null && $e->created_at->toDateString() === $key,
            );
            $spent = (int) $dayEvents
                ->filter(fn ($e) => in_array($e->source, $spendSources, true))
                ->sum('fuel_ml');
            $refueled = (int) $dayEvents
                ->filter(fn ($e) => $e->source === AiUsageEvent::SOURCE_REFUEL)
                ->sum('fuel_ml');
            $daily[] = [
                'date' => $key,
                'spent_ml' => $spent,
                'refueled_ml' => $refueled,
            ];
        }

        return [
            'today' => $aggregate(now()->startOfDay()),
            'last_7_days' => $aggregate(now()->subDays(7)->startOfDay()),
            'all_time' => [
                'fuel_ml' => (int) $wallet->lifetime_consumed_ml,
                'prompt_tokens' => (int) $wallet->lifetime_prompt_tokens,
                'completion_tokens' => (int) $wallet->lifetime_completion_tokens,
                'estimated_cost' => round((float) $wallet->lifetime_estimated_cost, 4),
                'events' => AiUsageEvent::query()
                    ->where('guest_profile_id', $profile->id)
                    ->whereIn('source', $spendSources)
                    ->count(),
                'tokens_are_estimates' => false,
            ],
            'daily' => $daily,
        ];
    }
}
