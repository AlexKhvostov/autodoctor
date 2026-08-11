<?php

namespace App\Models\Concerns;

use App\Support\Utf8;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;

trait ScrubsUtf8Attributes
{
    /**
     * @return list<string>
     */
    abstract protected function utf8Attributes(): array;

    public static function bootScrubsUtf8Attributes(): void
    {
        static::retrieved(function (Model $model): void {
            /** @var Model&object{utf8Attributes: callable(): array} $model */
            $attrs = $model->getAttributes();
            $changed = false;

            foreach ($model->utf8Attributes() as $key) {
                if (! array_key_exists($key, $attrs) || ! is_string($attrs[$key])) {
                    continue;
                }
                if (Utf8::isValid($attrs[$key])) {
                    continue;
                }
                $attrs[$key] = Utf8::sanitize($attrs[$key]);
                $changed = true;
            }

            if ($changed) {
                $model->setRawAttributes($attrs, true);
            }
        });

        static::saving(function (Model $model): void {
            foreach ($model->utf8Attributes() as $key) {
                $value = $model->getAttribute($key);
                if (! is_string($value)) {
                    continue;
                }
                $model->setAttribute($key, Utf8::sanitize($value));
            }
        });
    }
}
