<?php

namespace App\Models;

use App\Models\Concerns\HasUtf8Body;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GuestProfileAiNote extends Model
{
    use HasUuids;
    use HasUtf8Body;

    protected $guarded = [];

    public function profile(): BelongsTo
    {
        return $this->belongsTo(GuestProfile::class, 'guest_profile_id');
    }
}
