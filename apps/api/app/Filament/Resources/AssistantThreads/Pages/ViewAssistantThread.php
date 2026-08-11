<?php

namespace App\Filament\Resources\AssistantThreads\Pages;

use App\Filament\Resources\AssistantThreads\AssistantThreadResource;
use Filament\Resources\Pages\ViewRecord;

class ViewAssistantThread extends ViewRecord
{
    protected static string $resource = AssistantThreadResource::class;

    protected function resolveRecord(int|string $key): \Illuminate\Database\Eloquent\Model
    {
        return static::getResource()::getEloquentQuery()
            ->with(['messages', 'guestProfile.user', 'vehicle.configuration'])
            ->whereKey($key)
            ->firstOrFail();
    }
}
