<?php

namespace App\Filament\Resources\TelegramBotUsers;

use App\Filament\Resources\TelegramBotUsers\Pages\CreateTelegramAllowlistEntry;
use App\Filament\Resources\TelegramBotUsers\Pages\ListTelegramAllowlist;
use App\Models\TelegramBotUser;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use UnitEnum;

class TelegramAllowlistResource extends Resource
{
    protected static ?string $model = TelegramBotUser::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedShieldCheck;

    protected static string|UnitEnum|null $navigationGroup = 'Telegram';

    protected static ?string $navigationLabel = 'Белый список';

    protected static ?string $modelLabel = 'в белом списке';

    protected static ?string $pluralModelLabel = 'белый список';

    protected static ?int $navigationSort = 2;

    protected static ?string $slug = 'telegram-allowlist';

    public static function canDelete($record): bool
    {
        return false;
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('telegram_user_id')
                    ->label('Telegram ID')
                    ->numeric()
                    ->required()
                    ->helperText('Числовой id, не @ник. Если человек уже писал боту — его проще отметить галочкой в «Писали боту».'),
                TextInput::make('username')
                    ->label('Ник (необязательно)')
                    ->maxLength(64),
                Textarea::make('note')
                    ->label('Заметка')
                    ->maxLength(255)
                    ->rows(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        $table = $table
            ->columns(TelegramBotUserColumns::identity())
            ->defaultSort('allowlisted_at', 'desc')
            ->recordActions([
                Action::make('removeFromAllowlist')
                    ->label('Убрать')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->modalHeading('Убрать из белого списка?')
                    ->modalDescription('Человек останется в списке «Писали боту», но бот снова ответит «закрытый пилот».')
                    ->action(fn (TelegramBotUser $record) => $record->setAllowlisted(false)),
            ]);

        return TelegramBotUserColumns::search($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListTelegramAllowlist::route('/'),
            'create' => CreateTelegramAllowlistEntry::route('/create'),
        ];
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->allowlisted();
    }
}
