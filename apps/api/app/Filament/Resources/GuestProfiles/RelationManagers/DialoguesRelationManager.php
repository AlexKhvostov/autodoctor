<?php

namespace App\Filament\Resources\GuestProfiles\RelationManagers;

use App\Filament\Resources\AssistantThreads\AssistantThreadResource;
use App\Models\AssistantThread;
use Filament\Actions\Action;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class DialoguesRelationManager extends RelationManager
{
    protected static string $relationship = 'assistantThreads';

    protected static ?string $title = 'Диалоги';

    public function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with(['vehicle.configuration'])->withCount('messages'))
            ->columns([
                TextColumn::make('channel')
                    ->label('Канал')
                    ->badge()
                    ->state(fn (AssistantThread $record): string => $record->channel === 'telegram' ? 'Telegram' : 'Приложение'),
                TextColumn::make('title')
                    ->label('Тема')
                    ->placeholder('Без названия')
                    ->wrap()
                    ->searchable(),
                TextColumn::make('vehicle_label')
                    ->label('Машина')
                    ->state(function (AssistantThread $record): string {
                        $configuration = $record->vehicle?->configuration;
                        $label = trim(($configuration?->make ?? '').' '.($configuration?->model ?? ''));

                        return $label !== '' ? $label : '—';
                    }),
                TextColumn::make('messages_count')->label('Сообщений')->counts('messages'),
                TextColumn::make('last_message_at')->label('Последнее')->dateTime()->sortable(),
                TextColumn::make('created_at')->label('Начат')->dateTime(),
            ])
            ->defaultSort('last_message_at', 'desc')
            ->recordActions([
                Action::make('open')
                    ->label('Открыть')
                    ->url(fn (AssistantThread $record): string => AssistantThreadResource::getUrl('view', ['record' => $record])),
            ])
            ->paginated(false)
            ->emptyStateHeading('Диалогов пока нет');
    }
}
