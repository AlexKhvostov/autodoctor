<?php

namespace App\Filament\Resources\AiConfigVersions\Pages;

use App\Filament\Resources\AiConfigVersions\AiConfigVersionResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListAiConfigVersions extends ListRecords
{
    protected static string $resource = AiConfigVersionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
