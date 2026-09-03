<?php

namespace App\Filament\Resources\TelegramBotUsers;

use App\Filament\Resources\GuestProfiles\GuestProfileResource;
use App\Filament\Resources\TelegramBotUsers\Pages\ListTelegramBotWriters;
use App\Models\GuestProfile;
use App\Models\TelegramBotUser;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use UnitEnum;

class TelegramBotWriterResource extends Resource
{
    protected static ?string $model = TelegramBotUser::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedChatBubbleLeftRight;

    protected static string|UnitEnum|null $navigationGroup = 'Telegram';

    protected static ?string $navigationLabel = 'Писали боту';

    protected static ?string $modelLabel = 'кто писал боту';

    protected static ?string $pluralModelLabel = 'кто писал боту';

    protected static ?int $navigationSort = 1;

    protected static ?string $slug = 'telegram-writers';

    public static function canCreate(): bool
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

    public static function table(Table $table): Table
    {
        $table = $table
            ->columns([
                TelegramBotUserColumns::allowlistToggle(),
                ...TelegramBotUserColumns::identity(),
            ])
            ->defaultSort('last_message_at', 'desc')
            ->recordActions([
                Action::make('openProfile')
                    ->label('Пользователь')
                    ->url(function (TelegramBotUser $record): ?string {
                        $profile = GuestProfile::query()
                            ->where('telegram_id', $record->telegram_user_id)
                            ->first();

                        return $profile === null
                            ? null
                            : GuestProfileResource::getUrl('view', ['record' => $profile]);
                    })
                    ->visible(fn (TelegramBotUser $record): bool => GuestProfile::query()
                        ->where('telegram_id', $record->telegram_user_id)
                        ->exists()),
            ]);

        return TelegramBotUserColumns::search($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListTelegramBotWriters::route('/'),
        ];
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->whereNotNull('last_message_at');
    }
}
