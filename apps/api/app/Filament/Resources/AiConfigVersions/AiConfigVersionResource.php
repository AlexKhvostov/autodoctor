<?php

namespace App\Filament\Resources\AiConfigVersions;

use App\Filament\Resources\AiConfigVersions\Pages\CreateAiConfigVersion;
use App\Filament\Resources\AiConfigVersions\Pages\EditAiConfigVersion;
use App\Filament\Resources\AiConfigVersions\Pages\ListAiConfigVersions;
use App\Filament\Resources\AiConfigVersions\Schemas\AiConfigVersionForm;
use App\Filament\Resources\AiConfigVersions\Tables\AiConfigVersionsTable;
use App\Models\AiConfigVersion;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

class AiConfigVersionResource extends Resource
{
    protected static ?string $model = AiConfigVersion::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCpuChip;

    protected static string|UnitEnum|null $navigationGroup = 'AI';

    protected static ?string $navigationLabel = 'AI configs';

    protected static ?string $modelLabel = 'AI config';

    protected static ?int $navigationSort = 2;

    public static function form(Schema $schema): Schema
    {
        return AiConfigVersionForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return AiConfigVersionsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListAiConfigVersions::route('/'),
            'create' => CreateAiConfigVersion::route('/create'),
            'edit' => EditAiConfigVersion::route('/{record}/edit'),
        ];
    }
}
