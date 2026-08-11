<?php

namespace App\Models;

use App\Models\Concerns\HasUtf8Body;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VehicleAiNote extends Model
{
    use HasUuids;
    use HasUtf8Body;

    protected $guarded = [];

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }
}
