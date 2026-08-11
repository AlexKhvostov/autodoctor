<?php

namespace App\Filament\Resources\AiPromptVersions;

use App\Filament\Resources\AiPromptVersions\Pages\CreateAiPromptVersion;
use App\Filament\Resources\AiPromptVersions\Pages\EditAiPromptVersion;
use App\Filament\Resources\AiPromptVersions\Pages\ListAiPromptVersions;
use App\Filament\Resources\AiPromptVersions\Schemas\AiPromptVersionForm;
use App\Filament\Resources\AiPromptVersions\Tables\AiPromptVersionsTable;
use App\Models\AiPromptVersion;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

class AiPromptVersionResource extends Resource
{
    protected static ?string $model = AiPromptVersion::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedDocumentText;

    protected static string|UnitEnum|null $navigationGroup = 'AI';

    protected static ?string $navigationLabel = 'Prompt versions';

    protected static ?string $modelLabel = 'Prompt version';

    protected static ?int $navigationSort = 1;

    public static function form(Schema $schema): Schema
    {
        return AiPromptVersionForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return AiPromptVersionsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListAiPromptVersions::route('/'),
            'create' => CreateAiPromptVersion::route('/create'),
            'edit' => EditAiPromptVersion::route('/{record}/edit'),
        ];
    }
}
