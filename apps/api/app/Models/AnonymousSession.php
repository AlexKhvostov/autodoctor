<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AnonymousSession extends Model
{
    use HasUuids;

    protected $fillable = [
        'token_hash',
        'status',
        'locale',
        'platform',
        'app_version',
        'last_activity_at',
        'expires_at',
        'version',
    ];

    protected $hidden = ['token_hash'];

    protected function casts(): array
    {
        return [
            'last_activity_at' => 'immutable_datetime',
            'expires_at' => 'immutable_datetime',
            'version' => 'integer',
        ];
    }

    public function consents(): HasMany
    {
        return $this->hasMany(Consent::class);
    }

    public function vehicles(): HasMany
    {
        return $this->hasMany(Vehicle::class);
    }
}
