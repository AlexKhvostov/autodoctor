<?php

namespace App\Services\Telegram;

use App\Models\TelegramBotUser;

class TelegramAllowlist
{
    public function allows(int $telegramUserId): bool
    {
        if ($telegramUserId <= 0) {
            return false;
        }

        return in_array($telegramUserId, $this->allowedIds(), true);
    }

    /**
     * @return list<int>
     */
    public function allowedIds(): array
    {
        $ids = array_merge($this->idsFromEnv(), $this->idsFromDatabase());

        return array_values(array_unique($ids));
    }

    /**
     * @return list<int>
     */
    public function idsFromEnv(): array
    {
        $raw = (string) config('telegram.allowlist_ids', '');

        return $this->parseIds($raw);
    }

    /**
     * @return list<int>
     */
    public function idsFromDatabase(): array
    {
        return TelegramBotUser::query()
            ->allowlisted()
            ->pluck('telegram_user_id')
            ->map(fn ($id): int => (int) $id)
            ->filter(fn (int $id): bool => $id > 0)
            ->values()
            ->all();
    }

    /**
     * @return list<int>
     */
    public function parseIds(string $raw): array
    {
        if (trim($raw) === '') {
            return [];
        }

        $ids = [];
        foreach (preg_split('/[\s,;]+/', $raw) ?: [] as $part) {
            $part = trim($part);
            if ($part === '' || ! ctype_digit($part)) {
                continue;
            }
            $id = (int) $part;
            if ($id > 0) {
                $ids[] = $id;
            }
        }

        return array_values(array_unique($ids));
    }
}
