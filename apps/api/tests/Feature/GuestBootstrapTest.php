<?php

namespace Tests\Feature;

use App\Models\AnonymousSession;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class GuestBootstrapTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-07-17T09:00:00Z');
    }

    public function test_capabilities_match_contract(): void
    {
        $this->getJson('/api/v1/capabilities')
            ->assertOk()
            ->assertExactJson([
                'public_browse' => true,
                'anonymous_sessions' => true,
                'social_auth_providers' => ['telegram', 'google', 'apple'],
                'email_password_auth' => false,
                'max_vehicles_per_user' => 1,
            ]);
    }

    public function test_session_can_be_created_read_and_closed(): void
    {
        [$token, $sessionId] = $this->createSession();

        $this->withHeader('X-Session-Token', $token)
            ->getJson('/api/v1/sessions/current')
            ->assertOk()
            ->assertJsonPath('id', $sessionId)
            ->assertJsonPath('status', 'active');

        $closeKey = (string) Str::uuid();
        $headers = [
            'X-Session-Token' => $token,
            'Idempotency-Key' => $closeKey,
        ];

        $this->withHeaders($headers)
            ->deleteJson('/api/v1/sessions/current')
            ->assertNoContent();

        $this->withHeaders($headers)
            ->deleteJson('/api/v1/sessions/current')
            ->assertNoContent();

        $this->withHeader('X-Session-Token', $token)
            ->getJson('/api/v1/sessions/current')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'SESSION_REVOKED');
    }

    public function test_expired_and_invalid_tokens_are_rejected(): void
    {
        [$token, $sessionId] = $this->createSession();
        AnonymousSession::query()->findOrFail($sessionId)->update([
            'expires_at' => now()->subSecond(),
        ]);

        $this->withHeader('X-Session-Token', $token)
            ->getJson('/api/v1/sessions/current')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'SESSION_EXPIRED')
            ->assertJsonStructure(['error' => ['code', 'message', 'request_id']]);

        $this->withHeader('X-Session-Token', 'not-a-token')
            ->getJson('/api/v1/sessions/current')
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'INVALID_SESSION_TOKEN');
    }

    public function test_session_creation_replays_without_storing_plaintext_token(): void
    {
        $key = (string) Str::uuid();
        $payload = [
            'locale' => 'ru-BY',
            'platform' => 'android',
            'app_version' => '0.1.0',
        ];

        $first = $this->withHeader('Idempotency-Key', $key)
            ->postJson('/api/v1/sessions/anonymous', $payload)
            ->assertCreated();
        $second = $this->withHeader('Idempotency-Key', $key)
            ->postJson('/api/v1/sessions/anonymous', $payload)
            ->assertCreated();

        $this->assertSame($first->json(), $second->json());
        $this->assertDatabaseCount('anonymous_sessions', 1);
        $this->assertDatabaseCount('idempotency_records', 1);
        $this->assertDatabaseHas('anonymous_sessions', ['locale' => 'ru']);

        $token = $first->json('session_token');
        $this->assertSame(hash('sha256', $token), DB::table('anonymous_sessions')->value('token_hash'));
        $this->assertStringNotContainsString(
            $token,
            (string) DB::table('idempotency_records')->value('response_body'),
        );

        foreach (DB::table('anonymous_sessions')->first() as $value) {
            $this->assertNotSame($token, $value);
        }

        $this->withHeader('Idempotency-Key', $key)
            ->postJson('/api/v1/sessions/anonymous', [
                ...$payload,
                'locale' => 'en-US',
            ])
            ->assertConflict()
            ->assertJsonPath('error.code', 'IDEMPOTENCY_KEY_CONFLICT');
    }

    public function test_current_consents_are_public_and_include_required_and_analytics(): void
    {
        $response = $this->withHeader('Accept-Language', '')
            ->getJson('/api/v1/consents/current')
            ->assertOk()
            ->assertJsonCount(2, 'items')
            ->assertJsonPath('items.0.title', 'Обязательная обработка данных');

        $this->assertSame(
            ['essential_processing', 'analytics'],
            array_column($response->json('items'), 'purpose'),
        );
        $this->assertTrue($response->json('items.0.required'));
        $this->assertFalse($response->json('items.1.required'));
    }

    public function test_public_locale_defaults_to_russian_and_falls_back_to_russian(): void
    {
        $this->withHeader('Accept-Language', '')
            ->getJson('/api/v1/consents/current')
            ->assertOk()
            ->assertJsonPath('items.1.title', 'Аналитика использования');

        $this->withHeader('Accept-Language', 'de-DE')
            ->getJson('/api/v1/consents/current')
            ->assertOk()
            ->assertJsonPath('items.0.title', 'Обязательная обработка данных');
    }

    public function test_accept_language_localizes_consents_and_normalizes_regional_tags(): void
    {
        $this->withHeader('Accept-Language', 'en-US')
            ->getJson('/api/v1/consents/current')
            ->assertOk()
            ->assertJsonPath('items.0.title', 'Essential data processing')
            ->assertJsonPath(
                'items.1.text',
                'Anonymized analytics helps us improve the product. Your decision does not affect core features.',
            );

        $this->withHeader('Accept-Language', 'ru-BY')
            ->getJson('/api/v1/consents/current')
            ->assertOk()
            ->assertJsonPath('items.0.title', 'Обязательная обработка данных');
    }

    public function test_accept_language_localizes_public_error_response(): void
    {
        $this->withHeaders([
            'Accept-Language' => 'en',
            'Idempotency-Key' => 'not-a-uuid',
        ])->postJson('/api/v1/sessions/anonymous', [
            'locale' => 'en',
            'platform' => 'android',
        ])->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_FAILED')
            ->assertJsonPath('error.message', 'Check the submitted fields.')
            ->assertJsonPath(
                'error.fields.Idempotency-Key.0',
                'The Idempotency-Key header must contain a UUID.',
            );
    }

    public function test_protected_request_uses_session_locale_without_accept_language(): void
    {
        [$token] = $this->createSession('en-US');
        $this->assertDatabaseHas('anonymous_sessions', ['locale' => 'en']);

        $this->withHeaders([
            'Accept-Language' => '',
            'X-Session-Token' => $token,
            'Idempotency-Key' => (string) Str::uuid(),
        ])->postJson('/api/v1/consents', [
            'decisions' => [[
                'purpose' => 'analytics',
                'version' => '2026-07-17',
                'granted' => true,
            ]],
        ])->assertUnprocessable()
            ->assertJsonPath('error.message', 'Check the submitted fields.')
            ->assertJsonPath(
                'error.fields.decisions.0',
                'A decision is required for mandatory consent essential_processing.',
            );
    }

    public function test_not_found_error_uses_accept_language(): void
    {
        $this->withHeader('Accept-Language', 'en-US')
            ->getJson('/api/v1/not-a-real-endpoint')
            ->assertNotFound()
            ->assertJsonPath('error.code', 'NOT_FOUND')
            ->assertJsonPath('error.message', 'Resource not found.');
    }

    public function test_consents_are_saved_idempotently_and_conflicts_are_rejected(): void
    {
        [$token] = $this->createSession();
        $key = (string) Str::uuid();
        $headers = [
            'X-Session-Token' => $token,
            'Idempotency-Key' => $key,
        ];
        $payload = [
            'decisions' => [
                [
                    'purpose' => 'essential_processing',
                    'version' => '2026-07-17',
                    'granted' => true,
                ],
                [
                    'purpose' => 'analytics',
                    'version' => '2026-07-17',
                    'granted' => false,
                ],
            ],
        ];

        $first = $this->withHeaders($headers)
            ->postJson('/api/v1/consents', $payload)
            ->assertCreated()
            ->assertJsonCount(2, 'items');
        $second = $this->withHeaders($headers)
            ->postJson('/api/v1/consents', $payload)
            ->assertCreated();

        $this->assertSame($first->json(), $second->json());
        $this->assertDatabaseCount('consents', 2);

        $payload['decisions'][1]['granted'] = true;
        $this->withHeaders($headers)
            ->postJson('/api/v1/consents', $payload)
            ->assertConflict()
            ->assertJsonPath('error.code', 'IDEMPOTENCY_KEY_CONFLICT');
    }

    public function test_mandatory_consent_cannot_be_rejected_or_omitted(): void
    {
        [$token] = $this->createSession();

        $this->withHeaders([
            'X-Session-Token' => $token,
            'Idempotency-Key' => (string) Str::uuid(),
        ])->postJson('/api/v1/consents', [
            'decisions' => [[
                'purpose' => 'essential_processing',
                'version' => '2026-07-17',
                'granted' => false,
            ]],
        ])->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');

        $this->withHeaders([
            'X-Session-Token' => $token,
            'Idempotency-Key' => (string) Str::uuid(),
        ])->postJson('/api/v1/consents', [
            'decisions' => [[
                'purpose' => 'analytics',
                'version' => '2026-07-17',
                'granted' => true,
            ]],
        ])->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');
    }

    private function createSession(string $locale = 'ru-BY'): array
    {
        $response = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => $locale,
                'platform' => 'android',
                'app_version' => '0.1.0',
            ])
            ->assertCreated()
            ->assertJsonStructure([
                'session' => ['id', 'status', 'expires_at', 'created_at', 'updated_at', 'version'],
                'session_token',
            ]);

        return [$response->json('session_token'), $response->json('session.id')];
    }
}
