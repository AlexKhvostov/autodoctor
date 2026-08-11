<?php

namespace App\Filament\Resources\GuestProfiles\Pages;

use App\Filament\Resources\GuestProfiles\GuestProfileResource;
use App\Models\GuestProfile;
use Filament\Resources\Pages\ViewRecord;
use Illuminate\Contracts\Support\Htmlable;

class ViewGuestProfile extends ViewRecord
{
    protected static string $resource = GuestProfileResource::class;

    public function getTitle(): string|Htmlable
    {
        /** @var GuestProfile $record */
        $record = $this->getRecord();

        if (filled($record->user?->name)) {
            return (string) $record->user->name;
        }
        if (filled($record->user?->email)) {
            return (string) $record->user->email;
        }

        return 'Гость '.mb_substr((string) $record->id, 0, 8);
    }

    protected function resolveRecord(int|string $key): \Illuminate\Database\Eloquent\Model
    {
        return static::getResource()::getEloquentQuery()
            ->with(['user'])
            ->whereKey($key)
            ->firstOrFail();
    }
}
