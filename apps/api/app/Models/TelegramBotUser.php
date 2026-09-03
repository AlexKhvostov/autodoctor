<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Carbon;

class TelegramBotUser extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'telegram_user_id' => 'integer',
            'message_count' => 'integer',
            'last_message_at' => 'datetime',
            'is_allowlisted' => 'boolean',
            'allowlisted_at' => 'datetime',
            'removed_from_allowlist_at' => 'datetime',
            'access_requested_at' => 'datetime',
        ];
    }

    public function scopeAllowlisted(Builder $query): Builder
    {
        return $query->where('is_allowlisted', true);
    }

    public function displayName(): string
    {
        $parts = array_filter([$this->first_name, $this->last_name]);
        if ($parts !== []) {
            return implode(' ', $parts);
        }
        if (filled($this->username)) {
            return '@'.$this->username;
        }

        return 'ID '.$this->telegram_user_id;
    }

    public function setAllowlisted(bool $allowed): void
    {
        if ($allowed) {
            $this->forceFill([
                'is_allowlisted' => true,
                'allowlisted_at' => Carbon::now(),
                'removed_from_allowlist_at' => null,
            ])->save();

            return;
        }

        $this->forceFill([
            'is_allowlisted' => false,
            'removed_from_allowlist_at' => Carbon::now(),
        ])->save();
    }
}
