<?php

namespace App\Filament\Resources\GuestProfiles\RelationManagers;

use App\Models\Vehicle;
use App\Models\VehicleAiNote;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class VehiclesRelationManager extends RelationManager
{
    protected static string $relationship = 'vehicles';

    protected static ?string $title = 'Машины и заметки по ним';

    public function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with(['configuration', 'aiNotes']))
            ->columns([
                TextColumn::make('car')
                    ->label('Авто')
                    ->state(function (Vehicle $record): string {
                        $configuration = $record->configuration;
                        $label = trim(($configuration?->make ?? '').' '.($configuration?->model ?? ''));

                        return $label !== '' ? $label : '—';
                    })
                    ->description(fn (Vehicle $record): string => 'ID: '.mb_substr((string) $record->id, 0, 8).'…')
                    ->searchable(query: function ($query, string $search): void {
                        $query->whereHas('configuration', function ($q) use ($search): void {
                            $q->where('make', 'like', "%{$search}%")
                                ->orWhere('model', 'like', "%{$search}%");
                        });
                    }),
                TextColumn::make('production_year')->label('Год')->placeholder('—'),
                TextColumn::make('current_mileage')
                    ->label('Пробег')
                    ->formatStateUsing(fn ($state, Vehicle $record): string => $state === null
                        ? '—'
                        : number_format((int) $state, 0, '.', ' ').' '.($record->mileage_unit ?: 'km')),
                TextColumn::make('vehicle_notes')
                    ->label('AI-заметки по машине')
                    ->wrap()
                    ->state(function (Vehicle $record): string {
                        $notes = $record->aiNotes
                            ->sortByDesc(fn (VehicleAiNote $note) => $note->created_at?->timestamp ?? 0)
                            ->values();
                        if ($notes->isEmpty()) {
                            return '—';
                        }

                        return $notes
                            ->map(fn (VehicleAiNote $note): string => '• '.$note->body)
                            ->implode("\n");
                    }),
                TextColumn::make('created_at')->label('Добавлена')->dateTime()->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->paginated(false)
            ->emptyStateHeading('Машин пока нет')
            ->emptyStateDescription('Появятся, когда пользователь добавит авто в приложении.');
    }
}
