<?php

namespace App\Filament\Resources\GuestProfiles\Tables;

use App\Filament\Resources\GuestProfiles\GuestProfileResource;
use App\Models\GuestProfile;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class GuestProfilesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('display_name')
                    ->label('Пользователь')
                    ->state(function (GuestProfile $record): string {
                        if (filled($record->user?->name)) {
                            return (string) $record->user->name;
                        }
                        if (filled($record->user?->email)) {
                            return (string) $record->user->email;
                        }

                        if (filled($record->telegram_first_name)) {
                            return (string) $record->telegram_first_name;
                        }

                        return 'Гость '.mb_substr((string) $record->id, 0, 8);
                    })
                    ->description(fn (GuestProfile $record): string => (string) ($record->user?->email ?: 'ID: '.$record->id))
                    ->searchable(query: function ($query, string $search): void {
                        $query
                            ->where('id', 'like', "%{$search}%")
                            ->orWhereHas('user', function ($q) use ($search): void {
                                $q->where('email', 'like', "%{$search}%")
                                    ->orWhere('name', 'like', "%{$search}%");
                            });
                    })
                    ->wrap(),
                TextColumn::make('telegram_id')
                    ->label('Telegram ID')
                    ->placeholder('—')
                    ->copyable()
                    ->toggleable(),
                TextColumn::make('account_type')
                    ->label('Тип')
                    ->badge()
                    ->state(fn (GuestProfile $record): string => $record->user_id ? 'Аккаунт' : 'Гость')
                    ->color(fn (string $state): string => $state === 'Аккаунт' ? 'success' : 'gray'),
                TextColumn::make('sessions_count')
                    ->label('Сессии')
                    ->counts('sessions')
                    ->sortable(),
                TextColumn::make('vehicles_count')
                    ->label('Машины')
                    ->counts('vehicles')
                    ->sortable(),
                TextColumn::make('ai_notes_count')
                    ->label('Заметки')
                    ->counts('aiNotes')
                    ->sortable(),
                TextColumn::make('assistant_threads_count')
                    ->label('Диалоги')
                    ->counts('assistantThreads')
                    ->sortable(),
                TextColumn::make('created_at')
                    ->label('Первый визит')
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('updated_at')
                    ->label('Обновлён')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                SelectFilter::make('account_type')
                    ->label('Тип')
                    ->options([
                        'account' => 'Аккаунт',
                        'guest' => 'Гость',
                    ])
                    ->query(function ($query, array $data) {
                        return match ($data['value'] ?? null) {
                            'account' => $query->whereNotNull('user_id'),
                            'guest' => $query->whereNull('user_id'),
                            default => $query,
                        };
                    }),
            ])
            ->recordActions([
                ViewAction::make()->label('Открыть'),
            ])
            ->recordUrl(fn (GuestProfile $record): string => GuestProfileResource::getUrl('view', ['record' => $record]));
    }
}
