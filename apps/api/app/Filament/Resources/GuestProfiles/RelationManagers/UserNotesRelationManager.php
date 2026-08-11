<?php

namespace App\Filament\Resources\GuestProfiles\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class UserNotesRelationManager extends RelationManager
{
    protected static string $relationship = 'aiNotes';

    protected static ?string $title = 'Заметки о пользователе';

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('body')
                    ->label('Заметка')
                    ->wrap()
                    ->searchable(),
                TextColumn::make('source')->label('Источник')->badge(),
                TextColumn::make('created_at')->label('Когда')->dateTime()->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->paginated(false)
            ->emptyStateHeading('Пока нет заметок о пользователе')
            ->emptyStateDescription('Появятся после диалогов с AI, когда ассистент запомнит факты о человеке.');
    }
}
