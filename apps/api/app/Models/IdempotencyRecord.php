<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class IdempotencyRecord extends Model
{
    use HasUuids;

    protected $fillable = [
        'scope',
        'operation',
        'idempotency_key',
        'request_hash',
        'status_code',
        'response_body',
    ];

    protected function casts(): array
    {
        return [
            'status_code' => 'integer',
            'response_body' => 'array',
        ];
    }
}
