<?php

namespace App\Filament\Resources\AssistantThreads;

use App\Filament\Resources\AssistantThreads\Pages\ListAssistantThreads;
use App\Filament\Resources\AssistantThreads\Pages\ViewAssistantThread;
use App\Filament\Resources\AssistantThreads\Tables\AssistantThreadsTable;
use App\Filament\Resources\GuestProfiles\GuestProfileResource;
use App\Models\AssistantThread;
use BackedEnum;
use Filament\Infolists\Components\RepeatableEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use UnitEnum;

class AssistantThreadResource extends Resource
{
    protected static ?string $model = AssistantThread::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedChatBubbleLeftRight;

    protected static string|UnitEnum|null $navigationGroup = 'AI';

    protected static ?string $navigationLabel = 'Dialogues';

    protected static ?string $modelLabel = 'Dialogue';

    protected static ?string $pluralModelLabel = 'Dialogues';

    protected static ?int $navigationSort = 3;

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
            Section::make('Dialogue')
                ->columns(2)
                ->schema([
                    TextEntry::make('title')->label('Title')->columnSpanFull(),
                    TextEntry::make('account_label')
                        ->label('Account')
                        ->url(fn (AssistantThread $record): ?string => $record->guest_profile_id
                            ? GuestProfileResource::getUrl('view', ['record' => $record->guest_profile_id])
                            : null)
                        ->color('primary')
                        ->state(fn (AssistantThread $record): string => $record->guestProfile?->adminLabel()
                            ?? ('Guest '.mb_substr((string) $record->guest_profile_id, 0, 8))),
                    TextEntry::make('channel')
                        ->label('Канал')
                        ->badge()
                        ->state(fn (AssistantThread $record): string => $record->channel === 'telegram' ? 'Telegram' : 'Приложение')
                        ->color(fn (AssistantThread $record): string => $record->channel === 'telegram' ? 'info' : 'gray'),
                    TextEntry::make('account_type')
                        ->label('Type')
                        ->badge()
                        ->state(fn (AssistantThread $record): string => $record->guestProfile?->user_id
                            ? 'Account'
                            : 'Guest'),
                    TextEntry::make('status')
                        ->label('Status')
                        ->badge()
                        ->color(fn (string $state): string => match ($state) {
                            'resolved' => 'success',
                            'archived' => 'gray',
                            default => 'info',
                        }),
                    TextEntry::make('title_source')->label('Title source')->badge(),
                    TextEntry::make('vehicle_label')
                        ->label('Vehicle')
                        ->state(function (AssistantThread $record): string {
                            $vehicle = $record->vehicle;
                            $configuration = $vehicle?->configuration;
                            $label = trim(($configuration?->make ?? '').' '.($configuration?->model ?? ''));

                            return $label !== '' ? $label : (string) ($vehicle?->id ?? '—');
                        }),
                    TextEntry::make('created_at')->label('Started')->dateTime(),
                    TextEntry::make('last_message_at')->label('Last message')->dateTime(),
                    TextEntry::make('messages_count')
                        ->label('Messages')
                        ->state(fn (AssistantThread $record): int => $record->messages()->count()),
                ]),
            Section::make('Messages')
                ->schema([
                    RepeatableEntry::make('messages')
                        ->label('')
                        ->schema([
                            TextEntry::make('role')
                                ->badge()
                                ->color(fn (string $state): string => $state === 'user' ? 'info' : 'success'),
                            TextEntry::make('created_at')->dateTime()->label('At'),
                            TextEntry::make('content')
                                ->label('Text')
                                ->columnSpanFull()
                                ->markdown()
                                ->prose(),
                            TextEntry::make('provider')
                                ->visible(fn ($state): bool => filled($state))
                                ->placeholder(''),
                            TextEntry::make('model')
                                ->visible(fn ($state): bool => filled($state))
                                ->placeholder(''),
                        ])
                        ->columns(2),
                ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return AssistantThreadsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListAssistantThreads::route('/'),
            'view' => ViewAssistantThread::route('/{record}'),
        ];
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->with(['guestProfile.user', 'vehicle.configuration'])
            ->withCount('messages');
    }
}
