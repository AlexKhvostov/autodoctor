<?php

namespace App\Http\Controllers;

use App\Models\AnonymousSession;
use App\Models\GuestProfile;
use App\Models\GuestSkillProfile;
use App\Services\AgentProfileService;
use App\Services\GuestSkillProfileService;
use App\Services\VehicleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AgentProfileController extends Controller
{
    public function __construct(
        private readonly AgentProfileService $agents,
        private readonly GuestSkillProfileService $skills,
        private readonly VehicleService $vehicles,
    ) {}

    public function show(Request $request): JsonResponse
    {
        $profile = $this->ensureProfile($request);
        $vehicle = null;
        $vehicleId = $request->query('vehicle_id');
        if (is_string($vehicleId) && $vehicleId !== '') {
            $vehicle = $this->vehicles->owned($this->session($request), $vehicleId);
        }

        return response()->json([
            'agent_profile' => $this->agents->profilePayload($profile, $vehicle),
        ]);
    }

    public function updatePreferences(Request $request): JsonResponse
    {
        $this->rejectUnknownFields($request, [
            'simplicity',
            'verbosity',
            'directness',
            'initiative',
            'custom_instructions',
        ]);

        $validated = Validator::make($request->all(), [
            'simplicity' => ['sometimes', 'integer', 'between:0,10'],
            'verbosity' => ['sometimes', 'integer', 'between:0,10'],
            'directness' => ['sometimes', 'integer', 'between:0,10'],
            'initiative' => ['sometimes', 'integer', 'between:0,10'],
            'custom_instructions' => ['sometimes', 'nullable', 'string', 'max:800'],
        ])->validate();

        if ($validated === []) {
            throw ValidationException::withMessages([
                'preferences' => [__('validation.required')],
            ]);
        }

        $profile = $this->ensureProfile($request);
        $prefs = $this->agents->updatePreferences($profile, $validated);

        return response()->json([
            'preferences' => $this->agents->preferencesToArray($prefs),
        ]);
    }

    public function updateSkill(Request $request): JsonResponse
    {
        $this->rejectUnknownFields($request, [
            'knowledge_band',
            'hands_on',
        ]);

        $validated = Validator::make($request->all(), [
            'knowledge_band' => [
                'required',
                Rule::in(GuestSkillProfile::KNOWLEDGE_LEVELS),
            ],
            'hands_on' => [
                'required',
                Rule::in([...GuestSkillProfile::HANDS_LEVELS, 'yes']),
            ],
        ])->validate();

        $profile = $this->ensureProfile($request);
        $skill = $this->skills->applyOnboardingQuiz($profile, $validated);

        return response()->json([
            'skill' => $this->skills->toArray($skill),
        ]);
    }

    public function refuelStub(Request $request): JsonResponse
    {
        $this->rejectUnknownFields($request, ['package_ml']);

        $validated = Validator::make($request->all(), [
            'package_ml' => ['required', 'integer'],
        ])->validate();

        $profile = $this->ensureProfile($request);
        $wallet = $this->agents->refuelStub($profile, (int) $validated['package_ml']);

        return response()->json([
            'fuel' => [
                'balance_ml' => (int) $wallet->balance_ml,
                'capacity_ml' => (int) $wallet->capacity_ml,
                'percent' => $wallet->percentFull(),
                'lifetime_consumed_ml' => (int) $wallet->lifetime_consumed_ml,
                'payment_stub' => true,
                'message' => __('api.agent.refuel_stub'),
            ],
        ]);
    }

    private function session(Request $request): AnonymousSession
    {
        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');

        return $session;
    }

    private function ensureProfile(Request $request): GuestProfile
    {
        $session = $this->session($request);
        $session->loadMissing('guestProfile');

        if ($session->guestProfile !== null) {
            return $session->guestProfile;
        }

        $profile = GuestProfile::query()->create();
        $session->forceFill(['guest_profile_id' => $profile->id])->save();

        return $profile;
    }

    /**
     * @param  list<string>  $allowed
     */
    private function rejectUnknownFields(Request $request, array $allowed): void
    {
        $unknown = array_diff(array_keys($request->all()), $allowed);

        if ($unknown !== []) {
            throw ValidationException::withMessages(
                array_fill_keys($unknown, [__('api.fields.unknown')]),
            );
        }
    }
}
