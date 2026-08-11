<?php

namespace App\Filament\Resources\AiConfigVersions\Pages;

use App\Filament\Resources\AiConfigVersions\AiConfigVersionResource;
use App\Models\AiConfigVersion;
use Filament\Resources\Pages\CreateRecord;

class CreateAiConfigVersion extends CreateRecord
{
    protected static string $resource = AiConfigVersionResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $previous = AiConfigVersion::active();
        if ($previous !== null) {
            $data['previous_version_id'] = $previous->id;
        }
        $data['author'] = $data['author'] ?? auth()->user()?->email;

        return $data;
    }

    protected function afterCreate(): void
    {
        /** @var AiConfigVersion $record */
        $record = $this->record;
        if ($record->is_active) {
            AiConfigVersion::query()
                ->where('id', '!=', $record->id)
                ->where('is_active', true)
                ->update(['is_active' => false]);
        }
    }
}
