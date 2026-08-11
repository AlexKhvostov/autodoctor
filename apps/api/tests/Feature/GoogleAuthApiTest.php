<?php

namespace Tests\Feature;

use App\Models\GuestProfile;
use App\Models\User;
use App\Models\Vehicle;
use Database\Seeders\MaintenanceV2Seeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Tests\TestCase;

class GoogleAuthApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(MaintenanceV2Seeder::class);
        config([
            'services.google.client_id' => 'web-client-id.apps.googleusercontent.com',
        ]);
    }

    public function test_google_login_creates_user_links_guest_profile_and_returns_token(): void
    {
        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response([
                'aud' => 'web-client-id.apps.googleusercontent.com',
                'sub' => 'google-sub-1',
                'email' => 'alexey@example.com',
                'name' => 'Alexey',
                'email_verified' => 'true',
            ], 200),
        ]);

        $session = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
            ])
            ->assertCreated();

        $profileId = $session->json('guest_profile_id');

        $response = $this->postJson('/api/v1/auth/google', [
            'id_token' => 'fake-google-id-token',
            'guest_profile_id' => $profileId,
        ])
            ->assertOk()
            ->assertJsonPath('user.email', 'alexey@example.com')
            ->assertJsonPath('guest_profile_id', $profileId);

        $this->assertNotEmpty($response->json('token'));
        $this->assertDatabaseHas('users', [
            'email' => 'alexey@example.com',
            'google_id' => 'google-sub-1',
            'is_admin' => false,
        ]);
        $this->assertDatabaseHas('guest_profiles', [
            'id' => $profileId,
            'user_id' => User::query()->where('email', 'alexey@example.com')->value('id'),
        ]);

        $this->withHeader('Authorization', 'Bearer '.$response->json('token'))
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('email', 'alexey@example.com')
            ->assertJsonPath('guest_profile_id', $profileId);
    }

    public function test_google_login_claims_vehicles_and_garage_survives_new_session(): void
    {
        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response([
                'aud' => 'web-client-id.apps.googleusercontent.com',
                'sub' => 'google-sub-claim',
                'email' => 'owner@example.com',
                'name' => 'Owner',
                'email_verified' => 'true',
            ], 200),
        ]);

        $first = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
            ])
            ->assertCreated();
        $profileId = $first->json('guest_profile_id');
        $token1 = $first->json('session_token');

        $vehicleId = $this->withHeaders([
            'X-Session-Token' => $token1,
            'Idempotency-Key' => (string) Str::uuid(),
            'Accept-Language' => 'ru',
        ])->postJson('/api/v1/vehicles', [
            'make' => 'Volkswagen',
            'model' => 'Golf',
            'production_year' => 2018,
            'fuel_type' => 'petrol',
            'engine' => ['displacement_cc' => 1400],
            'mileage' => ['value' => 50000, 'unit' => 'km'],
        ])->assertCreated()->json('id');

        $this->assertDatabaseHas('vehicles', [
            'id' => $vehicleId,
            'user_id' => null,
        ]);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'fake-google-id-token-long-enough',
            'guest_profile_id' => $profileId,
        ])->assertOk();

        $userId = User::query()->where('email', 'owner@example.com')->value('id');
        $this->assertDatabaseHas('vehicles', [
            'id' => $vehicleId,
            'user_id' => $userId,
        ]);

        // New anonymous session for the same guest profile (as after APK reinstall
        // when guest_profile_id is kept and a fresh session token is issued).
        $second = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
                'guest_profile_id' => $profileId,
            ])
            ->assertCreated();

        $this->assertNotSame($token1, $second->json('session_token'));

        $this->withHeader('X-Session-Token', $second->json('session_token'))
            ->getJson('/api/v1/vehicles')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('items.0.id', $vehicleId);

        $this->withHeader('X-Session-Token', $second->json('session_token'))
            ->getJson('/api/v1/vehicles/'.$vehicleId)
            ->assertOk()
            ->assertJsonPath('id', $vehicleId);
    }

    public function test_returning_google_user_merges_free_guest_profile_with_car(): void
    {
        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response([
                'aud' => 'web-client-id.apps.googleusercontent.com',
                'sub' => 'google-sub-merge',
                'email' => 'merge@example.com',
                'name' => 'Merge',
                'email_verified' => 'true',
            ], 200),
        ]);

        $canonicalSession = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
            ])->assertCreated();
        $canonicalProfile = $canonicalSession->json('guest_profile_id');

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'fake-google-id-token-long-enough',
            'guest_profile_id' => $canonicalProfile,
        ])->assertOk();

        $orphanSession = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
            ])->assertCreated();
        $orphanProfile = $orphanSession->json('guest_profile_id');
        $this->assertNotSame($canonicalProfile, $orphanProfile);

        $vehicleId = $this->withHeaders([
            'X-Session-Token' => $orphanSession->json('session_token'),
            'Idempotency-Key' => (string) Str::uuid(),
            'Accept-Language' => 'ru',
        ])->postJson('/api/v1/vehicles', [
            'make' => 'Skoda',
            'model' => 'Octavia',
            'production_year' => 2020,
            'fuel_type' => 'diesel',
            'engine' => ['displacement_cc' => 2000],
            'mileage' => ['value' => 10000, 'unit' => 'km'],
        ])->assertCreated()->json('id');

        $login = $this->postJson('/api/v1/auth/google', [
            'id_token' => 'fake-google-id-token-long-enough',
            'guest_profile_id' => $orphanProfile,
        ])->assertOk();

        $this->assertSame($canonicalProfile, $login->json('guest_profile_id'));
        $this->assertDatabaseMissing('guest_profiles', ['id' => $orphanProfile]);
        $this->assertDatabaseHas('vehicles', [
            'id' => $vehicleId,
            'user_id' => User::query()->where('email', 'merge@example.com')->value('id'),
        ]);

        $this->withHeader('X-Session-Token', $canonicalSession->json('session_token'))
            ->getJson('/api/v1/vehicles')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('items.0.id', $vehicleId);

        $this->assertInstanceOf(Vehicle::class, Vehicle::query()->find($vehicleId));
    }


    public function test_google_login_rejects_when_not_configured(): void
    {
        config([
            'services.google.client_id' => null,
            'services.google.android_client_id' => null,
            'services.google.ios_client_id' => null,
        ]);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'fake-google-id-token',
        ])
            ->assertStatus(503)
            ->assertJsonPath('error.code', 'GOOGLE_AUTH_NOT_CONFIGURED');
    }

    public function test_google_login_rejects_invalid_audience(): void
    {
        config([
            'services.google.client_id' => 'expected-client-id',
        ]);

        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response([
                'aud' => 'other-client-id',
                'sub' => 'google-sub-2',
                'email' => 'x@example.com',
                'email_verified' => 'true',
            ], 200),
        ]);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'fake-google-id-token-long-enough',
        ])
            ->assertUnauthorized()
            ->assertJsonPath('error.code', 'GOOGLE_TOKEN_INVALID');
    }

    public function test_google_login_rejects_foreign_guest_profile(): void
    {
        config([
            'services.google.client_id' => 'web-client-id.apps.googleusercontent.com',
        ]);

        Http::fake([
            'oauth2.googleapis.com/tokeninfo*' => Http::response([
                'aud' => 'web-client-id.apps.googleusercontent.com',
                'sub' => 'google-sub-3',
                'email' => 'new@example.com',
                'name' => 'New',
                'email_verified' => 'true',
            ], 200),
        ]);

        $owner = User::factory()->create(['email' => 'owner@example.com']);
        $profile = GuestProfile::query()->create(['user_id' => $owner->id]);

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'fake-google-id-token-long-enough',
            'guest_profile_id' => $profile->id,
        ])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'GUEST_PROFILE_OWNED');
    }
}
