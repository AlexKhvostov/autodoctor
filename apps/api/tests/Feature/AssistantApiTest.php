<?php

namespace Tests\Feature;

use App\Models\AiConfigVersion;
use App\Models\AiPromptVersion;
use Database\Seeders\AiConfigSeeder;
use Database\Seeders\MaintenanceV1Seeder;
use Database\Seeders\MaintenanceV2Seeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Tests\TestCase;

class AssistantApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(MaintenanceV1Seeder::class);
        $this->seed(MaintenanceV2Seeder::class);
        $this->seed(AiConfigSeeder::class);
        config([
            'ai.providers.abacus.api_key' => 'test-abacus-key',
            'ai.providers.deepseek.api_key' => 'test-deepseek-key',
        ]);
    }

    public function test_assistant_message_uses_active_config_and_returns_reply(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Проверьте тормозные колодки.']],
                ],
            ], 200),
        ]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Volkswagen',
                'model' => 'Golf',
                'production_year' => 2020,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1400],
                'mileage' => ['value' => 50000, 'unit' => 'km'],
            ])
            ->assertCreated()
            ->json('id');

        $response = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Скрипят тормоза',
                'thread_id' => (string) Str::uuid(),
                'history' => [
                    ['role' => 'user', 'content' => 'Привет'],
                    ['role' => 'assistant', 'content' => 'Здравствуйте'],
                ],
            ])
            ->assertOk()
            ->assertJsonPath('reply', 'Проверьте тормозные колодки.')
            ->assertJsonPath('provider', 'abacus')
            ->assertJsonPath('model', 'route-llm');

        $this->assertStringContainsString('ai-chat-system#', (string) $response->json('prompt_version'));

        $recorded = Http::recorded();
        $this->assertNotEmpty($recorded);
        $request = $recorded[0][0];
        $this->assertStringContainsString('routellm.abacus.ai', $request->url());
        $payload = json_decode($request->body(), true, flags: JSON_THROW_ON_ERROR);
        $system = (string) data_get($payload, 'messages.0.content');
        $this->assertStringContainsString('Volkswagen Golf', $system);
        $this->assertStringContainsString('Журнал обслуживания', $system);
        $this->assertStringContainsString('VIN: не задан', $system);
        $this->assertStringContainsString('Трансмиссия: не задано', $system);
        $this->assertStringContainsString('не отвечал', $system);
        $this->assertStringContainsString('План ТО', $system);
        $this->assertStringNotContainsString('Use this text as the `system` message', $system);
    }

    public function test_assistant_context_includes_transmission_and_history_answers(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'У вас АКПП, масло меняли на 180000 км.']],
                ],
            ], 200),
        ]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Volkswagen',
                'model' => 'Eos',
                'production_year' => 2007,
                'fuel_type' => 'diesel',
                'engine' => ['displacement_cc' => 2000],
                'transmission' => ['type' => 'automatic'],
                'drivetrain' => 'fwd',
                'mileage' => ['value' => 230000, 'unit' => 'km'],
            ])
            ->assertCreated()
            ->json('id');

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/history-answers', [
                'answers' => [[
                    'work_code' => 'engine_oil',
                    'answer' => 'done_known',
                    'performed_mileage_km' => 222000,
                ]],
            ])
            ->assertOk();

        $this->withHeaders($headers)
            ->getJson('/api/v1/vehicles/'.$vehicleId.'/maintenance-plan')
            ->assertOk();

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Какая у меня КПП и когда меняли масло?',
                'history' => [],
            ])
            ->assertOk();

        $recorded = Http::recorded();
        $this->assertNotEmpty($recorded);
        $payload = json_decode($recorded[0][0]->body(), true, flags: JSON_THROW_ON_ERROR);
        $system = (string) data_get($payload, 'messages.0.content');

        $this->assertStringContainsString('### Досье AutoDoctor', $system);
        $this->assertStringContainsString('## Уровень владельца', $system);
        $this->assertStringContainsString('уровень знаний:', $system);
        $this->assertStringContainsString('Трансмиссия: автомат', $system);
        $this->assertStringContainsString('Топливо: дизель', $system);
        $this->assertStringContainsString('Привод: передний привод', $system);
        $this->assertStringContainsString('VIN: не задан', $system);
        $this->assertStringContainsString('Моторное масло', $system);
        $this->assertStringNotContainsString('engine_oil', $system);
        $this->assertStringContainsString('пробег 222000 км', $system);
        $this->assertStringContainsString('не отвечал', $system);
        $this->assertStringContainsString('План ТО (актуальный снимок)', $system);
        $this->assertStringNotContainsString('План ещё не рассчитывался.', $system);
        $this->assertStringNotContainsString('срочность immediate', $system);
        $this->assertStringNotContainsString('срочность high', $system);
        $this->assertStringNotContainsString('статус overdue', $system);
    }

    public function test_first_message_returns_suggested_thread_title(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::sequence()
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Давайте сузим варианты.']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Хруст спереди слева']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => '[]']],
                    ],
                ]),
        ]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Other',
                'model' => 'Other model',
                'production_year' => 2020,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1600],
            ])
            ->assertCreated()
            ->json('id');

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Замечен слева спереди хруст при движении назад',
                'suggest_title' => true,
                'history' => [],
            ])
            ->assertOk()
            ->assertJsonPath('reply', 'Давайте сузим варианты.')
            ->assertJsonPath('title', 'Хруст спереди слева')
            ->assertJsonPath('notes_saved.vehicle', [])
            ->assertJsonPath('notes_saved.user', [])
            ->assertJsonPath('issues_saved', []);

        $this->assertCount(3, Http::recorded());
    }

    public function test_assistant_creates_issue_case_and_reuses_in_dossier(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::sequence()
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Понял, хруст слева. Когда сильнее?']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => json_encode([
                            'vehicle' => ['add' => [], 'remove' => []],
                            'user' => ['add' => [], 'remove' => []],
                            'issues' => ['upsert' => [[
                                'id' => null,
                                'title' => 'Хруст слева при заднем ходе',
                                'status' => 'open',
                                'urgency' => 'medium',
                                'symptoms' => 'хруст слева спереди при движении назад',
                                'checks_suggested' => ['проверить пыльник ШРУСа'],
                                'checks_done' => [],
                                'recommendations' => 'при усилении — к СТО',
                                'resolution_note' => null,
                            ]]],
                        ], JSON_UNESCAPED_UNICODE)]],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'По открытому хрусту — как сейчас?']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => '{"vehicle":{"add":[],"remove":[]},"user":{"add":[],"remove":[]},"issues":{"upsert":[]}}']],
                    ],
                ]),
        ]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Volkswagen',
                'model' => 'Golf',
                'production_year' => 2018,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1400],
            ])
            ->assertCreated()
            ->json('id');

        $first = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Хрустит слева спереди когда еду назад',
                'history' => [],
            ])
            ->assertOk()
            ->assertJsonPath('issues_saved.0.title', 'Хруст слева при заднем ходе')
            ->assertJsonPath('issues_saved.0.status', 'open')
            ->assertJsonPath('issues_saved.0.action', 'created');

        $issueId = (string) $first->json('issues_saved.0.id');
        $threadId = (string) $first->json('thread_id');
        $this->assertDatabaseHas('vehicle_issues', [
            'id' => $issueId,
            'vehicle_id' => $vehicleId,
            'status' => 'open',
            'source_thread_id' => $threadId,
        ]);

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Сегодня ещё стучит где-то спереди',
                'history' => [],
            ])
            ->assertOk();

        $recorded = Http::recorded();
        $this->assertGreaterThanOrEqual(3, count($recorded));
        $secondReplyPayload = json_decode($recorded[2][0]->body(), true, flags: JSON_THROW_ON_ERROR);
        $system = (string) data_get($secondReplyPayload, 'messages.0.content');
        $this->assertStringContainsString('Кейсы жалоб', $system);
        $this->assertStringContainsString('Хруст слева при заднем ходе', $system);
        $this->assertStringContainsString('статус: открыт', $system);
        $this->assertStringContainsString('срочность: средняя', $system);
        $this->assertStringNotContainsString('[open/medium]', $system);
    }

    public function test_archiving_thread_dismisses_linked_open_issues(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::sequence()
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Понял, хруст.']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => json_encode([
                            'vehicle' => ['add' => [], 'remove' => []],
                            'user' => ['add' => [], 'remove' => []],
                            'issues' => ['upsert' => [[
                                'id' => null,
                                'title' => 'Хруст слева',
                                'status' => 'open',
                                'urgency' => 'medium',
                                'symptoms' => 'хруст слева',
                                'checks_suggested' => [],
                                'checks_done' => [],
                                'recommendations' => null,
                                'resolution_note' => null,
                            ]]],
                        ], JSON_UNESCAPED_UNICODE)]],
                    ],
                ]),
        ]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Volkswagen',
                'model' => 'Golf',
                'production_year' => 2018,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1400],
            ])
            ->assertCreated()
            ->json('id');

        $first = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Хрустит слева',
                'history' => [],
            ])
            ->assertOk();

        $issueId = (string) $first->json('issues_saved.0.id');
        $threadId = (string) $first->json('thread_id');

        $this->withHeaders($headers)
            ->patchJson('/api/v1/vehicles/'.$vehicleId.'/assistant/threads/'.$threadId, [
                'status' => 'archived',
            ])
            ->assertOk()
            ->assertJsonPath('status', 'archived');

        $this->assertDatabaseHas('vehicle_issues', [
            'id' => $issueId,
            'status' => 'dismissed',
            'source_thread_id' => $threadId,
        ]);
    }

    public function test_assistant_saves_durable_notes_and_reuses_in_context(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::sequence()
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Понял, кабриолет. Когда появляется шум?']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => '{"vehicle":{"add":["Кабриолет"],"remove":[]},"user":{"add":[],"remove":[]}}']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'С учётом кабриолета уточним…']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => '{"vehicle":{"add":[],"remove":[]},"user":{"add":[],"remove":[]}}']],
                    ],
                ]),
        ]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Other',
                'model' => 'Other model',
                'production_year' => 2020,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1600],
            ])
            ->assertCreated()
            ->json('id');

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'У меня кабриолет, скрипит крыша',
                'history' => [],
            ])
            ->assertOk()
            ->assertJsonPath('notes_saved.vehicle.0', 'Кабриолет');

        $this->assertDatabaseHas('vehicle_ai_notes', [
            'vehicle_id' => $vehicleId,
            'body' => 'Кабриолет',
            'source' => 'chat',
        ]);

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Шум сильнее на трассе',
                'history' => [
                    ['role' => 'user', 'content' => 'У меня кабриолет, скрипит крыша'],
                    ['role' => 'assistant', 'content' => 'Понял, кабриолет. Когда появляется шум?'],
                ],
            ])
            ->assertOk();

        $secondChatRequest = Http::recorded()[2][0];
        $payload = json_decode($secondChatRequest->body(), true, flags: JSON_THROW_ON_ERROR);
        $system = (string) data_get($payload, 'messages.0.content');
        $this->assertStringContainsString('Кабриолет', $system);
        $this->assertStringContainsString('Шаг 2', $system);
    }

    public function test_assistant_saves_user_preference_notes_across_chats(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::sequence()
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Хорошо, Алексей, буду на ты.']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => '{"vehicle":{"add":[],"remove":[]},"user":{"add":["Зовут Алексей","Обращаться на ты"],"remove":[]}}']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Алексей, давай уточним шум.']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => '{"vehicle":{"add":[],"remove":[]},"user":{"add":[],"remove":[]}}']],
                    ],
                ]),
        ]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Other',
                'model' => 'Other model',
                'production_year' => 2020,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1600],
            ])
            ->assertCreated()
            ->json('id');

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Меня зовут Алексей, говори на ты',
                'history' => [],
            ])
            ->assertOk()
            ->assertJsonPath('notes_saved.user.0', 'Зовут Алексей')
            ->assertJsonPath('notes_saved.user.1', 'Обращаться на ты');

        $this->assertDatabaseHas('guest_profile_ai_notes', [
            'body' => 'Зовут Алексей',
            'source' => 'chat',
        ]);
        $this->assertDatabaseHas('guest_profile_ai_notes', [
            'body' => 'Обращаться на ты',
            'source' => 'chat',
        ]);

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Скрипят тормоза',
                'history' => [],
            ])
            ->assertOk();

        $secondChatRequest = Http::recorded()[2][0];
        $payload = json_decode($secondChatRequest->body(), true, flags: JSON_THROW_ON_ERROR);
        $system = (string) data_get($payload, 'messages.0.content');
        $this->assertStringContainsString('Зовут Алексей', $system);
        $this->assertStringContainsString('Обращаться на ты', $system);
        $this->assertStringContainsString('Заметки о пользователе', $system);
    }

    public function test_user_notes_survive_new_session_with_same_guest_profile(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::sequence()
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Понял, Алексей.']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => '{"vehicle":{"add":[],"remove":[]},"user":{"add":["Зовут Алексей"],"remove":[]}}']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Снова здравствуй.']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => '{"vehicle":{"add":[],"remove":[]},"user":{"add":[],"remove":[]}}']],
                    ],
                ]),
        ]);

        $first = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
            ])
            ->assertCreated();

        $profileId = $first->json('guest_profile_id');
        $this->assertNotEmpty($profileId);

        $headers1 = [
            'X-Session-Token' => $first->json('session_token'),
            'Idempotency-Key' => (string) Str::uuid(),
            'Accept-Language' => 'ru',
        ];

        $vehicleId = $this->withHeaders($headers1)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Other',
                'model' => 'Other model',
                'production_year' => 2020,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1600],
            ])
            ->assertCreated()
            ->json('id');

        $this->withHeaders($headers1)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Меня зовут Алексей',
                'history' => [],
            ])
            ->assertOk()
            ->assertJsonPath('notes_saved.user.0', 'Зовут Алексей');

        // Новая сессия с тем же guest_profile_id (как после истечения токена на устройстве).
        $second = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
                'guest_profile_id' => $profileId,
            ])
            ->assertCreated();

        $this->assertSame($profileId, $second->json('guest_profile_id'));

        $headers2 = [
            'X-Session-Token' => $second->json('session_token'),
            'Idempotency-Key' => (string) Str::uuid(),
            'Accept-Language' => 'ru',
        ];

        $vehicleId2 = $this->withHeaders($headers2)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Other',
                'model' => 'Other model',
                'production_year' => 2020,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1600],
            ])
            ->assertCreated()
            ->json('id');

        $this->withHeaders($headers2)
            ->postJson('/api/v1/vehicles/'.$vehicleId2.'/assistant/messages', [
                'message' => 'Скрипят тормоза',
                'history' => [],
            ])
            ->assertOk();

        $chatRequest = Http::recorded()[2][0];
        $payload = json_decode($chatRequest->body(), true, flags: JSON_THROW_ON_ERROR);
        $system = (string) data_get($payload, 'messages.0.content');
        $this->assertStringContainsString('Зовут Алексей', $system);
    }

    public function test_first_user_turn_gets_stage_1_hint(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::sequence()
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Уточню пару деталей.']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => '[]']],
                    ],
                ]),
        ]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Other',
                'model' => 'Other model',
                'production_year' => 2020,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1600],
            ])
            ->assertCreated()
            ->json('id');

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Скрипят тормоза',
                'history' => [],
            ])
            ->assertOk();

        $request = Http::recorded()[0][0];
        $payload = json_decode($request->body(), true, flags: JSON_THROW_ON_ERROR);
        $system = (string) data_get($payload, 'messages.0.content');
        $this->assertStringContainsString('Шаг 1', $system);
    }

    public function test_assistant_returns_disabled_when_config_off(): void
    {
        AiConfigVersion::query()->update(['enabled' => false, 'is_active' => false]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Other',
                'model' => 'Other model',
                'production_year' => 2020,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1600],
            ])
            ->assertCreated()
            ->json('id');

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Hello',
            ])
            ->assertStatus(503)
            ->assertJsonPath('error.code', 'AI_DISABLED');
    }

    public function test_assistant_falls_back_when_primary_fails(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::response(['error' => 'down'], 500),
            'api.deepseek.com/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Fallback reply']],
                ],
            ], 200),
        ]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Other',
                'model' => 'Other model',
                'production_year' => 2020,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1600],
            ])
            ->assertCreated()
            ->json('id');

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Test',
            ])
            ->assertOk()
            ->assertJsonPath('reply', 'Fallback reply')
            ->assertJsonPath('provider', 'deepseek');
    }

    public function test_seeder_creates_approved_prompt_and_active_config(): void
    {
        $this->assertDatabaseHas('ai_prompt_versions', [
            'code' => 'ai-chat-system',
            'status' => AiPromptVersion::STATUS_APPROVED,
        ]);
        $this->assertDatabaseHas('ai_config_versions', [
            'primary_provider' => 'abacus',
            'is_active' => true,
            'enabled' => true,
        ]);
    }

    public function test_assistant_persists_thread_and_messages(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::sequence()
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Уточню детали.']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => 'Скрип тормозов']],
                    ],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['content' => '{"vehicle":{"add":[],"remove":[]},"user":{"add":[],"remove":[]}}']],
                    ],
                ]),
        ]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Other',
                'model' => 'Other model',
                'production_year' => 2020,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1600],
            ])
            ->assertCreated()
            ->json('id');

        $threadId = (string) Str::uuid();
        $response = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Скрипят тормоза',
                'thread_id' => $threadId,
                'suggest_title' => true,
                'history' => [],
            ])
            ->assertOk()
            ->assertJsonPath('thread_id', $threadId)
            ->assertJsonPath('title', 'Скрип тормозов');

        $this->assertDatabaseHas('assistant_threads', [
            'id' => $threadId,
            'vehicle_id' => $vehicleId,
            'title' => 'Скрип тормозов',
        ]);
        $this->assertDatabaseHas('assistant_messages', [
            'assistant_thread_id' => $threadId,
            'role' => 'user',
            'content' => 'Скрипят тормоза',
        ]);
        $this->assertDatabaseHas('assistant_messages', [
            'assistant_thread_id' => $threadId,
            'role' => 'assistant',
            'content' => 'Уточню детали.',
        ]);
        $this->assertSame($threadId, $response->json('thread_id'));
    }

    public function test_threads_can_be_listed_renamed_resolved_and_archived(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Ок']],
                ],
            ], 200),
        ]);

        $headers = $this->sessionHeaders();
        $vehicleId = $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles', [
                'make' => 'Volkswagen',
                'model' => 'Golf',
                'production_year' => 2020,
                'fuel_type' => 'petrol',
                'engine' => ['displacement_cc' => 1400],
                'mileage' => ['value' => 50000, 'unit' => 'km'],
            ])
            ->assertCreated()
            ->json('id');

        $threadId = (string) Str::uuid();
        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Скрипят тормоза',
                'thread_id' => $threadId,
                'suggest_title' => false,
            ])
            ->assertOk();

        $this->withHeaders($headers)
            ->getJson('/api/v1/vehicles/'.$vehicleId.'/assistant/threads')
            ->assertOk()
            ->assertJsonPath('items.0.id', $threadId)
            ->assertJsonPath('items.0.status', 'active');

        $this->withHeaders($headers)
            ->patchJson('/api/v1/vehicles/'.$vehicleId.'/assistant/threads/'.$threadId, [
                'title' => 'Мои тормоза',
            ])
            ->assertOk()
            ->assertJsonPath('title', 'Мои тормоза')
            ->assertJsonPath('title_source', 'user');

        $this->withHeaders($headers)
            ->postJson('/api/v1/vehicles/'.$vehicleId.'/assistant/messages', [
                'message' => 'Ещё вопрос',
                'thread_id' => $threadId,
                'suggest_title' => true,
            ])
            ->assertOk();

        $this->assertDatabaseHas('assistant_threads', [
            'id' => $threadId,
            'title' => 'Мои тормоза',
            'title_source' => 'user',
        ]);

        $this->withHeaders($headers)
            ->patchJson('/api/v1/vehicles/'.$vehicleId.'/assistant/threads/'.$threadId, [
                'status' => 'resolved',
            ])
            ->assertOk()
            ->assertJsonPath('status', 'resolved');

        $this->withHeaders($headers)
            ->getJson('/api/v1/vehicles/'.$vehicleId.'/assistant/threads?status=active')
            ->assertOk()
            ->assertJsonPath('items.0.status', 'resolved');

        $this->withHeaders($headers)
            ->patchJson('/api/v1/vehicles/'.$vehicleId.'/assistant/threads/'.$threadId, [
                'status' => 'archived',
            ])
            ->assertOk()
            ->assertJsonPath('status', 'archived');

        $this->withHeaders($headers)
            ->getJson('/api/v1/vehicles/'.$vehicleId.'/assistant/threads?status=active')
            ->assertOk()
            ->assertJsonCount(0, 'items');

        $this->withHeaders($headers)
            ->getJson('/api/v1/vehicles/'.$vehicleId.'/assistant/threads?status=archived')
            ->assertOk()
            ->assertJsonPath('items.0.id', $threadId);

        $this->withHeaders($headers)
            ->getJson('/api/v1/vehicles/'.$vehicleId.'/assistant/threads/'.$threadId)
            ->assertOk()
            ->assertJsonPath('id', $threadId)
            ->assertJsonStructure(['messages']);

        $this->withHeaders($headers)
            ->deleteJson('/api/v1/vehicles/'.$vehicleId.'/assistant/threads/'.$threadId)
            ->assertNoContent();

        $this->assertDatabaseMissing('assistant_threads', ['id' => $threadId]);

        $this->withHeaders($headers)
            ->getJson('/api/v1/vehicles/'.$vehicleId.'/assistant/threads?status=archived')
            ->assertOk()
            ->assertJsonCount(0, 'items');
    }

    public function test_assistant_message_works_without_a_vehicle(): void
    {
        Http::fake([
            'routellm.abacus.ai/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Могу помочь выбрать автомобиль.']],
                ],
            ], 200),
        ]);

        $headers = $this->sessionHeaders();
        $threadId = (string) Str::uuid();

        $this->withHeaders($headers)
            ->postJson('/api/v1/assistant/messages', [
                'message' => 'Какую машину лучше взять в городе?',
                'thread_id' => $threadId,
            ])
            ->assertOk()
            ->assertJsonPath('reply', 'Могу помочь выбрать автомобиль.')
            ->assertJsonPath('thread_id', $threadId);

        $this->assertDatabaseHas('assistant_threads', [
            'id' => $threadId,
            'vehicle_id' => null,
        ]);

        $recorded = Http::recorded();
        $this->assertNotEmpty($recorded);
        $payload = json_decode($recorded[0][0]->body(), true, flags: JSON_THROW_ON_ERROR);
        $system = (string) data_get($payload, 'messages.0.content');
        $this->assertStringContainsString('автомобиль ещё не выбран', $system);

        $this->withHeaders($headers)
            ->getJson('/api/v1/assistant/threads')
            ->assertOk()
            ->assertJsonPath('items.0.id', $threadId);
    }

    private function sessionHeaders(): array
    {
        $response = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
            ])->assertCreated();

        return [
            'X-Session-Token' => $response->json('session_token'),
            'Idempotency-Key' => (string) Str::uuid(),
            'Accept-Language' => 'ru',
        ];
    }
}
