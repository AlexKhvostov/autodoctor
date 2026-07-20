<?php

namespace Database\Seeders;

use App\Models\MaintenanceRule;
use App\Models\MaintenanceSource;
use App\Models\RulesetVersion;
use App\Models\WorkCatalogItem;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use LogicException;

class MaintenanceV2Seeder extends Seeder
{
    public const RULESET_VERSION = 'by-pilot-baseline-2';

    private const SOURCE_ID = '82e43f85-7db8-5bf7-8901-bf78a7610802';

    private const RULESET_ID = '56f97a38-e168-5ff6-a7c4-a3ff54886ca7';

    public function run(): void
    {
        $definitions = $this->definitions();
        $contentHash = 'sha256:'.hash('sha256', json_encode(
            $definitions,
            JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES,
        ));

        DB::transaction(function () use ($definitions, $contentHash): void {
            $sourceValues = [
                'source_kind' => 'editorial_baseline',
                'title' => 'AutoDoctor Pilot Baseline v2',
                'publisher' => 'AutoDoctor Editorial',
                'document_version' => '2',
                'publication_status' => 'published',
                'methodology_note' => 'Внутренняя редакционная методика AutoDoctor; не руководство и не регламент производителя.',
                'url' => null,
                'official_oem' => false,
                'effective_date' => null,
                'verified_at' => null,
            ];
            $source = MaintenanceSource::query()->firstOrCreate(
                ['id' => self::SOURCE_ID],
                $sourceValues,
            );
            $this->assertImmutable($source, $sourceValues, 'maintenance source v2');

            $ruleset = RulesetVersion::query()->firstOrCreate(
                ['version' => self::RULESET_VERSION],
                [
                    'id' => self::RULESET_ID,
                    'content_hash' => $contentHash,
                    'published_at' => now(),
                ],
            );
            if ($ruleset->id !== self::RULESET_ID || $ruleset->content_hash !== $contentHash) {
                throw new LogicException('Published maintenance ruleset v2 differs from canonical seed.');
            }

            foreach ($definitions as $definition) {
                $catalog = WorkCatalogItem::query()->firstOrCreate(
                    ['code' => $definition['work_code']],
                    [
                        'id' => $definition['catalog_id'],
                        'localized_name' => $definition['title'],
                    ],
                );

                $values = [
                    'id' => $definition['rule_id'],
                    'source_id' => $source->id,
                    'work_catalog_item_id' => $catalog->id,
                    'rule_level' => $definition['rule_level'],
                    'rule_type' => 'recommendation',
                    'rule_kind' => $definition['rule_kind'],
                    'mileage_interval_km' => $definition['mileage_interval_km'],
                    'time_interval_days' => $definition['time_interval_days'],
                    'applicability' => ['fuel_types' => $definition['fuel_types']],
                    'localized_content' => [
                        'title' => $definition['title'],
                        'basis' => $definition['basis'],
                        'history_impact' => $definition['history_impact'],
                    ],
                    'criticality' => $definition['criticality'],
                    'version' => 1,
                ];
                $rule = MaintenanceRule::query()->firstOrCreate(
                    [
                        'ruleset_version_id' => $ruleset->id,
                        'work_code' => $definition['work_code'],
                    ],
                    $values,
                );
                $this->assertImmutable($rule, $values, "maintenance rule {$definition['work_code']}");
            }
        });
    }

    private function definitions(): array
    {
        $all = ['petrol', 'diesel', 'hybrid', 'electric', 'lpg', 'other'];
        $combustion = ['petrol', 'diesel', 'hybrid', 'lpg'];
        $spark = ['petrol', 'hybrid', 'lpg'];
        $unknown = [
            'ru' => 'История неизвестна — рекомендуем проверить/выполнить сейчас.',
            'en' => 'History is unknown — we recommend checking or performing this now.',
        ];

        return [
            $this->rule('engine_oil', 1, 'type_based', 'interval_based', $combustion, 10000, 365, 'medium', ['ru' => 'Моторное масло', 'en' => 'Engine oil'], $this->intervalBasis('10 000 км или 365 дней, что наступит раньше', '10,000 km or 365 days, whichever comes first'), $unknown),
            $this->rule('oil_filter', 2, 'type_based', 'interval_based', $combustion, 10000, 365, 'medium', ['ru' => 'Масляный фильтр', 'en' => 'Oil filter'], $this->intervalBasis('10 000 км или 365 дней, что наступит раньше', '10,000 km or 365 days, whichever comes first'), $unknown),
            $this->rule('cabin_filter', 3, 'universal', 'interval_based', $all, null, 365, 'low', ['ru' => 'Салонный фильтр', 'en' => 'Cabin filter'], $this->intervalBasis('365 дней', '365 days'), $unknown),
            $this->rule('brake_system_inspection', 4, 'universal', 'condition_based', $all, null, null, 'safety_critical', ['ru' => 'Проверка тормозной системы', 'en' => 'Brake system inspection'], $this->conditionBasis('тормозную систему', 'the brake system'), $unknown),
            $this->rule('tire_condition_inspection', 5, 'universal', 'condition_based', $all, null, null, 'safety_critical', ['ru' => 'Проверка состояния шин', 'en' => 'Tire condition inspection'], $this->conditionBasis('состояние шин', 'tire condition'), $unknown),
            $this->rule('coolant_inspection', 6, 'universal', 'condition_based', $all, null, null, 'medium', ['ru' => 'Проверка охлаждающей жидкости', 'en' => 'Coolant inspection'], $this->conditionBasis('охлаждающую жидкость', 'the coolant'), $unknown),
            $this->rule('air_filter', 7, 'type_based', 'interval_based', $combustion, null, 365, 'low', ['ru' => 'Воздушный фильтр', 'en' => 'Air filter'], $this->intervalBasis('365 дней', '365 days'), $unknown),
            $this->rule('brake_fluid', 8, 'universal', 'condition_based', $all, null, null, 'high', ['ru' => 'Тормозная жидкость', 'en' => 'Brake fluid'], $this->conditionBasis('тормозную жидкость', 'the brake fluid'), $unknown),
            $this->rule('brake_pads', 9, 'universal', 'condition_based', $all, null, null, 'safety_critical', ['ru' => 'Тормозные колодки', 'en' => 'Brake pads'], $this->conditionBasis('тормозные колодки', 'the brake pads'), $unknown),
            $this->rule('brake_discs', 10, 'universal', 'condition_based', $all, null, null, 'safety_critical', ['ru' => 'Тормозные диски', 'en' => 'Brake discs'], $this->conditionBasis('тормозные диски', 'the brake discs'), $unknown),
            $this->rule('timing_drive', 11, 'type_based', 'condition_based', $combustion, null, null, 'high', ['ru' => 'Привод ГРМ', 'en' => 'Timing drive'], $this->conditionBasis('привод ГРМ', 'the timing drive'), $unknown),
            $this->rule('transmission_oil', 12, 'type_based', 'condition_based', $combustion, null, null, 'medium', ['ru' => 'Масло трансмиссии', 'en' => 'Transmission oil'], $this->conditionBasis('масло трансмиссии', 'the transmission oil'), $unknown),
            $this->rule('spark_plugs', 13, 'type_based', 'condition_based', $spark, null, null, 'medium', ['ru' => 'Свечи зажигания', 'en' => 'Spark plugs'], $this->conditionBasis('свечи зажигания', 'the spark plugs'), $unknown),
        ];
    }

    private function rule(string $code, int $number, string $level, string $kind, array $fuels, ?int $mileage, ?int $days, string $criticality, array $title, array $basis, array $history): array
    {
        $suffix = str_pad((string) $number, 12, '0', STR_PAD_LEFT);

        return [
            'work_code' => $code,
            'catalog_id' => "10000000-0000-5000-8000-{$suffix}",
            'rule_id' => "20000000-0000-5000-8000-{$suffix}",
            'rule_level' => $level,
            'rule_kind' => $kind,
            'fuel_types' => $fuels,
            'mileage_interval_km' => $mileage,
            'time_interval_days' => $days,
            'criticality' => $criticality,
            'title' => $title,
            'basis' => $basis,
            'history_impact' => $history,
        ];
    }

    private function intervalBasis(string $ru, string $en): array
    {
        return [
            'ru' => "Базовая рекомендация AutoDoctor — каждые {$ru}. Проверьте точный порядок в руководстве владельца.",
            'en' => "AutoDoctor baseline recommendation — every {$en}. Check the exact schedule in the owner's manual.",
        ];
    }

    private function conditionBasis(string $ru, string $en): array
    {
        return [
            'ru' => "Базовая рекомендация AutoDoctor — регулярно проверять {$ru}. Проверьте точный порядок в руководстве владельца.",
            'en' => "AutoDoctor baseline recommendation — inspect {$en} regularly. Check the exact schedule in the owner's manual.",
        ];
    }

    private function assertImmutable($model, array $expected, string $label): void
    {
        foreach ($expected as $key => $value) {
            if ($model->getAttribute($key) != $value) {
                throw new LogicException("Published {$label} differs from canonical seed.");
            }
        }
    }
}
