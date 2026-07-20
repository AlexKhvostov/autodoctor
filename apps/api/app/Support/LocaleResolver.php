<?php

namespace App\Support;

use Illuminate\Http\Request;

class LocaleResolver
{
    public const FALLBACK_LOCALE = 'ru';

    private const SUPPORTED_LOCALES = ['ru', 'en'];

    public static function fromRequest(Request $request): string
    {
        return self::fromAcceptLanguage($request->header('Accept-Language'));
    }

    public static function fromAcceptLanguage(mixed $header): string
    {
        if (! is_string($header) || trim($header) === '') {
            return self::FALLBACK_LOCALE;
        }

        $candidates = [];

        foreach (explode(',', $header) as $position => $entry) {
            $parts = explode(';', trim($entry));
            $tag = array_shift($parts);
            $quality = 1.0;

            foreach ($parts as $parameter) {
                if (preg_match('/^\s*q=([01](?:\.\d{0,3})?)\s*$/i', $parameter, $matches) === 1) {
                    $quality = (float) $matches[1];
                }
            }

            $locale = self::normalize($tag);
            if ($locale !== null && $quality > 0) {
                $candidates[] = compact('locale', 'quality', 'position');
            }
        }

        usort(
            $candidates,
            fn (array $left, array $right): int => $right['quality'] <=> $left['quality']
                ?: $left['position'] <=> $right['position'],
        );

        return $candidates[0]['locale'] ?? self::FALLBACK_LOCALE;
    }

    public static function normalize(mixed $locale): ?string
    {
        if (! is_string($locale)) {
            return null;
        }

        $base = strtolower(explode('-', str_replace('_', '-', trim($locale)), 2)[0]);

        return in_array($base, self::SUPPORTED_LOCALES, true) ? $base : null;
    }

    public static function hasAcceptLanguage(Request $request): bool
    {
        $header = $request->header('Accept-Language');

        return is_string($header) && trim($header) !== '';
    }
}
