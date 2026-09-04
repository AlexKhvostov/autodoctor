<?php

namespace App\Filament\Resources\TokenTopupPackages\Pages;

use App\Filament\Resources\TokenTopupPackages\TokenTopupPackageResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListTokenTopupPackages extends ListRecords
{
    protected static string $resource = TokenTopupPackageResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
