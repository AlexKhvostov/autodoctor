<?php

namespace App\Filament\Resources\GuestProfiles\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class SessionsRelationManager extends RelationManager
{
    protected static string $relationship = 'sessions';

    protected static ?string $title = 'Сессии / устройства';

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')
                    ->label('Session ID')
                    ->formatStateUsing(fn (string $state): string => mb_substr($state, 0, 8).'…')
                    ->copyable()
                    ->tooltip(fn ($record): string => (string) $record->id),
                TextColumn::make('platform')->label('Платформа')->badge(),
                TextColumn::make('status')->label('Статус')->badge(),
                TextColumn::make('locale')->label('Язык'),
                TextColumn::make('app_version')->label('Версия приложения')->placeholder('—'),
                TextColumn::make('last_activity_at')->label('Активность')->dateTime()->sortable(),
                TextColumn::make('expires_at')->label('Истекает')->dateTime(),
                TextColumn::make('created_at')->label('Создана')->dateTime(),
            ])
            ->defaultSort('last_activity_at', 'desc')
            ->paginated(false);
    }
}
