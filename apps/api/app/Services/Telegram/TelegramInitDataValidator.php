<?php

namespace App\Services\Telegram;

class TelegramInitDataValidator
{
    public function userId(string $initData): ?int
    {
        $values = $this->verifiedValues($initData);
        if ($values === null) {
            return null;
        }

        $userRaw = $values['user'] ?? '';
        $user = json_decode($userRaw, true);
        $id = is_array($user) ? (int) ($user['id'] ?? 0) : 0;

        return $id > 0 ? $id : null;
    }

    /**
     * @return array<string, string>|null
     */
    public function verifiedValues(string $initData): ?array
    {
        $token = (string) config('telegram.bot_token');
        if ($token === '' || trim($initData) === '') {
            return null;
        }

        parse_str($initData, $data);
        if (! is_array($data) || ! isset($data['hash']) || ! is_string($data['hash'])) {
            return null;
        }

        $hash = $data['hash'];
        unset($data['hash']);
        ksort($data);

        $pairs = [];
        foreach ($data as $key => $value) {
            if (! is_string($key) || ! is_string($value)) {
                continue;
            }
            $pairs[] = $key.'='.$value;
        }
        $checkString = implode("\n", $pairs);
        $secret = hash_hmac('sha256', $token, 'WebAppData', true);
        $computed = hash_hmac('sha256', $checkString, $secret);

        if (! hash_equals($computed, $hash)) {
            return null;
        }

        $authDate = (int) ($data['auth_date'] ?? 0);
        if ($authDate < 1 || abs(time() - $authDate) > 86400) {
            return null;
        }

        return $data;
    }
}
