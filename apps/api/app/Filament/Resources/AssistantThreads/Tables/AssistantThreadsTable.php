<?php

namespace App\Filament\Resources\AssistantThreads\Tables;

use App\Models\AssistantThread;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class AssistantThreadsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('title')
                    ->label('Title')
                    ->searchable()
                    ->limit(40)
                    ->placeholder('Untitled'),
                TextColumn::make('account')
                    ->label('Account')
                    ->state(fn (AssistantThread $record): string => $record->guestProfile?->adminLabel()
                        ?? ('Guest '.mb_substr((string) $record->guest_profile_id, 0, 8)))
                    ->searchable(query: function ($query, string $search): void {
                        $query->whereHas('guestProfile', function ($q) use ($search): void {
                            $q->where('telegram_id', 'like', "%{$search}%")
                                ->orWhere('telegram_username', 'like', "%{$search}%")
                                ->orWhere('telegram_first_name', 'like', "%{$search}%")
                                ->orWhereHas('user', function ($userQuery) use ($search): void {
                                    $userQuery->where('email', 'like', "%{$search}%")
                                        ->orWhere('name', 'like', "%{$search}%");
                                });
                        })->orWhere('guest_profile_id', 'like', "%{$search}%");
                    }),
                TextColumn::make('channel')
                    ->label('Канал')
                    ->badge()
                    ->state(fn (AssistantThread $record): string => $record->channel === 'telegram' ? 'Telegram' : 'Приложение')
                    ->color(fn (AssistantThread $record): string => $record->channel === 'telegram' ? 'info' : 'gray'),
                TextColumn::make('account_type')
                    ->label('Type')
                    ->badge()
                    ->state(fn (AssistantThread $record): string => $record->guestProfile?->user_id
                        ? 'Account'
                        : 'Guest')
                    ->color(fn (string $state): string => $state === 'Account' ? 'success' : 'gray'),
                TextColumn::make('vehicle')
                    ->label('Vehicle')
                    ->state(function (AssistantThread $record): string {
                        $configuration = $record->vehicle?->configuration;
                        $label = trim(($configuration?->make ?? '').' '.($configuration?->model ?? ''));

                        return $label !== '' ? $label : '—';
                    }),
                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'resolved' => 'success',
                        'archived' => 'gray',
                        default => 'info',
                    }),
                TextColumn::make('messages_count')
                    ->label('Msgs')
                    ->counts('messages')
                    ->sortable(),
                TextColumn::make('created_at')
                    ->label('Started')
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('last_message_at')
                    ->label('Last message')
                    ->dateTime()
                    ->sortable(),
            ])
            ->defaultSort('last_message_at', 'desc')
            ->filters([
                SelectFilter::make('status')
                    ->options([
                        'active' => 'Active',
                        'resolved' => 'Resolved',
                        'archived' => 'Archived',
                    ]),
                SelectFilter::make('channel')
                    ->label('Канал')
                    ->options([
                        'telegram' => 'Telegram',
                        'app' => 'Приложение',
                    ]),
            ])
            ->recordActions([
                ViewAction::make(),
            ]);
    }
}
