<?php

namespace App\Filament\Resources\AiPromptVersions\Pages;

use App\Filament\Resources\AiPromptVersions\AiPromptVersionResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListAiPromptVersions extends ListRecords
{
    protected static string $resource = AiPromptVersionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
