<?php

namespace Tests\Feature;

use App\Models\AssistantMessage;
use App\Models\GuestProfile;
use App\Models\ServiceRecord;
use App\Models\TelegramBotUser;
use Database\Seeders\AiConfigSeeder;
use Database\Seeders\MaintenanceV1Seeder;
use Database\Seeders\MaintenanceV2Seeder;
use Carbon\CarbonImmutable;
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
        Http::fake(function ($request) {
            $url = $request->url();
            if (str_contains($url, 'api.telegram.org')) {
                return Http::response(['ok' => true], 200);
            }
            $system = (string) data_get($request->data(), 'messages.0.content');
            if (str_contains($system, 'Extract a car card')) {
                return Http::response([
                    'choices' => [[
                        'message' => [
                            'content' => '{"make":"Volkswagen","model":"Polo","production_year":2014,"fuel_type":"petrol","mileage_km":null,"vin":null,"displacement_cc":null}',
                        ],
                    ]],
                ], 200);
            }

            return Http::response([
                'choices' => [[
                    'message' => ['content' => 'Похоже, Polo 2014. Напишите пробег, если помните.'],
                ]],
            ], 200);
        });
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
            if (! str_contains($request->url(), '/sendMessage')) {
                return false;
            }
            $text = (string) ($request['text'] ?? '');

            return str_contains($text, 'Polo 2014')
                && ! str_contains($request->body(), 'save_vehicle');
        });
        Http::assertSent(function ($request): bool {
            if (! str_contains($request->url(), '/sendMessage')) {
                return false;
            }
            $text = (string) ($request['text'] ?? '');

            return str_contains($text, (string) config('telegram.messages.save_summary_intro'))
                && str_contains($text, 'Volkswagen Polo')
                && str_contains($text, '2014')
                && str_contains($request->body(), 'save_vehicle')
                && ! str_contains($text, 'пробег, если помните');
        });
        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), 'routellm.abacus.ai');
        });
    }

    public function test_save_button_is_not_offered_until_card_is_complete(): void
    {
        $this->seed(AiConfigSeeder::class);
        config(['ai.providers.abacus.api_key' => 'test-key']);
        Http::fake(function ($request) {
            $url = $request->url();
            if (str_contains($url, 'api.telegram.org')) {
                return Http::response(['ok' => true], 200);
            }
            $system = (string) data_get($request->data(), 'messages.0.content');
            if (str_contains($system, 'Extract a car card')) {
                return Http::response([
                    'choices' => [[
                        'message' => [
                            'content' => '{"make":"Volkswagen","model":"Polo","production_year":null,"fuel_type":null,"mileage_km":null,"vin":null,"displacement_cc":null}',
                        ],
                    ]],
                ], 200);
            }

            return Http::response([
                'choices' => [[
                    'message' => ['content' => 'Какой год выпуска?'],
                ]],
            ], 200);
        });
        Http::preventStrayRequests();

        $user = TelegramBotUser::query()->create(['telegram_user_id' => 80003]);
        $user->setAllowlisted(true);

        $this->postJson('/telegram/webhook', $this->update(80003, 'у меня поло'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), '/sendMessage')
                && str_contains((string) $request['text'], 'год выпуска');
        });
        Http::assertNotSent(function ($request): bool {
            return str_contains($request->url(), '/sendMessage')
                && str_contains($request->body(), 'save_vehicle');
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

    public function test_work_message_waits_for_clarification_before_journal_summary(): void
    {
        CarbonImmutable::setTestNow('2026-09-03 12:00:00');
        $this->seed(AiConfigSeeder::class);
        $this->seed(MaintenanceV1Seeder::class);
        $this->seed(MaintenanceV2Seeder::class);
        config(['ai.providers.abacus.api_key' => 'test-key']);

        $fakeLlm = function ($request) {
            $url = $request->url();
            if (str_contains($url, 'api.telegram.org')) {
                return Http::response(['ok' => true], 200);
            }

            $system = (string) data_get($request->data(), 'messages.0.content');
            if (str_contains($system, 'Extract a car card')) {
                return Http::response([
                    'choices' => [[
                        'message' => [
                            'content' => '{"make":"Volkswagen","model":"Polo","production_year":2014,"fuel_type":"petrol","mileage_km":148000,"vin":null,"displacement_cc":null}',
                        ],
                    ]],
                ], 200);
            }
            if (str_contains($system, 'обновляешь память')) {
                return Http::response([
                    'choices' => [[
                        'message' => [
                            'content' => '{"vehicle":{"add":[],"remove":[]},"user":{"add":[],"remove":[]},"issues":[],"skill_signal":{"delta":null,"reason":null}}',
                        ],
                    ]],
                ], 200);
            }
            if (str_contains($system, 'maintenance work event')) {
                $transcript = (string) data_get($request->data(), 'messages.1.content');
                $complete = str_contains($transcript, '150000') || str_contains($transcript, '150 000');

                return Http::response([
                    'choices' => [[
                        'message' => [
                            'content' => $complete
                                ? '{"has_work_event":true,"work_codes":["tire_condition_inspection"],"service_date":"2026-09-03","service_date_status":"known","mileage_km":150000,"mileage_status":"known","note":"Замена всех 4 колёс"}'
                                : '{"has_work_event":true,"work_codes":["tire_condition_inspection"],"service_date":"2026-09-03","service_date_status":"known","mileage_km":null,"mileage_status":"missing","note":"Замена всех 4 колёс"}',
                        ],
                    ]],
                ], 200);
            }

            $messages = $request->data()['messages'] ?? [];
            $lastUser = '';
            foreach (array_reverse($messages) as $message) {
                if (($message['role'] ?? '') === 'user') {
                    $lastUser = (string) ($message['content'] ?? '');
                    break;
                }
            }
            if (str_contains($lastUser, '150000')) {
                return Http::response([
                    'choices' => [[
                        'message' => ['content' => 'Запишу: сегодня замена колёс, пробег 150 000 км.'],
                    ]],
                ], 200);
            }

            return Http::response([
                'choices' => [[
                    'message' => ['content' => 'Понял, сегодня поменяли колёса. Какой пробег сейчас, если помните?'],
                ]],
            ], 200);
        };

        Http::fake($fakeLlm);
        Http::preventStrayRequests();

        $user = TelegramBotUser::query()->create(['telegram_user_id' => 80004]);
        $user->setAllowlisted(true);

        $this->postJson('/telegram/webhook', $this->update(80004, 'polo 2014'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();
        $this->postJson('/telegram/webhook', $this->callbackUpdate(80004, 'save_vehicle'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();
        $this->postJson('/telegram/webhook', $this->update(80004, 'сегодня поменял колеса'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        Http::assertSent(function ($request): bool {
            if (! str_contains($request->url(), '/sendMessage')) {
                return false;
            }
            $text = (string) ($request['text'] ?? '');

            return str_contains($text, 'поменяли колёса');
        });
        Http::assertNotSent(function ($request): bool {
            if (! str_contains($request->url(), '/sendMessage')) {
                return false;
            }

            return str_contains((string) ($request['text'] ?? ''), (string) config('telegram.messages.save_work_summary_intro'));
        });

        $this->postJson('/telegram/webhook', $this->update(80004, '150000'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        Http::assertSent(function ($request): bool {
            if (! str_contains($request->url(), '/sendMessage')) {
                return false;
            }
            $text = (string) ($request['text'] ?? '');

            return str_contains($text, (string) config('telegram.messages.save_work_summary_intro'))
                && str_contains($text, 'Проверка состояния шин')
                && str_contains($text, '03.09.2026')
                && str_contains($text, '150000')
                && str_contains($request->body(), 'save_service_record');
        });

        CarbonImmutable::setTestNow();
    }

    public function test_save_service_record_button_creates_journal_entry(): void
    {
        CarbonImmutable::setTestNow('2026-09-03 12:00:00');
        $this->seed(AiConfigSeeder::class);
        $this->seed(MaintenanceV1Seeder::class);
        $this->seed(MaintenanceV2Seeder::class);
        config(['ai.providers.abacus.api_key' => 'test-key']);
        Http::fake(function ($request) {
            $url = $request->url();
            if (str_contains($url, 'api.telegram.org')) {
                return Http::response(['ok' => true], 200);
            }
            $system = (string) data_get($request->data(), 'messages.0.content');
            if (str_contains($system, 'Extract a car card')) {
                return Http::response([
                    'choices' => [[
                        'message' => [
                            'content' => '{"make":"Volkswagen","model":"Polo","production_year":2014,"fuel_type":"petrol","mileage_km":148000,"vin":null,"displacement_cc":null}',
                        ],
                    ]],
                ], 200);
            }
            if (str_contains($system, 'maintenance work event')) {
                return Http::response([
                    'choices' => [[
                        'message' => [
                            'content' => '{"has_work_event":true,"work_codes":["tire_condition_inspection"],"service_date":"2026-09-03","service_date_status":"known","mileage_km":148000,"mileage_status":"known","note":"Замена всех 4 колёс"}',
                        ],
                    ]],
                ], 200);
            }

            return Http::response([
                'choices' => [[
                    'message' => ['content' => 'Понял.'],
                ]],
            ], 200);
        });
        Http::preventStrayRequests();

        $user = TelegramBotUser::query()->create(['telegram_user_id' => 80005]);
        $user->setAllowlisted(true);

        $this->postJson('/telegram/webhook', $this->update(80005, 'polo 2014'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();
        $this->postJson('/telegram/webhook', $this->callbackUpdate(80005, 'save_vehicle'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();
        $this->postJson('/telegram/webhook', $this->update(80005, 'сегодня поменял колеса'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();
        $this->postJson('/telegram/webhook', $this->callbackUpdate(80005, 'save_service_record'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        $this->assertDatabaseCount('service_records', 1);
        $this->assertDatabaseHas('service_records', [
            'mileage_value' => 148000,
            'note' => 'Замена всех 4 колёс',
        ]);
        $this->assertSame(
            '2026-09-03',
            ServiceRecord::query()->value('service_date')?->format('Y-m-d'),
        );
        Http::assertSent(function ($request): bool {
            return str_contains($request->url(), '/sendMessage')
                && str_contains((string) $request['text'], 'Записал в журнал');
        });

        CarbonImmutable::setTestNow();
    }

    public function test_complaint_does_not_offer_journal_save(): void
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
            $system = (string) data_get($request->data(), 'messages.0.content');
            if (str_contains($system, 'Extract a car card')) {
                return Http::response([
                    'choices' => [[
                        'message' => [
                            'content' => '{"make":"Volkswagen","model":"Polo","production_year":2014,"fuel_type":"petrol","mileage_km":148000,"vin":null,"displacement_cc":null}',
                        ],
                    ]],
                ], 200);
            }
            if (str_contains($system, 'maintenance work event')) {
                return Http::response([
                    'choices' => [[
                        'message' => [
                            'content' => '{"has_work_event":false,"work_codes":[],"service_date":null,"mileage_km":null,"note":null}',
                        ],
                    ]],
                ], 200);
            }

            return Http::response([
                'choices' => [[
                    'message' => ['content' => 'Похоже на стук в подвеске. Когда слышите?'],
                ]],
            ], 200);
        });
        Http::preventStrayRequests();

        $user = TelegramBotUser::query()->create(['telegram_user_id' => 80006]);
        $user->setAllowlisted(true);

        $this->postJson('/telegram/webhook', $this->update(80006, 'polo 2014'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();
        $this->postJson('/telegram/webhook', $this->callbackUpdate(80006, 'save_vehicle'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();
        $this->postJson('/telegram/webhook', $this->update(80006, 'стучит подвеска'), [
            'X-Telegram-Bot-Api-Secret-Token' => 'test-secret',
        ])->assertOk();

        Http::assertNotSent(function ($request): bool {
            return str_contains($request->url(), '/sendMessage')
                && str_contains($request->body(), 'save_service_record');
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
