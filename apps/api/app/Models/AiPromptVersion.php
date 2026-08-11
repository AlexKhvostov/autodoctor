<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AiPromptVersion extends Model
{
    protected $guarded = [];

    public const STATUS_DRAFT = 'draft';

    public const STATUS_APPROVED = 'approved';

    public const STATUS_ARCHIVED = 'archived';

    public function configVersions(): HasMany
    {
        return $this->hasMany(AiConfigVersion::class, 'prompt_version_id');
    }

    public function isApproved(): bool
    {
        return $this->status === self::STATUS_APPROVED;
    }

    public function approve(): void
    {
        $this->forceFill(['status' => self::STATUS_APPROVED])->save();
    }

    public function archive(): void
    {
        $this->forceFill(['status' => self::STATUS_ARCHIVED])->save();
    }
}
