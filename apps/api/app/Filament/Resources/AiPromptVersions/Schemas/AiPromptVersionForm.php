<?php

namespace App\Filament\Resources\AiPromptVersions\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class AiPromptVersionForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('code')
                    ->required()
                    ->maxLength(120),
                TextInput::make('name')
                    ->required()
                    ->maxLength(180),
                Select::make('status')
                    ->options([
                        'draft' => 'Draft',
                        'approved' => 'Approved',
                        'archived' => 'Archived',
                    ])
                    ->required()
                    ->default('draft'),
                Textarea::make('body')
                    ->required()
                    ->rows(20)
                    ->columnSpanFull(),
            ]);
    }
}
