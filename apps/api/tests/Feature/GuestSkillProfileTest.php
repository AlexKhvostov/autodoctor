<?php

namespace Tests\Feature;

use App\Models\AnonymousSession;
use App\Models\GuestProfile;
use App\Models\GuestSkillObservation;
use App\Models\Vehicle;
use App\Services\Ai\VehicleUserDossierBuilder;
use App\Services\GuestSkillProfileService;
use Database\Seeders\MaintenanceV1Seeder;
use Database\Seeders\MaintenanceV2Seeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class GuestSkillProfileTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(MaintenanceV1Seeder::class);
        $this->seed(MaintenanceV2Seeder::class);
    }

    public function test_quiz_sets_novice_score_and_hands_off_ceiling(): void
    {
        $headers = $this->sessionHeaders();

        $this->withHeaders($headers)
            ->getJson('/api/v1/guest/skill-profile')
            ->assertOk()
            ->assertJsonPath('skill_profile.overall_score', 50)
            ->assertJsonPath('skill_profile.assessed', false);

        $this->withHeaders($headers)
            ->patchJson('/api/v1/guest/skill-profile', [
                'knowledge_band' => 'novice',
                'hands_on' => 'never',
                'detail_preference' => 'simple',
            ])
            ->assertOk()
            ->assertJsonPath('skill_profile.overall_score', 15)
            ->assertJsonPath('skill_profile.band', 'novice')
            ->assertJsonPath('skill_profile.self_reported_band', 'novice')
            ->assertJsonPath('skill_profile.hands_on', false)
            ->assertJsonPath('skill_profile.hands_on_level', 'never')
            ->assertJsonPath('skill_profile.assessed', true);

        $this->assertDatabaseHas('guest_skill_observations', [
            'source' => GuestSkillObservation::SOURCE_ONBOARDING_QUIZ,
        ]);
    }

    public function test_quiz_confident_hands_on_scores_higher(): void
    {
        $headers = $this->sessionHeaders();

        $this->withHeaders($headers)
            ->patchJson('/api/v1/guest/skill-profile', [
                'knowledge_band' => 'confident',
                'hands_on' => 'yes',
                'detail_preference' => 'detailed',
            ])
            ->assertOk()
            ->assertJsonPath('skill_profile.overall_score', 81)
            ->assertJsonPath('skill_profile.band', 'confident')
            ->assertJsonPath('skill_profile.hands_on', true)
            ->assertJsonPath('skill_profile.hands_on_level', 'often');
    }

    public function test_ema_does_not_jump_from_single_strong_signal(): void
    {
        $headers = $this->sessionHeaders();
        $token = $headers['X-Session-Token'];
        $session = AnonymousSession::query()
            ->where('token_hash', hash('sha256', $token))
            ->first()
            ?? AnonymousSession::query()->latest('created_at')->firstOrFail();

        $session->loadMissing('guestProfile');
        $profile = $session->guestProfile ?? GuestProfile::query()->create();
        if ($session->guest_profile_id === null) {
            $session->forceFill(['guest_profile_id' => $profile->id])->save();
        }

        $skills = app(GuestSkillProfileService::class);
        $skills->applyOnboardingQuiz($profile, [
            'knowledge_band' => 'basic',
            'hands_on' => 'sometimes',
        ]);

        $before = (int) $skills->forProfile($profile)->overall_score;
        $this->assertSame(45, $before);

        $afterSignal = $skills->applyChatSignal($profile, 15, 'я механик');
        // weight 0.25 while samples < 5: round(0.75*45 + 0.25*60) = 49
        $this->assertSame(49, (int) $afterSignal->overall_score);
        $this->assertLessThan(70, (int) $afterSignal->overall_score);

        $second = $skills->applyChatSignal($profile->fresh(), 15, 'сам обслуживаю');
        $this->assertLessThan(75, (int) $second->overall_score);
        $this->assertGreaterThan((int) $afterSignal->overall_score, (int) $second->overall_score);
    }

    public function test_dossier_includes_owner_skill_block(): void
    {
        $headers = $this->sessionHeaders();
        $this->withHeaders($headers)
            ->patchJson('/api/v1/guest/skill-profile', [
                'knowledge_band' => 'novice',
                'hands_on' => 'never',
            ])
            ->assertOk();

        $created = $this->withHeaders(array_merge($headers, [
            'Idempotency-Key' => (string) Str::uuid(),
        ]))->postJson('/api/v1/vehicles', [
            'make' => 'Other',
            'model' => 'Other model',
            'production_year' => 2020,
            'fuel_type' => 'petrol',
            'engine' => ['displacement_cc' => 1600],
        ])->assertCreated();

        $session = AnonymousSession::query()
            ->where('token_hash', hash('sha256', $headers['X-Session-Token']))
            ->firstOrFail();
        $session->loadMissing('guestProfile');
        $profile = $session->guestProfile;
        $this->assertNotNull($profile);

        $vehicle = Vehicle::query()->findOrFail($created->json('id'));
        $dossier = app(VehicleUserDossierBuilder::class)->build($profile, $vehicle);

        $this->assertStringContainsString('## Уровень владельца', $dossier);
        $this->assertStringContainsString('уровень знаний: новичок', $dossier);
        $this->assertStringContainsString('готовность к проверкам руками: нет', $dossier);
        $this->assertStringContainsString('правило:', $dossier);
    }

    public function test_unknown_fields_rejected(): void
    {
        $headers = $this->sessionHeaders();

        $this->withHeaders($headers)
            ->patchJson('/api/v1/guest/skill-profile', [
                'knowledge_band' => 'basic',
                'hands_on' => 'sometimes',
                'extra' => true,
            ])
            ->assertUnprocessable();
    }

    /**
     * @return array{X-Session-Token: string, Idempotency-Key?: string}
     */
    private function sessionHeaders(): array
    {
        $response = $this->withHeader('Idempotency-Key', (string) Str::uuid())
            ->postJson('/api/v1/sessions/anonymous', [
                'locale' => 'ru',
                'platform' => 'android',
                'app_version' => '0.1.0',
            ])
            ->assertCreated();

        return [
            'X-Session-Token' => $response->json('session_token'),
        ];
    }
}
