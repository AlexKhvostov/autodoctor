<?php

namespace Tests\Unit;

use App\Services\Telegram\TelegramInitDataValidator;
use Tests\TestCase;

class TelegramInitDataValidatorTest extends TestCase
{
    public function test_accepts_signed_init_data(): void
    {
        config(['telegram.bot_token' => 'TESTTOKEN']);
        $initData = $this->sign(['auth_date' => (string) time(), 'user' => '{"id":70001,"first_name":"Anna"}']);

        $this->assertSame(70001, app(TelegramInitDataValidator::class)->userId($initData));
    }

    public function test_rejects_tampered_hash(): void
    {
        config(['telegram.bot_token' => 'TESTTOKEN']);
        $initData = $this->sign(['auth_date' => (string) time(), 'user' => '{"id":70001}']).'tamper';

        $this->assertNull(app(TelegramInitDataValidator::class)->userId($initData));
    }

    /**
     * @param  array<string, string>  $fields
     */
    private function sign(array $fields): string
    {
        ksort($fields);
        $pairs = [];
        foreach ($fields as $key => $value) {
            $pairs[] = $key.'='.$value;
        }
        $secret = hash_hmac('sha256', 'TESTTOKEN', 'WebAppData', true);
        $fields['hash'] = hash_hmac('sha256', implode("\n", $pairs), $secret);

        return http_build_query($fields);
    }
}
