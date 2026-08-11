<?php

namespace App\Filament\Resources\AiPromptVersions\Pages;

use App\Filament\Resources\AiPromptVersions\AiPromptVersionResource;
use App\Models\AiPromptVersion;
use Filament\Actions\Action;
use Filament\Actions\DeleteAction;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;

class EditAiPromptVersion extends EditRecord
{
    protected static string $resource = AiPromptVersionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('approve')
                ->label('Approve')
                ->icon('heroicon-o-check-badge')
                ->color('success')
                ->visible(fn (): bool => $this->record->status !== AiPromptVersion::STATUS_APPROVED)
                ->requiresConfirmation()
                ->action(function (): void {
                    /** @var AiPromptVersion $record */
                    $record = $this->record;
                    $record->approve();
                    Notification::make()
                        ->title('Prompt approved')
                        ->success()
                        ->send();
                }),
            DeleteAction::make(),
        ];
    }
}
