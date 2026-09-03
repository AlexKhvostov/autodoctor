<?php

namespace App\Filament\Resources\TelegramBotUsers;

use App\Models\TelegramBotUser;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ToggleColumn;
use Filament\Tables\Table;

class TelegramBotUserColumns
{
    /**
     * @return array<int, TextColumn|ToggleColumn>
     */
    public static function identity(): array
    {
        return [
            TextColumn::make('telegram_user_id')
                ->label('Telegram ID')
                ->copyable()
                ->searchable()
                ->sortable(),
            TextColumn::make('username')
                ->label('Ник')
                ->formatStateUsing(fn (?string $state): string => filled($state) ? '@'.$state : '—')
                ->searchable(),
            TextColumn::make('display_name')
                ->label('Имя')
                ->state(fn (TelegramBotUser $record): string => $record->displayName())
                ->searchable(query: function ($query, string $search): void {
                    $query->where('first_name', 'like', "%{$search}%")
                        ->orWhere('last_name', 'like', "%{$search}%");
                }),
            TextColumn::make('message_count')
                ->label('Сообщений')
                ->sortable(),
            TextColumn::make('last_message_at')
                ->label('Последнее сообщение')
                ->dateTime()
                ->sortable()
                ->placeholder('ещё не писал'),
            TextColumn::make('allowlisted_at')
                ->label('В белый список')
                ->dateTime()
                ->placeholder('—')
                ->sortable(),
            TextColumn::make('removed_from_allowlist_at')
                ->label('Убран из списка')
                ->dateTime()
                ->placeholder('—')
                ->sortable(),
            TextColumn::make('note')
                ->label('Заметка')
                ->placeholder('—')
                ->wrap()
                ->toggleable(),
        ];
    }

    public static function allowlistToggle(): ToggleColumn
    {
        return ToggleColumn::make('is_allowlisted')
            ->label('Белый список')
            ->updateStateUsing(function (TelegramBotUser $record, mixed $state): void {
                $record->setAllowlisted((bool) $state);
            });
    }

    public static function search(Table $table): Table
    {
        return $table->searchPlaceholder('ID, ник или имя');
    }
}
