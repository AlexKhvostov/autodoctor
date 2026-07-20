<?php

namespace Database\Seeders;

use App\Models\MaintenanceRule;
use App\Models\MaintenanceSource;
use App\Models\RulesetVersion;
use App\Models\WorkCatalogItem;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MaintenanceV1Seeder extends Seeder
{
    public const RULESET_VERSION = 'by-pilot-baseline-1';

    private const SOURCE_ID = 'b7dd60b4-3efd-5fc9-93a6-f07bf31071d2';

    private const RULESET_ID = '7747518e-574a-50b6-8522-825be86599c6';

    public function run(): void
    {
        $definitions = $this->definitions();
        $contentHash = 'sha256:'.hash('sha256', json_encode(
            $definitions,
            JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES,
        ));

        DB::transaction(function () use ($definitions, $contentHash): void {
            $source = MaintenanceSource::query()->updateOrCreate(
                ['id' => self::SOURCE_ID],
                [
                    'source_kind' => 'editorial_baseline',
                    'title' => 'AutoDoctor Pilot Baseline v1',
                    'publisher' => 'AutoDoctor Editorial',
                    'document_version' => '1',
                    'publication_status' => 'published',
                    'methodology_note' => 'Внутренняя редакционная методика AutoDoctor; не руководство и не регламент производителя.',
                    'url' => null,
                    'official_oem' => false,
                    'effective_date' => null,
                    'verified_at' => null,
                ],
            );

            $ruleset = RulesetVersion::query()->firstOrNew(['version' => self::RULESET_VERSION]);
            $ruleset->id ??= self::RULESET_ID;
            $ruleset->content_hash = $contentHash;
            $ruleset->published_at ??= now();
            $ruleset->save();

            foreach ($definitions as $definition) {
                $catalog = WorkCatalogItem::query()->updateOrCreate(
                    ['code' => $definition['work_code']],
                    [
                        'id' => $definition['catalog_id'],
                        'localized_name' => $definition['title'],
                    ],
                );

                MaintenanceRule::query()->updateOrCreate(
                    [
                        'ruleset_version_id' => $ruleset->id,
                        'work_code' => $definition['work_code'],
                    ],
                    [
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
                    ],
                );
            }
        });
    }

    private function definitions(): array
    {
        $all = ['petrol', 'diesel', 'hybrid', 'electric', 'lpg', 'other'];
        $combustion = ['petrol', 'diesel', 'hybrid', 'lpg'];
        $unknownHistory = [
            'ru' => 'История последнего обслуживания неизвестна; срок и просрочка не рассчитаны.',
            'en' => 'The last service is unknown; due values and overdue status were not calculated.',
        ];
        $conditionHistory = [
            'ru' => 'История проверки неизвестна; требуется осмотр без оценки процента износа.',
            'en' => 'Inspection history is unknown; an inspection is required without a wear percentage estimate.',
        ];

        return [
            $this->rule('engine_oil', 'a9aaa92b-56cb-5908-a629-19541762c7cd', '3e7a9ac9-4b26-5eaf-8b66-24d4c5c45b70', 'type_based', 'interval_based', $combustion, 10000, 365, 'medium',
                ['ru' => 'Моторное масло', 'en' => 'Engine oil'],
                $this->intervalBasis('10 000 км или 365 дней, что наступит раньше', '10,000 km or 365 days, whichever comes first'),
                $unknownHistory),
            $this->rule('oil_filter', 'ac3eb995-20b0-5fc3-b071-4d43f089ed66', '8e3d7d3a-93d6-570d-80e1-87804f1be652', 'type_based', 'interval_based', $combustion, 10000, 365, 'medium',
                ['ru' => 'Масляный фильтр', 'en' => 'Oil filter'],
                $this->intervalBasis('10 000 км или 365 дней, что наступит раньше', '10,000 km or 365 days, whichever comes first'),
                $unknownHistory),
            $this->rule('cabin_filter', '87d768ef-6831-5164-8ec1-3c3e98b9d88c', '57ff0819-8805-5d4e-b65f-dabddb099d77', 'universal', 'interval_based', $all, null, 365, 'low',
                ['ru' => 'Салонный фильтр', 'en' => 'Cabin filter'],
                $this->intervalBasis('365 дней', '365 days'),
                $unknownHistory),
            $this->rule('brake_system_inspection', 'aa1f8910-7443-5702-a429-e4ce32e27b2b', 'c50aecff-98f0-536c-bd15-d9ac23c990b8', 'universal', 'condition_based', $all, null, null, 'high',
                ['ru' => 'Проверка тормозной системы', 'en' => 'Brake system inspection'],
                $this->conditionBasis('тормозную систему', 'the brake system'),
                $conditionHistory),
            $this->rule('tire_condition_inspection', 'b419158c-b7e4-5fb3-8d89-a8e26060647f', '58331c62-3401-50ce-8690-f985bdb51bc9', 'universal', 'condition_based', $all, null, null, 'high',
                ['ru' => 'Проверка состояния шин', 'en' => 'Tire condition inspection'],
                $this->conditionBasis('состояние шин', 'tire condition'),
                $conditionHistory),
            $this->rule('coolant_inspection', 'aa1a419f-fd02-507d-936f-56b0329aeecb', 'c2f690ea-00df-5c8b-996a-60ebdf3c4f5d', 'universal', 'condition_based', $all, null, null, 'medium',
                ['ru' => 'Проверка охлаждающей жидкости', 'en' => 'Coolant inspection'],
                $this->conditionBasis('охлаждающую жидкость', 'the coolant'),
                $conditionHistory),
        ];
    }

    private function rule(
        string $workCode,
        string $catalogId,
        string $ruleId,
        string $ruleLevel,
        string $ruleKind,
        array $fuelTypes,
        ?int $mileage,
        ?int $days,
        string $criticality,
        array $title,
        array $basis,
        array $historyImpact,
    ): array {
        return [
            'work_code' => $workCode,
            'catalog_id' => $catalogId,
            'rule_id' => $ruleId,
            'rule_level' => $ruleLevel,
            'rule_kind' => $ruleKind,
            'fuel_types' => $fuelTypes,
            'mileage_interval_km' => $mileage,
            'time_interval_days' => $days,
            'criticality' => $criticality,
            'title' => $title,
            'basis' => $basis,
            'history_impact' => $historyImpact,
        ];
    }

    private function intervalBasis(string $ruInterval, string $enInterval): array
    {
        return [
            'ru' => "Базовая рекомендация AutoDoctor — каждые {$ruInterval}. Проверьте точный порядок в руководстве владельца.",
            'en' => "AutoDoctor baseline recommendation — every {$enInterval}. Check the exact schedule in the owner's manual.",
        ];
    }

    private function conditionBasis(string $ruSubject, string $enSubject): array
    {
        return [
            'ru' => "Базовая рекомендация AutoDoctor — регулярно проверять {$ruSubject}. Проверьте точный порядок в руководстве владельца.",
            'en' => "AutoDoctor baseline recommendation — inspect {$enSubject} regularly. Check the exact schedule in the owner's manual.",
        ];
    }
}
