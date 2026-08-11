<?php

namespace App\Models;

use App\Models\Concerns\ScrubsUtf8Attributes;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AssistantThread extends Model
{
    use HasUuids;
    use ScrubsUtf8Attributes;

    public const STATUS_ACTIVE = 'active';

    public const STATUS_RESOLVED = 'resolved';

    public const STATUS_ARCHIVED = 'archived';

    public const TITLE_SOURCE_AUTO = 'auto';

    public const TITLE_SOURCE_USER = 'user';

    protected $guarded = [];

    protected function utf8Attributes(): array
    {
        return ['title'];
    }

    protected function casts(): array
    {
        return [
            'last_message_at' => 'immutable_datetime',
            'resolved_at' => 'immutable_datetime',
            'archived_at' => 'immutable_datetime',
        ];
    }

    public function guestProfile(): BelongsTo
    {
        return $this->belongsTo(GuestProfile::class);
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function anonymousSession(): BelongsTo
    {
        return $this->belongsTo(AnonymousSession::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(AssistantMessage::class)->orderBy('created_at');
    }

    public function issues(): HasMany
    {
        return $this->hasMany(VehicleIssue::class, 'source_thread_id');
    }

    public function isTitleLockedByUser(): bool
    {
        return ($this->title_source ?? self::TITLE_SOURCE_AUTO) === self::TITLE_SOURCE_USER;
    }

    public function applyStatus(string $status): void
    {
        $this->status = $status;
        $now = now();

        if ($status === self::STATUS_RESOLVED) {
            $this->resolved_at = $this->resolved_at ?? $now;
            $this->archived_at = null;
        } elseif ($status === self::STATUS_ARCHIVED) {
            $this->archived_at = $this->archived_at ?? $now;
            $this->dismissLinkedOpenIssues();
        } else {
            $this->status = self::STATUS_ACTIVE;
            $this->resolved_at = null;
            $this->archived_at = null;
        }
    }

    /**
     * Архив чата = пользователь убрал тему из внимания; follow-up по жалобам из него не нужен.
     */
    private function dismissLinkedOpenIssues(): void
    {
        if ($this->id === null) {
            return;
        }

        $open = VehicleIssue::query()
            ->where('source_thread_id', $this->id)
            ->whereIn('status', [
                VehicleIssue::STATUS_OPEN,
                VehicleIssue::STATUS_WATCHING,
            ])
            ->get();

        foreach ($open as $issue) {
            $issue->applyStatus(
                VehicleIssue::STATUS_DISMISSED,
                'Чат архивирован — проблема, вероятно, больше не беспокоит',
            );
            $issue->save();
        }
    }
}
