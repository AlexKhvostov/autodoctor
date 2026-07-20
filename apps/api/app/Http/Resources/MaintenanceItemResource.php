<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MaintenanceItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $rule = $this->resource->rule;
        $locale = app()->getLocale() === 'en' ? 'en' : 'ru';
        $content = $rule->localized_content;
        $source = $rule->source;
        $explanation = $this->resource->explanation;
        $historyState = $explanation['history_state'];
        $importance = match (true) {
            $rule->criticality === 'safety_critical',
            $this->resource->urgency === 'immediate',
            $rule->rule_type === 'regulation' && $this->resource->status === 'overdue' => 'critical_attention',
            $rule->rule_type === 'regulation' => 'required',
            default => 'recommended',
        };

        return array_filter([
            'id' => $this->resource->id,
            'work_code' => $rule->work_code,
            'title' => $content['title'][$locale],
            'status' => $this->resource->status,
            'criticality' => $rule->criticality,
            'urgency' => $this->resource->urgency,
            'presentation_importance' => in_array($this->resource->status, ['completed', 'not_applicable'], true)
                ? null
                : $importance,
            'rule_level' => $rule->rule_level,
            'rule_type' => $rule->rule_type,
            'rule_version' => $rule->version,
            'due' => [
                'mileage' => $this->resource->due_mileage_km === null ? null : [
                    'value' => $this->resource->due_mileage_km,
                    'unit' => 'km',
                ],
                'date' => $this->resource->due_date?->format('Y-m-d'),
            ],
            'interval' => [
                'mileage_km' => $this->resource->interval_metadata['mileage_km'] ?? null,
                'days' => $this->resource->interval_metadata['days'] ?? null,
            ],
            'basis' => $content['basis'][$locale],
            'requires_check_now' => (bool) $explanation['requires_check_now'],
            'history_impact' => $this->historyImpact($locale, $historyState['answer']),
            'history_state' => $historyState,
            'source' => [
                'id' => $source->id,
                'title' => $source->title,
                'publisher' => $source->publisher,
                'source_kind' => $source->source_kind,
                'official_oem' => $source->official_oem,
                'methodology_note' => $source->methodology_note,
                'url' => $source->url,
                'effective_date' => $source->effective_date?->format('Y-m-d'),
                'verified_at' => $source->verified_at?->toISOString(),
            ],
        ], fn ($value, $key): bool => $key !== 'presentation_importance' || $value !== null, ARRAY_FILTER_USE_BOTH);
    }

    private function historyImpact(string $locale, ?string $answer): string
    {
        if ($answer === 'done_known') {
            return $locale === 'ru'
                ? 'Последнее выполнение подтверждено указанной датой и/или пробегом.'
                : 'The last completion is confirmed by the supplied date and/or mileage.';
        }
        if ($answer === 'not_applicable') {
            return $locale === 'ru'
                ? 'Пользователь отметил пункт как неприменимый.'
                : 'The user marked this item as not applicable.';
        }

        return $locale === 'ru'
            ? 'История неизвестна — рекомендуем проверить/выполнить сейчас.'
            : 'History is unknown — we recommend checking or performing this now.';
    }
}
