<?php

namespace App\Filament\Resources\GuestProfiles\Pages;

use App\Filament\Resources\GuestProfiles\GuestProfileResource;
use Filament\Resources\Pages\ListRecords;

class ListGuestProfiles extends ListRecords
{
    protected static string $resource = GuestProfileResource::class;
}
