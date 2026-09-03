<?php

namespace Tests\Feature;

use App\Models\GuestProfile;
use App\Models\TelegramBotUser;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class TelegramWebhookTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config([
            'telegram.bot_token' => 'TESTTOKEN',
            'telegram.webhook_secret' => 'test-secret',
            'telegram.allowlist_ids' => '',
            'telegram.api_base' => 'https://api.telegram.org',
        ]);

        Http::fake([
            'api.telegram.org/*' => Http::response(['ok' => true], 200),
        ]);
        Http::preventStrayRequests();
    }

    public function test_rejects_missing_webhook_secret(): void
    {
        $this->postJson('/telegram/webhook', $this->update(1001, '/start'))
            ->assertUnauthorized();

        Http::assertNothingSent();
        $this->assertDatabaseCount('guest_profiles', 0);
        $this->assertDatabaseCount('telegram_bot_users', 0);
    }

    public function test_denied_user_is_logged_as_writer_without_guest_profile(): void
    {
        $this->postJson('/telegram/webhook', $this->update(1001, '/start', 'stranger'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), '/botTESTTOKEN/sendMessage')
                && $request['chat_id'] === 1001
                && $request['text'] === config('telegram.messages.closed_pilot');
        });
        $this->assertDatabaseCount('guest_profiles', 0);
        $this->assertDatabaseHas('telegram_bot_users', [
            'telegram_user_id' => 1001,
            'username' => 'stranger',
            'is_allowlisted' => false,
            'message_count' => 1,
        ]);
        $this->assertNotNull(TelegramBotUser::query()->where('telegram_user_id', 1001)->value('last_message_at'));
    }

    public function test_env_allowlisted_user_is_remembered_on_start(): void
    {
        config(['telegram.allowlist_ids' => '70001']);

        $this->postJson('/telegram/webhook', $this->update(70001, '/start', 'anna'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), '/botTESTTOKEN/sendMessage')
                && $request['text'] === config('telegram.messages.start');
        });
        $this->assertDatabaseHas('guest_profiles', [
            'telegram_id' => 70001,
            'telegram_username' => 'anna',
        ]);
        $this->assertDatabaseHas('telegram_bot_users', [
            'telegram_user_id' => 70001,
            'username' => 'anna',
        ]);
    }

    public function test_database_allowlist_lets_user_through(): void
    {
        $user = TelegramBotUser::query()->create([
            'telegram_user_id' => 80001,
        ]);
        $user->setAllowlisted(true);

        $this->postJson('/telegram/webhook', $this->update(80001, 'у меня поло 2014'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        $this->assertNotNull(GuestProfile::query()->where('telegram_id', 80001)->first());
        Http::assertSent(function ($request): bool {
            return $request['text'] === config('telegram.messages.continue');
        });
        $this->assertSame(1, TelegramBotUser::query()->where('telegram_user_id', 80001)->value('message_count'));
    }

    /**
     * @return array<string, mixed>
     */
    private function update(int $userId, string $text, ?string $username = null): array
    {
        return [
            'update_id' => 1,
            'message' => [
                'message_id' => 1,
                'from' => [
                    'id' => $userId,
                    'is_bot' => false,
                    'first_name' => 'Test',
                    'username' => $username,
                ],
                'chat' => [
                    'id' => $userId,
                    'type' => 'private',
                ],
                'text' => $text,
            ],
        ];
    }
}
