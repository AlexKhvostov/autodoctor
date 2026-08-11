<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AiConfigVersion extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'enabled' => 'boolean',
            'is_active' => 'boolean',
            'max_tokens' => 'integer',
        ];
    }

    public function promptVersion(): BelongsTo
    {
        return $this->belongsTo(AiPromptVersion::class, 'prompt_version_id');
    }

    public function previousVersion(): BelongsTo
    {
        return $this->belongsTo(self::class, 'previous_version_id');
    }

    public static function active(): ?self
    {
        return self::query()
            ->with('promptVersion')
            ->where('is_active', true)
            ->where('enabled', true)
            ->latest('id')
            ->first();
    }

    public function activate(): void
    {
        self::query()->where('is_active', true)->update(['is_active' => false]);
        $this->forceFill(['is_active' => true, 'enabled' => true])->save();
    }
}
