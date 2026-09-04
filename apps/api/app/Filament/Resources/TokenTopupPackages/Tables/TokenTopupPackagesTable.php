<?php

namespace App\Filament\Resources\TokenTopupPackages\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class TokenTopupPackagesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('sort_order')->label('#')->sortable(),
                TextColumn::make('key')->searchable()->sortable(),
                TextColumn::make('type')->badge()->sortable(),
                TextColumn::make('title')->searchable()->wrap(),
                TextColumn::make('tokens_amount')->label('Токены')->placeholder('—'),
                TextColumn::make('stars_price')->label('⭐')->placeholder('—'),
                TextColumn::make('cooldown_hours')->label('Кулдаун ч')->placeholder('—'),
                IconColumn::make('enabled')->boolean()->label('On'),
                TextColumn::make('updated_at')->dateTime()->sortable(),
            ])
            ->defaultSort('sort_order')
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
