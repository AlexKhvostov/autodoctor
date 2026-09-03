<?php

namespace App\Filament\Resources\TelegramBotUsers\Pages;

use App\Filament\Resources\TelegramBotUsers\TelegramBotWriterResource;
use Filament\Resources\Pages\ListRecords;

class ListTelegramBotWriters extends ListRecords
{
    protected static string $resource = TelegramBotWriterResource::class;
}
