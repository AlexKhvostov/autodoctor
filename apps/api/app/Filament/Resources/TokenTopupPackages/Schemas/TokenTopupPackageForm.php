<?php

namespace App\Filament\Resources\TokenTopupPackages\Schemas;

use App\Models\TokenTopupPackage;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class TokenTopupPackageForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Пакет')
                    ->columns(2)
                    ->schema([
                        TextInput::make('key')
                            ->label('Ключ')
                            ->required()
                            ->maxLength(64)
                            ->unique(ignoreRecord: true)
                            ->helperText('Стабильный код: stars_pack_s, mileage, invite…'),
                        Select::make('type')
                            ->label('Тип')
                            ->options([
                                TokenTopupPackage::TYPE_STARS => 'Stars (покупка)',
                                TokenTopupPackage::TYPE_MILEAGE => 'Бонус за пробег',
                                TokenTopupPackage::TYPE_INVITE => 'Приглашение друга',
                            ])
                            ->required()
                            ->native(false),
                        TextInput::make('title')
                            ->label('Название')
                            ->required()
                            ->maxLength(120)
                            ->columnSpanFull(),
                        TextInput::make('subtitle')
                            ->label('Подзаголовок')
                            ->maxLength(255)
                            ->columnSpanFull(),
                        TextInput::make('icon')
                            ->label('Иконка')
                            ->maxLength(16)
                            ->placeholder('⭐'),
                        TextInput::make('badge')
                            ->label('Бейдж')
                            ->maxLength(64)
                            ->helperText('Например «скоро». Для пробега можно оставить пустым — покажется статус кулдауна.'),
                        TextInput::make('tokens_amount')
                            ->label('Токены')
                            ->numeric()
                            ->minValue(0)
                            ->helperText('Сколько токенов даёт пакет / бонус'),
                        TextInput::make('stars_price')
                            ->label('Цена, Stars')
                            ->numeric()
                            ->minValue(0)
                            ->helperText('Для бесплатных способов — 0. Именно это видит Mini App.'),
                        TextInput::make('cooldown_hours')
                            ->label('Кулдаун, часов')
                            ->numeric()
                            ->minValue(1)
                            ->helperText('Только для бонуса за пробег (обычно 24).'),
                        TextInput::make('sort_order')
                            ->label('Порядок')
                            ->numeric()
                            ->default(100)
                            ->required(),
                        Toggle::make('enabled')
                            ->label('Показывать в приложении')
                            ->default(true),
                    ]),
            ]);
    }
}
