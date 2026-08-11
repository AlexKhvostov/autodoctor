<?php

namespace App\Models;

use App\Models\Concerns\ScrubsUtf8Attributes;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AssistantMessage extends Model
{
    use HasUuids;
    use ScrubsUtf8Attributes;

    public $timestamps = false;

    protected $guarded = [];

    protected function utf8Attributes(): array
    {
        return ['content'];
    }

    protected function casts(): array
    {
        return [
            'created_at' => 'immutable_datetime',
        ];
    }

    public function thread(): BelongsTo
    {
        return $this->belongsTo(AssistantThread::class, 'assistant_thread_id');
    }
}
