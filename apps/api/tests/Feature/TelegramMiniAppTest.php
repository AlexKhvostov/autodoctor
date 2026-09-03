<?php

namespace Tests\Feature;

use App\Models\GuestProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TelegramMiniAppTest extends TestCase
{
    use RefreshDatabase;

    public function test_mini_app_page_is_served(): void
    {
        $this->get('/telegram/app')
            ->assertOk()
            ->assertSee('AutoDoctor', false)
            ->assertSee('telegram-web-app.js', false);
    }

    public function test_state_requires_telegram_init_data(): void
    {
        $this->getJson('/telegram/app/state')->assertUnauthorized();
    }

    public function test_state_returns_collected_card_for_allowlisted_user(): void
    {
        config(['telegram.bot_token' => 'TESTTOKEN', 'telegram.allowlist_ids' => '70001']);
        GuestProfile::query()->create([
            'telegram_id' => 70001,
            'telegram_username' => 'anna',
            'telegram_first_name' => 'Anna',
        ]);

        $this->withHeader('X-Telegram-Init-Data', $this->sign([
            'auth_date' => (string) time(),
            'user' => '{"id":70001,"first_name":"Anna"}',
        ]))->getJson('/telegram/app/state')
            ->assertOk()
            ->assertJsonPath('ok', true)
            ->assertJsonPath('allowed', true)
            ->assertJsonPath('greeting', '@anna')
            ->assertJsonPath('vehicle', null);
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
