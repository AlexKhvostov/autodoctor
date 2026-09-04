<?php

namespace App\Filament\Resources\TokenTopupPackages\Pages;

use App\Filament\Resources\TokenTopupPackages\TokenTopupPackageResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditTokenTopupPackage extends EditRecord
{
    protected static string $resource = TokenTopupPackageResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
