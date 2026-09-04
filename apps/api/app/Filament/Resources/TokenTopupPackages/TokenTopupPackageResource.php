<?php

namespace App\Filament\Resources\TokenTopupPackages;

use App\Filament\Resources\TokenTopupPackages\Pages\CreateTokenTopupPackage;
use App\Filament\Resources\TokenTopupPackages\Pages\EditTokenTopupPackage;
use App\Filament\Resources\TokenTopupPackages\Pages\ListTokenTopupPackages;
use App\Filament\Resources\TokenTopupPackages\Schemas\TokenTopupPackageForm;
use App\Filament\Resources\TokenTopupPackages\Tables\TokenTopupPackagesTable;
use App\Models\TokenTopupPackage;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

class TokenTopupPackageResource extends Resource
{
    protected static ?string $model = TokenTopupPackage::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCurrencyDollar;

    protected static string|UnitEnum|null $navigationGroup = 'AI';

    protected static ?string $navigationLabel = 'Token packs';

    protected static ?string $modelLabel = 'Token pack';

    protected static ?string $pluralModelLabel = 'Token packs';

    protected static ?int $navigationSort = 5;

    public static function form(Schema $schema): Schema
    {
        return TokenTopupPackageForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return TokenTopupPackagesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListTokenTopupPackages::route('/'),
            'create' => CreateTokenTopupPackage::route('/create'),
            'edit' => EditTokenTopupPackage::route('/{record}/edit'),
        ];
    }
}
