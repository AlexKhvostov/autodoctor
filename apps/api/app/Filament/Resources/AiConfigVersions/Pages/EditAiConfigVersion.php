<?php

namespace App\Filament\Resources\AiConfigVersions\Pages;

use App\Filament\Resources\AiConfigVersions\AiConfigVersionResource;
use App\Models\AiConfigVersion;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditAiConfigVersion extends EditRecord
{
    protected static string $resource = AiConfigVersionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }

    protected function afterSave(): void
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
