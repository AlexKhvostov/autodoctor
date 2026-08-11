<?php

namespace App\Support;

final class Utf8
{
    public static function sanitize(?string $value): string
    {
        if ($value === null || $value === '') {
            return '';
        }

        $clean = function_exists('mb_scrub')
            ? mb_scrub($value, 'UTF-8')
            : (iconv('UTF-8', 'UTF-8//IGNORE', $value) ?: '');

        $clean = str_replace("\0", '', $clean);

        return $clean;
    }

    public static function isValid(?string $value): bool
    {
        if ($value === null || $value === '') {
            return true;
        }

        return mb_check_encoding($value, 'UTF-8');
    }
}
