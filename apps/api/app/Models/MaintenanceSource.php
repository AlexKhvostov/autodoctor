<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MaintenanceSource extends Model
{
    use HasUuids;

    protected $fillable = [
        'source_kind', 'title', 'publisher', 'document_version', 'publication_status',
        'methodology_note', 'url', 'official_oem', 'effective_date', 'verified_at',
    ];

    protected function casts(): array
    {
        return [
            'official_oem' => 'boolean',
            'effective_date' => 'immutable_date',
            'verified_at' => 'immutable_datetime',
        ];
    }

    public function rules(): HasMany
    {
        return $this->hasMany(MaintenanceRule::class, 'source_id');
    }
}
