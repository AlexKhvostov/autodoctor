<?php

namespace App\Filament\Resources\GuestProfiles;

use App\Filament\Resources\GuestProfiles\Pages\ListGuestProfiles;
use App\Filament\Resources\GuestProfiles\Pages\ViewGuestProfile;
use App\Filament\Resources\GuestProfiles\RelationManagers\DialoguesRelationManager;
use App\Filament\Resources\GuestProfiles\RelationManagers\SessionsRelationManager;
use App\Filament\Resources\GuestProfiles\RelationManagers\UserNotesRelationManager;
use App\Filament\Resources\GuestProfiles\RelationManagers\VehiclesRelationManager;
use App\Filament\Resources\GuestProfiles\Tables\GuestProfilesTable;
use App\Models\GuestProfile;
use BackedEnum;
use Filament\Infolists\Components\TextEntry;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

class GuestProfileResource extends Resource
{
    protected static ?string $model = GuestProfile::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUsers;

    protected static string|UnitEnum|null $navigationGroup = 'Пользователи';

    protected static ?string $navigationLabel = 'Пользователи приложения';

    protected static ?string $modelLabel = 'пользователь';

    protected static ?string $pluralModelLabel = 'пользователи';

    protected static ?int $navigationSort = 1;

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit($record): bool
    {
        return false;
    }

    public static function canDelete($record): bool
    {
        return false;
    }

    public static function form(Schema $schema): Schema
    {
        return $schema;
    }

    public static function infolist(Schema $schema): Schema
    {
        return $schema->components([
            Section::make('Кто это')
                ->columns(2)
                ->schema([
                    TextEntry::make('id')
                        ->label('Guest profile ID')
                        ->copyable()
                        ->columnSpanFull(),
                    TextEntry::make('account_type')
                        ->label('Тип')
                        ->badge()
                        ->state(fn (GuestProfile $record): string => $record->user_id ? 'Аккаунт' : 'Гость')
                        ->color(fn (string $state): string => $state === 'Аккаунт' ? 'success' : 'gray'),
                    TextEntry::make('user.email')->label('Email')->placeholder('—')->copyable(),
                    TextEntry::make('user.name')->label('Имя')->placeholder('—'),
                    TextEntry::make('user.google_id')->label('Google ID')->placeholder('—')->copyable(),
                    TextEntry::make('created_at')->label('Первый визит')->dateTime(),
                    TextEntry::make('updated_at')->label('Обновлён')->dateTime(),
                    TextEntry::make('summary')
                        ->label('Сводка')
                        ->state(function (GuestProfile $record): string {
                            $record->loadCount(['sessions', 'vehicles', 'aiNotes', 'assistantThreads']);

                            return sprintf(
                                'Сессий: %d · Машин: %d · Заметок о человеке: %d · Диалогов: %d',
                                $record->sessions_count,
                                $record->vehicles_count,
                                $record->ai_notes_count,
                                $record->assistant_threads_count,
                            );
                        })
                        ->columnSpanFull(),
                ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return GuestProfilesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            SessionsRelationManager::class,
            UserNotesRelationManager::class,
            VehiclesRelationManager::class,
            DialoguesRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListGuestProfiles::route('/'),
            'view' => ViewGuestProfile::route('/{record}'),
        ];
    }

    public static function getEloquentQuery(): \Illuminate\Database\Eloquent\Builder
    {
        return parent::getEloquentQuery()
            ->with(['user'])
            ->withCount(['sessions', 'vehicles', 'aiNotes', 'assistantThreads']);
    }
}
