<?php

namespace App\Models;

use App\Models\Concerns\ScrubsUtf8Attributes;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

class VehicleIssue extends Model
{
    use HasUuids;
    use ScrubsUtf8Attributes;

    public const STATUS_OPEN = 'open';

    public const STATUS_WATCHING = 'watching';

    public const STATUS_RESOLVED = 'resolved';

    public const STATUS_DISMISSED = 'dismissed';

    public const STATUSES = [
        self::STATUS_OPEN,
        self::STATUS_WATCHING,
        self::STATUS_RESOLVED,
        self::STATUS_DISMISSED,
    ];

    public const URGENCY_LOW = 'low';

    public const URGENCY_MEDIUM = 'medium';

    public const URGENCY_HIGH = 'high';

    public const URGENCIES = [
        self::URGENCY_LOW,
        self::URGENCY_MEDIUM,
        self::URGENCY_HIGH,
    ];

    protected $guarded = [];

    protected function utf8Attributes(): array
    {
        return ['title', 'symptoms', 'recommendations', 'resolution_note'];
    }

    protected function casts(): array
    {
        return [
            'checks_suggested' => 'array',
            'checks_done' => 'array',
            'first_seen_at' => 'immutable_datetime',
            'last_touched_at' => 'immutable_datetime',
            'resolved_at' => 'immutable_datetime',
        ];
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function sourceThread(): BelongsTo
    {
        return $this->belongsTo(AssistantThread::class, 'source_thread_id');
    }

    public function isOpenLike(): bool
    {
        return in_array($this->status, [self::STATUS_OPEN, self::STATUS_WATCHING], true);
    }

    public function applyStatus(string $status, ?string $resolutionNote = null): void
    {
        $this->status = in_array($status, self::STATUSES, true) ? $status : self::STATUS_OPEN;
        $now = Carbon::now();

        if (in_array($this->status, [self::STATUS_RESOLVED, self::STATUS_DISMISSED], true)) {
            $this->resolved_at = $this->resolved_at ?? $now;
            if ($resolutionNote !== null && trim($resolutionNote) !== '') {
                $this->resolution_note = trim($resolutionNote);
            }
        } else {
            $this->resolved_at = null;
        }

        $this->last_touched_at = $now;
    }
}
