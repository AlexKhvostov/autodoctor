<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ConditionObservation;
use App\Models\HistoryAnswer;
use App\Models\MaintenancePlanSnapshot;
use App\Models\MaintenanceRule;
use App\Models\RulesetVersion;
use App\Models\Vehicle;
use Carbon\CarbonImmutable;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class PlanCalculator
{
    public const ALGORITHM_VERSION = 'maintenance-v3';

    public function calculate(Vehicle $vehicle, ?CarbonImmutable $asOf = null): MaintenancePlanSnapshot
    {
        return DB::transaction(function () use ($vehicle, $asOf): MaintenancePlanSnapshot {
            $vehicle = Vehicle::query()
                ->with([
                    'configuration',
                    'historyAnswers.workCatalogItem',
                    'serviceRecords.items.workCatalogItem',
                    'conditionObservations.workCatalogItem',
                ])
                ->lockForUpdate()
                ->findOrFail($vehicle->id);
            $ruleset = $this->publishedRuleset();
            $asOf ??= CarbonImmutable::today();
            $input = $this->inputSnapshot($vehicle, $asOf);
            $inputHash = $this->hash($input);
            $configVersion = (string) config('maintenance.config_version');

            $existing = MaintenancePlanSnapshot::query()
                ->where('vehicle_id', $vehicle->id)
                ->where('ruleset_version_id', $ruleset->id)
                ->where('algorithm_version', self::ALGORITHM_VERSION)
                ->where('config_version', $configVersion)
                ->where('input_hash', $inputHash)
                ->first();

            if ($existing !== null) {
                return $this->load($existing);
            }

            $rules = $this->applicableRules($ruleset, $vehicle);
            $answers = $this->effectiveAnswers($vehicle);
            $observations = $this->latestConditionObservations($vehicle);
            $items = $rules->map(fn (MaintenanceRule $rule): array => $this->evaluate(
                $rule,
                $answers->get($rule->work_code),
                $observations->get($rule->work_code),
                $vehicle,
                $asOf,
            ));
            $warnings = ['EDITORIAL_BASELINE_ONLY'];
            if ($items->contains(fn (array $item): bool => $item['history_state']['answer'] !== 'done_known'
                && $item['status'] !== 'not_applicable')) {
                $warnings[] = 'HISTORY_REQUIRED';
            }
            if ($vehicle->current_mileage === null) {
                $warnings[] = 'MILEAGE_NOT_PROVIDED';
            }

            $content = [
                'algorithm_version' => self::ALGORITHM_VERSION,
                'config_version' => $configVersion,
                'input_hash' => $inputHash,
                'ruleset_content_hash' => $ruleset->content_hash,
                'warnings' => $warnings,
                'items' => $items->values()->all(),
            ];
            $snapshot = MaintenancePlanSnapshot::query()->create([
                'vehicle_id' => $vehicle->id,
                'ruleset_version_id' => $ruleset->id,
                'algorithm_version' => self::ALGORITHM_VERSION,
                'config_version' => $configVersion,
                'input_snapshot' => $input,
                'input_hash' => $inputHash,
                'content_hash' => $this->hash($content),
                'warnings' => $warnings,
                'calculated_at' => now(),
            ]);

            foreach ($items as $item) {
                $snapshot->items()->create([
                    'rule_id' => $item['rule_id'],
                    'status' => $item['status'],
                    'urgency' => $item['urgency'],
                    'due_mileage_km' => $item['due_mileage_km'],
                    'due_date' => $item['due_date'],
                    'interval_metadata' => [
                        'mileage_km' => $item['interval']['mileage_km'],
                        'days' => $item['interval']['days'],
                    ],
                    'warnings' => $item['requires_check_now'] ? ['HISTORY_REQUIRED'] : [],
                    'explanation' => [
                        'requires_check_now' => $item['requires_check_now'],
                        'history_state' => $item['history_state'],
                        'inspection_state' => $item['inspection_state'],
                        'latest_observation' => $item['latest_observation'],
                        'condition_thresholds' => $item['condition_thresholds'],
                        'wear_derived_state' => $item['wear_derived_state'],
                        'time_used_fraction' => $item['time_used_fraction'],
                        'mileage_used_fraction' => $item['mileage_used_fraction'],
                        'effective_used_fraction' => $item['effective_used_fraction'],
                        'effective_trigger' => $item['effective_trigger'],
                        'derived_state' => $item['derived_state'],
                    ],
                ]);
            }

            return $this->load($snapshot);
        });
    }

    public function latest(Vehicle $vehicle): MaintenancePlanSnapshot
    {
        return $this->calculate($vehicle);
    }

    public function applicableWorkCodes(Vehicle $vehicle): Collection
    {
        $vehicle->loadMissing('configuration');

        return $this->applicableRules($this->publishedRuleset(), $vehicle)->pluck('work_code');
    }

    private function evaluate(
        MaintenanceRule $rule,
        ?HistoryAnswer $answer,
        ?ConditionObservation $observation,
        Vehicle $vehicle,
        CarbonImmutable $asOf,
    ): array {
        $answerValue = $answer?->answer;
        $historyState = [
            'answer' => $answerValue,
            'performed_date' => $answer?->performed_date?->format('Y-m-d'),
            'performed_mileage_km' => $answer?->performed_mileage_km,
        ];
        $unresolved = $answerValue !== 'done_known' && $answerValue !== 'not_applicable';
        $status = $answerValue === 'not_applicable' ? 'not_applicable' : ($unresolved ? 'unknown' : 'current');
        $dueDate = null;
        $dueMileage = null;
        $timeFraction = null;
        $mileageFraction = null;
        $inspectionState = null;
        $effectiveFraction = null;
        $effectiveTrigger = 'unknown';
        $conditionThresholds = config('maintenance.condition_wear_thresholds.'.$rule->work_code);
        $wearDerivedState = null;

        if ($rule->rule_kind === 'condition_based') {
            if ($observation !== null && is_array($conditionThresholds)) {
                $wear = $observation->wear_percent;
                $wearDerivedState = $wear >= $conditionThresholds['action_percent']
                    ? 'danger'
                    : ($wear >= $conditionThresholds['warning_percent'] ? 'warning' : 'normal');
                $status = match ($wearDerivedState) {
                    'danger' => 'overdue',
                    'warning' => 'soon',
                    default => 'current',
                };
                $unresolved = false;
                $inspectionState = 'completed';
            } else {
                $inspectionState = match ($answerValue) {
                    'done_known' => 'completed',
                    'not_applicable' => 'unknown',
                    default => 'check_required',
                };
            }
        } elseif ($answerValue === 'done_known') {
            if ($answer?->performed_date !== null && $rule->time_interval_days !== null) {
                $elapsedDays = max(0, $answer->performed_date->diffInDays($asOf, false));
                $timeFraction = $elapsedDays / $rule->time_interval_days;
                $dueDate = $answer->performed_date->addDays($rule->time_interval_days)->format('Y-m-d');
            }
            $currentMileage = $this->mileageKm($vehicle);
            if ($answer?->performed_mileage_km !== null && $rule->mileage_interval_km !== null) {
                $dueMileage = $answer->performed_mileage_km + $rule->mileage_interval_km;
                if ($currentMileage !== null) {
                    $mileageFraction = max(0, $currentMileage - $answer->performed_mileage_km)
                        / $rule->mileage_interval_km;
                }
            }

            $available = array_filter([
                'time' => $timeFraction,
                'mileage' => $mileageFraction,
            ], fn ($value): bool => $value !== null);
            if ($available !== []) {
                $effectiveFraction = max($available);
                $triggers = array_keys(array_filter(
                    $available,
                    fn ($value): bool => abs($value - $effectiveFraction) < 0.0000001,
                ));
                $effectiveTrigger = count($triggers) === 2 ? 'both' : $triggers[0];
            }

            $overdue = ($timeFraction !== null && $timeFraction >= 1)
                || ($mileageFraction !== null && $mileageFraction >= 1);
            $soon = ! $overdue && (
                ($dueDate !== null && $asOf->diffInDays(CarbonImmutable::parse($dueDate), false)
                    <= (int) config('maintenance.soon_threshold.days'))
                || ($dueMileage !== null && $currentMileage !== null
                    && $dueMileage - $currentMileage <= (int) config('maintenance.soon_threshold.mileage_km'))
            );
            $status = $overdue ? 'overdue' : ($soon ? 'soon' : 'current');
        }

        $requiresCheckNow = $unresolved;
        $urgency = $wearDerivedState === 'danger' && $rule->criticality === 'safety_critical'
            ? 'immediate'
            : $this->urgency($status, $rule->criticality, $requiresCheckNow);

        return [
            'work_code' => $rule->work_code,
            'rule_id' => $rule->id,
            'rule_version' => $rule->version,
            'status' => $status,
            'urgency' => $urgency,
            'due_mileage_km' => $dueMileage,
            'due_date' => $dueDate,
            'interval' => [
                'mileage_km' => $rule->mileage_interval_km,
                'days' => $rule->time_interval_days,
            ],
            'requires_check_now' => $requiresCheckNow,
            'history_state' => $historyState,
            'inspection_state' => $inspectionState,
            'latest_observation' => $observation === null ? null : [
                'id' => $observation->id,
                'vehicle_id' => $observation->vehicle_id,
                'work_code' => $rule->work_code,
                'wear_percent' => $observation->wear_percent,
                'remaining_percent' => 100 - $observation->wear_percent,
                'observed_at' => $observation->observed_at->format('Y-m-d'),
                'mileage' => $observation->mileage_value === null ? null : [
                    'value' => $observation->mileage_value,
                    'unit' => $observation->mileage_unit,
                ],
                'source' => $observation->source,
                'note' => $observation->note,
                'created_at' => $observation->created_at->toISOString(),
            ],
            'condition_thresholds' => is_array($conditionThresholds) ? [
                ...$conditionThresholds,
                'provenance' => 'autodoctor_editorial',
            ] : null,
            'wear_derived_state' => $wearDerivedState,
            'time_used_fraction' => $timeFraction,
            'mileage_used_fraction' => $mileageFraction,
            'effective_used_fraction' => $effectiveFraction,
            'effective_trigger' => $effectiveTrigger,
            'derived_state' => $wearDerivedState ?? match ($status) {
                'overdue' => 'danger',
                'soon' => 'warning',
                'current' => 'normal',
                default => 'unknown',
            },
        ];
    }

    private function urgency(string $status, string $criticality, bool $requiresCheckNow): string
    {
        if ($criticality === 'safety_critical' && ($requiresCheckNow || $status === 'overdue')) {
            return 'immediate';
        }

        return match ($status) {
            'overdue' => 'high',
            'soon' => 'medium',
            default => $requiresCheckNow && $criticality === 'high' ? 'high' : 'none',
        };
    }

    private function publishedRuleset(): RulesetVersion
    {
        $ruleset = RulesetVersion::query()
            ->where('version', config('maintenance.ruleset_version'))
            ->whereNotNull('published_at')
            ->whereHas('rules', fn ($query) => $query
                ->whereHas('source', fn ($source) => $source->where('publication_status', 'published')))
            ->first();

        if ($ruleset === null || $ruleset->rules()->count() !== 13) {
            throw new ApiException('PLAN_PREPARING', __('api.errors.plan_preparing'), 409);
        }

        return $ruleset;
    }

    private function applicableRules(RulesetVersion $ruleset, Vehicle $vehicle): Collection
    {
        $fuelType = $vehicle->configuration->fuel_type;

        return $ruleset->rules()
            ->with(['source', 'workCatalogItem'])
            ->orderBy('work_code')
            ->get()
            ->filter(function (MaintenanceRule $rule) use ($fuelType, $vehicle): bool {
                if ($vehicle->plan_eligibility !== 'specific_oem_allowed' && $rule->rule_level === 'specific') {
                    return false;
                }

                return in_array($fuelType, $rule->applicability['fuel_types'] ?? [], true);
            })
            ->values();
    }

    private function inputSnapshot(Vehicle $vehicle, CarbonImmutable $asOf): array
    {
        $configuration = $vehicle->configuration;

        return [
            'vehicle' => [
                'make' => $configuration->make,
                'model' => $configuration->model,
                'generation' => $configuration->generation,
                'production_year' => $vehicle->production_year,
                'first_use_date' => $vehicle->first_use_date?->format('Y-m-d'),
                'fuel_type' => $configuration->fuel_type,
                'engine' => [
                    'displacement_cc' => $configuration->engine_displacement_cc,
                    'engine_code' => $configuration->engine_code,
                    'power_kw' => $configuration->engine_power_kw === null ? null : (float) $configuration->engine_power_kw,
                ],
                'transmission' => [
                    'type' => $configuration->transmission_type,
                    'gears' => $configuration->transmission_gears,
                ],
                'drivetrain' => $configuration->drivetrain,
                'market' => $configuration->market,
                'profile_status' => $vehicle->profile_status,
                'recommendation_scope' => $vehicle->plan_eligibility,
                'mileage_base_km' => $this->mileageKm($vehicle),
            ],
            'service_history' => $vehicle->serviceRecords
                ->sortBy(fn ($record): string => $record->service_date->format('Y-m-d').'|'.$record->id)
                ->map(fn ($record): array => [
                    'id' => $record->id,
                    'service_date' => $record->service_date->format('Y-m-d'),
                    'mileage' => $record->mileage_value === null ? null : [
                        'value' => $record->mileage_value,
                        'unit' => $record->mileage_unit,
                        'value_km' => (int) round($record->mileage_unit === 'mi'
                            ? $record->mileage_value * 1.609344
                            : $record->mileage_value),
                    ],
                    'evidence_source' => $record->evidence_source,
                    'note' => $record->note,
                    'work_codes' => $record->items
                        ->pluck('workCatalogItem.code')
                        ->sort()
                        ->values()
                        ->all(),
                    'version' => $record->version,
                ])->values()->all(),
            'history_answers' => $vehicle->historyAnswers
                ->sortBy('workCatalogItem.code')
                ->map(fn (HistoryAnswer $answer): array => [
                    'work_code' => $answer->workCatalogItem->code,
                    'answer' => $answer->answer,
                    'performed_date' => $answer->performed_date?->format('Y-m-d'),
                    'performed_mileage_km' => $answer->performed_mileage_km,
                    'version' => $answer->version,
                ])->values()->all(),
            'condition_observations' => $this->latestConditionObservations($vehicle)
                ->sortKeys()
                ->map(fn (ConditionObservation $observation): array => [
                    'id' => $observation->id,
                    'work_code' => $observation->workCatalogItem->code,
                    'wear_percent' => $observation->wear_percent,
                    'observed_at' => $observation->observed_at->format('Y-m-d'),
                    'mileage' => $observation->mileage_value === null ? null : [
                        'value' => $observation->mileage_value,
                        'unit' => $observation->mileage_unit,
                    ],
                    'source' => $observation->source,
                    'note' => $observation->note,
                ])->values()->all(),
            'operating_conditions' => null,
            'season' => null,
            'as_of_date' => $asOf->format('Y-m-d'),
        ];
    }

    private function effectiveAnswers(Vehicle $vehicle): Collection
    {
        $answers = $vehicle->historyAnswers->keyBy('workCatalogItem.code');
        foreach ($vehicle->serviceRecords
            ->sortBy(fn ($record): string => $record->service_date->format('Y-m-d').'|'.$record->id) as $record) {
            foreach ($record->items as $item) {
                $fact = new HistoryAnswer([
                    'answer' => 'done_known',
                    'performed_date' => $record->service_date,
                    'performed_mileage_km' => $record->mileage_value === null
                        ? null
                        : (int) round($record->mileage_unit === 'mi'
                            ? $record->mileage_value * 1.609344
                            : $record->mileage_value),
                    'version' => $record->version,
                ]);
                $fact->setRelation('workCatalogItem', $item->workCatalogItem);
                $answers->put($item->workCatalogItem->code, $fact);
            }
        }

        return $answers;
    }

    private function latestConditionObservations(Vehicle $vehicle): Collection
    {
        return $vehicle->conditionObservations
            ->sortByDesc(fn (ConditionObservation $item): string => sprintf(
                '%s|%s|%s',
                $item->observed_at->format('Y-m-d'),
                $item->created_at->format('Y-m-d H:i:s.u'),
                $item->id,
            ))
            ->unique('work_catalog_item_id')
            ->keyBy('workCatalogItem.code');
    }

    private function mileageKm(Vehicle $vehicle): ?int
    {
        if ($vehicle->current_mileage === null) {
            return null;
        }

        return $vehicle->mileage_unit === 'mi'
            ? (int) round($vehicle->current_mileage * 1.609344)
            : $vehicle->current_mileage;
    }

    private function hash(array $value): string
    {
        return 'sha256:'.hash('sha256', $this->canonicalJson($value));
    }

    private function canonicalJson(mixed $value): string
    {
        $sort = function (mixed $item) use (&$sort): mixed {
            if (! is_array($item)) {
                return $item;
            }
            if (! array_is_list($item)) {
                ksort($item, SORT_STRING);
            }

            return array_map($sort, $item);
        };

        return json_encode(
            $sort($value),
            JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRESERVE_ZERO_FRACTION,
        );
    }

    private function load(MaintenancePlanSnapshot $snapshot): MaintenancePlanSnapshot
    {
        $snapshot->load([
            'rulesetVersion',
            'items' => fn ($query) => $query->with(['rule.source', 'rule.workCatalogItem'])
                ->orderBy(
                    MaintenanceRule::query()
                        ->select('work_code')
                        ->whereColumn('maintenance_rules.id', 'plan_items.rule_id'),
                ),
        ]);

        $snapshot->setRelation('items', $snapshot->items->sort(function ($left, $right): int {
            $leftKey = $this->sortKey($left);
            $rightKey = $this->sortKey($right);

            return ($leftKey <=> $rightKey)
                ?: ($left->rule->work_code <=> $right->rule->work_code)
                ?: ($left->id <=> $right->id);
        })->values());

        return $snapshot;
    }

    private function sortKey($item): array
    {
        if ($item->status === 'not_applicable') {
            return [3, 0, 0, 0, '9999-12-31', PHP_INT_MAX];
        }
        $unresolved = (bool) ($item->explanation['requires_check_now'] ?? false);
        $criticality = match ($item->rule->criticality) {
            'safety_critical' => 0,
            'high' => 1,
            'medium' => 2,
            default => 3,
        };
        if ($unresolved) {
            return [0, $criticality, 0, 0, '0000-00-00', 0];
        }
        $importance = $this->importance($item);
        $status = match ($item->status) {
            'overdue' => 0,
            'soon' => 1,
            'current' => 2,
            'completed' => 3,
            default => 4,
        };
        $urgency = match ($item->urgency) {
            'immediate' => 0,
            'high' => 1,
            'medium' => 2,
            'low' => 3,
            default => 4,
        };
        $importanceRank = match ($importance) {
            'critical_attention' => 0,
            'required' => 1,
            'recommended' => 2,
            default => 3,
        };

        return [
            1,
            $importance === 'critical_attention' ? 0 : 1,
            $status,
            $urgency * 10 + $importanceRank,
            $item->due_date?->format('Y-m-d') ?? '9999-12-31',
            $item->due_mileage_km ?? PHP_INT_MAX,
        ];
    }

    private function importance($item): string
    {
        if ($item->rule->criticality === 'safety_critical' || $item->urgency === 'immediate') {
            return 'critical_attention';
        }
        if ($item->rule->rule_type === 'regulation') {
            return $item->status === 'overdue' ? 'critical_attention' : 'required';
        }

        return 'recommended';
    }
}
