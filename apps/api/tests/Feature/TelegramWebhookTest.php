<?php

namespace Tests\Feature;

use App\Models\AssistantMessage;
use App\Models\GuestProfile;
use App\Models\TelegramBotUser;
use Database\Seeders\AiConfigSeeder;
use Database\Seeders\MaintenanceV1Seeder;
use Database\Seeders\MaintenanceV2Seeder;
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
            'telegram.owner_chat_id' => 287536885,
            'telegram.access_request_cooldown_minutes' => 60,
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

    public function test_denied_user_gets_closed_pilot_and_access_button(): void
    {
        $this->postJson('/telegram/webhook', $this->update(1001, '/start', 'stranger'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), '/botTESTTOKEN/sendMessage')
                && (int) $request['chat_id'] === 1001
                && $request['text'] === config('telegram.messages.closed_pilot')
                && str_contains($request->body(), 'access_request');
        });
        $this->assertDatabaseCount('guest_profiles', 0);
        $this->assertDatabaseHas('telegram_bot_users', [
            'telegram_user_id' => 1001,
            'username' => 'stranger',
            'is_allowlisted' => false,
            'message_count' => 1,
        ]);
    }

    public function test_access_request_notifies_owner_without_llm(): void
    {
        $this->postJson('/telegram/webhook', $this->callbackUpdate(1001, 'access_request', 'stranger'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), '/answerCallbackQuery');
        });
        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), '/sendMessage')
                && $request['chat_id'] === 287536885
                && str_contains((string) $request['text'], 'Запрос доступа')
                && str_contains((string) $request['text'], '1001')
                && str_contains((string) $request['text'], '@stranger');
        });
        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), '/sendMessage')
                && $request['chat_id'] === 1001
                && $request['text'] === config('telegram.messages.access_request_sent');
        });
        $this->assertNotNull(
            TelegramBotUser::query()->where('telegram_user_id', 1001)->value('access_requested_at')
        );
        $this->assertDatabaseCount('guest_profiles', 0);
    }

    public function test_access_request_is_rate_limited(): void
    {
        $user = TelegramBotUser::query()->create([
            'telegram_user_id' => 1001,
            'username' => 'stranger',
            'access_requested_at' => now(),
        ]);

        $this->postJson('/telegram/webhook', $this->callbackUpdate(1001, 'access_request', 'stranger'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        Http::assertNotSent(function ($request): bool {
            return str_contains($request->url(), '/sendMessage')
                && $request['chat_id'] === 287536885;
        });
        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), '/sendMessage')
                && $request['chat_id'] === 1001
                && $request['text'] === config('telegram.messages.access_request_already');
        });
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
        $this->assertDatabaseHas('assistant_threads', [
            'channel' => 'telegram',
            'title' => 'Telegram',
        ]);
    }

    public function test_start_shows_open_app_button_when_https_mini_app_configured(): void
    {
        config([
            'telegram.allowlist_ids' => '70001',
            'telegram.mini_app_url' => 'https://api-dev.autodoctor.by/telegram/app',
        ]);

        $this->assertSame(
            'https://api-dev.autodoctor.by/telegram/app',
            app(\App\Services\Telegram\TelegramBotClient::class)->miniAppUrl(),
        );

        $this->postJson('/telegram/webhook', $this->update(70001, '/start', 'anna'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        Http::assertSent(fn ($request): bool => str_contains($request->url(), 'setChatMenuButton'));
        Http::assertSent(function ($request): bool {
            if (! str_contains($request->url(), 'sendMessage')) {
                return false;
            }

            return data_get($request->data(), 'reply_markup.keyboard.0.0.web_app.url')
                === 'https://api-dev.autodoctor.by/telegram/app';
        });
    }

    public function test_allowlisted_message_goes_to_assistant(): void
    {
        $this->seed(AiConfigSeeder::class);
        config(['ai.providers.abacus.api_key' => 'test-key']);
        Http::fake([
            'api.telegram.org/*' => Http::response(['ok' => true], 200),
            'routellm.abacus.ai/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Похоже, Polo 2014. Нажмите Записать, когда подтвердите.']],
                ],
            ], 200),
        ]);
        Http::preventStrayRequests();

        $user = TelegramBotUser::query()->create([
            'telegram_user_id' => 80001,
        ]);
        $user->setAllowlisted(true);

        $this->postJson('/telegram/webhook', $this->update(80001, 'у меня поло 2014'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        $this->assertNotNull(GuestProfile::query()->where('telegram_id', 80001)->first());
        $this->assertTrue(AssistantMessage::query()->where('role', 'assistant')->exists());
        $this->assertDatabaseHas('assistant_threads', [
            'channel' => 'telegram',
        ]);
        Http::assertSent(function ($request): bool {
            $body = $request->body();

            return str_contains($request->url(), '/sendMessage')
                && str_contains((string) $request['text'], 'Polo 2014')
                && str_contains($body, 'save_vehicle');
        });
        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), 'routellm.abacus.ai');
        });
    }

    public function test_save_vehicle_button_creates_vehicle_from_dialogue(): void
    {
        $this->seed(AiConfigSeeder::class);
        $this->seed(MaintenanceV1Seeder::class);
        $this->seed(MaintenanceV2Seeder::class);
        config(['ai.providers.abacus.api_key' => 'test-key']);
        Http::fake(function ($request) {
            $url = $request->url();
            if (str_contains($url, 'api.telegram.org')) {
                return Http::response(['ok' => true], 200);
            }
            $payload = $request->data();
            $system = (string) data_get($payload, 'messages.0.content');
            if (str_contains($system, 'Extract a car card')) {
                return Http::response([
                    'choices' => [[
                        'message' => [
                            'content' => '{"make":"Volkswagen","model":"Polo","production_year":2014,"fuel_type":"petrol","mileage_km":148000,"vin":null,"displacement_cc":null}',
                        ],
                    ]],
                ], 200);
            }

            return Http::response([
                'choices' => [[
                    'message' => ['content' => 'Volkswagen Polo, 2014.'],
                ]],
            ], 200);
        });
        Http::preventStrayRequests();

        $user = TelegramBotUser::query()->create(['telegram_user_id' => 80002]);
        $user->setAllowlisted(true);

        $this->postJson('/telegram/webhook', $this->update(80002, 'у меня polo 2014, 148 тысяч'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        $this->postJson('/telegram/webhook', $this->callbackUpdate(80002, 'save_vehicle'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        $this->assertDatabaseHas('vehicle_configurations', [
            'make' => 'Volkswagen',
            'model' => 'Polo',
        ]);
        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), '/sendMessage')
                && str_contains((string) $request['text'], 'Записал');
        });
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

    /**
     * @return array<string, mixed>
     */
    private function callbackUpdate(int $userId, string $data, ?string $username = null): array
    {
        return [
            'update_id' => 2,
            'callback_query' => [
                'id' => 'cb-1',
                'from' => [
                    'id' => $userId,
                    'is_bot' => false,
                    'first_name' => 'Test',
                    'username' => $username,
                ],
                'message' => [
                    'message_id' => 2,
                    'chat' => [
                        'id' => $userId,
                        'type' => 'private',
                    ],
                ],
                'data' => $data,
            ],
        ];
    }
}
