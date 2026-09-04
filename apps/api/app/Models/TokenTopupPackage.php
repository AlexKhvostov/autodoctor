<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class TokenTopupPackage extends Model
{
    public const TYPE_STARS = 'stars';

    public const TYPE_MILEAGE = 'mileage';

    public const TYPE_INVITE = 'invite';

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'tokens_amount' => 'integer',
            'stars_price' => 'integer',
            'cooldown_hours' => 'integer',
            'enabled' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    /**
     * @param  Builder<self>  $query
     * @return Builder<self>
     */
    public function scopeEnabled(Builder $query): Builder
    {
        return $query->where('enabled', true);
    }

    /**
     * @param  Builder<self>  $query
     * @return Builder<self>
     */
    public function scopeOrdered(Builder $query): Builder
    {
        return $query->orderBy('sort_order')->orderBy('id');
    }

    public function formattedTokensLabel(): ?string
    {
        if ($this->tokens_amount === null) {
            return $this->type === self::TYPE_INVITE ? '+бонус' : null;
        }

        return '+'.number_format($this->tokens_amount, 0, '', ' ');
    }

    public function formattedStarsLabel(): string
    {
        if ($this->stars_price === null) {
            return 'скоро';
        }

        if ($this->stars_price === 0) {
            return '0 ⭐';
        }

        return $this->stars_price.' ⭐';
    }
}
