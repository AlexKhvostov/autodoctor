<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WorkCatalogItem extends Model
{
    use HasUuids;

    protected $fillable = ['code', 'localized_name'];

    protected function casts(): array
    {
        return ['localized_name' => 'array'];
    }

    public function rules(): HasMany
    {
        return $this->hasMany(MaintenanceRule::class);
    }

    public function historyAnswers(): HasMany
    {
        return $this->hasMany(HistoryAnswer::class);
    }

    public function serviceRecordItems(): HasMany
    {
        return $this->hasMany(ServiceRecordItem::class);
    }
}
