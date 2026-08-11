<?php

namespace App\Filament\Resources\AssistantThreads\Tables;

use App\Models\AssistantThread;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
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
                    ->state(function (AssistantThread $record): string {
                        $user = $record->guestProfile?->user;
                        if ($user !== null) {
                            return $user->email ?: ($user->name ?: '#'.$user->id);
                        }

                        return 'Guest '.mb_substr((string) $record->guest_profile_id, 0, 8);
                    })
                    ->searchable(query: function ($query, string $search): void {
                        $query->whereHas('guestProfile.user', function ($q) use ($search): void {
                            $q->where('email', 'like', "%{$search}%")
                                ->orWhere('name', 'like', "%{$search}%");
                        })->orWhere('guest_profile_id', 'like', "%{$search}%");
                    }),
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
                \Filament\Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'active' => 'Active',
                        'resolved' => 'Resolved',
                        'archived' => 'Archived',
                    ]),
            ])
            ->recordActions([
                ViewAction::make(),
            ]);
    }
}
