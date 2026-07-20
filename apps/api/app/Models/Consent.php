<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Consent extends Model
{
    use HasUuids;

    protected $fillable = [
        'anonymous_session_id',
        'purpose',
        'document_version',
        'granted',
        'decided_at',
    ];

    protected function casts(): array
    {
        return [
            'granted' => 'boolean',
            'decided_at' => 'immutable_datetime',
        ];
    }

    public function anonymousSession(): BelongsTo
    {
        return $this->belongsTo(AnonymousSession::class);
    }
}
