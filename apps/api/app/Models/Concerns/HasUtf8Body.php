<?php

namespace App\Models\Concerns;

use App\Support\Utf8;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;

trait HasUtf8Body
{
    public static function bootHasUtf8Body(): void
    {
        static::retrieved(function (Model $model): void {
            if (! array_key_exists('body', $model->getAttributes())) {
                return;
            }

            $raw = $model->getAttributes()['body'];
            if (! is_string($raw) || Utf8::isValid($raw)) {
                return;
            }

            $model->setRawAttributes([
                ...$model->getAttributes(),
                'body' => Utf8::sanitize($raw),
            ], true);
        });
    }

    protected function body(): Attribute
    {
        return Attribute::make(
            get: fn (?string $value): string => Utf8::sanitize($value),
            set: fn (?string $value): string => Utf8::sanitize($value),
        );
    }
}
