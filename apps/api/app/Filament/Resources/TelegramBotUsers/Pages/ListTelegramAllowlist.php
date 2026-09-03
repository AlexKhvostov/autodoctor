<?php

namespace App\Filament\Resources\TelegramBotUsers\Pages;

use App\Filament\Resources\TelegramBotUsers\TelegramAllowlistResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListTelegramAllowlist extends ListRecords
{
    protected static string $resource = TelegramAllowlistResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()->label('Добавить ID'),
        ];
    }
}
