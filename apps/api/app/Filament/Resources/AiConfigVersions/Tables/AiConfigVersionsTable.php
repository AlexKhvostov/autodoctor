<?php

namespace App\Filament\Resources\AiConfigVersions\Tables;

use App\Models\AiConfigVersion;
use App\Services\Ai\LlmClient;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Throwable;

class AiConfigVersionsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')->sortable(),
                IconColumn::make('is_active')->boolean()->label('Active'),
                IconColumn::make('enabled')->boolean(),
                TextColumn::make('primary_provider')->badge(),
                TextColumn::make('primary_model'),
                TextColumn::make('fallback_provider')->badge()->placeholder('—'),
                TextColumn::make('promptVersion.code')->label('Prompt'),
                TextColumn::make('updated_at')->dateTime()->sortable(),
            ])
            ->defaultSort('id', 'desc')
            ->recordActions([
                EditAction::make(),
                Action::make('activate')
                    ->label('Activate')
                    ->icon('heroicon-o-bolt')
                    ->color('warning')
                    ->visible(fn (AiConfigVersion $record): bool => ! $record->is_active)
                    ->requiresConfirmation()
                    ->action(function (AiConfigVersion $record): void {
                        $record->activate();
                        Notification::make()
                            ->title('Config activated')
                            ->success()
                            ->send();
                    }),
                Action::make('testConnection')
                    ->label('Test connection')
                    ->icon('heroicon-o-signal')
                    ->action(function (AiConfigVersion $record, LlmClient $llm): void {
                        try {
                            $result = $llm->testConnection(
                                provider: $record->primary_provider,
                                model: $record->primary_model,
                            );
                            Notification::make()
                                ->title('Connection OK')
                                ->body(mb_substr($result, 0, 180))
                                ->success()
                                ->send();
                        } catch (Throwable $exception) {
                            Notification::make()
                                ->title('Connection failed')
                                ->body($exception->getMessage())
                                ->danger()
                                ->send();
                        }
                    }),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
