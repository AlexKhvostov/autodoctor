<?php

namespace App\Filament\Resources\AiConfigVersions\Schemas;

use App\Models\AiPromptVersion;
use Filament\Forms\Components\Placeholder;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class AiConfigVersionForm
{
    public static function configure(Schema $schema): Schema
    {
        $providers = collect(config('ai.whitelist', []))
            ->mapWithKeys(fn (string $key) => [
                $key => config("ai.providers.{$key}.label", $key),
            ])
            ->all();

        return $schema
            ->components([
                Placeholder::make('secrets_hint')
                    ->label('Secrets')
                    ->content(function (): string {
                        $lines = [];
                        foreach (config('ai.whitelist', []) as $provider) {
                            $configured = filled(config("ai.providers.{$provider}.api_key"));
                            $label = config("ai.providers.{$provider}.label", $provider);
                            $lines[] = $configured
                                ? "{$label}: key configured in .env"
                                : "{$label}: key missing in .env";
                        }

                        return implode(' · ', $lines);
                    })
                    ->columnSpanFull(),
                Select::make('primary_provider')
                    ->options($providers)
                    ->required(),
                TextInput::make('primary_model')
                    ->required()
                    ->maxLength(128),
                Select::make('fallback_provider')
                    ->options($providers)
                    ->nullable(),
                TextInput::make('fallback_model')
                    ->maxLength(128)
                    ->nullable(),
                Select::make('prompt_version_id')
                    ->label('Approved prompt')
                    ->options(
                        fn () => AiPromptVersion::query()
                            ->where('status', AiPromptVersion::STATUS_APPROVED)
                            ->orderByDesc('id')
                            ->get()
                            ->mapWithKeys(fn (AiPromptVersion $prompt) => [
                                $prompt->id => "#{$prompt->id} {$prompt->code} — {$prompt->name}",
                            ])
                            ->all()
                    )
                    ->required()
                    ->searchable(),
                TextInput::make('max_tokens')
                    ->numeric()
                    ->minValue(64)
                    ->maxValue(8192)
                    ->nullable(),
                TextInput::make('author')
                    ->maxLength(120)
                    ->nullable(),
                Toggle::make('enabled')
                    ->default(true),
                Toggle::make('is_active')
                    ->label('Active config')
                    ->helperText('Only one active config is used by the mobile chat API.')
                    ->default(false),
            ]);
    }
}
