<?php

namespace App\Filament\Resources\AiPromptVersions\Tables;

use App\Models\AiPromptVersion;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class AiPromptVersionsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')->sortable(),
                TextColumn::make('code')->searchable()->sortable(),
                TextColumn::make('name')->searchable()->sortable(),
                TextColumn::make('status')->badge()->sortable(),
                TextColumn::make('updated_at')->dateTime()->sortable(),
            ])
            ->defaultSort('id', 'desc')
            ->filters([])
            ->recordActions([
                EditAction::make(),
                Action::make('approve')
                    ->label('Approve')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->visible(fn (AiPromptVersion $record): bool => $record->status !== AiPromptVersion::STATUS_APPROVED)
                    ->requiresConfirmation()
                    ->action(function (AiPromptVersion $record): void {
                        $record->approve();
                        Notification::make()
                            ->title('Prompt approved')
                            ->success()
                            ->send();
                    }),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
