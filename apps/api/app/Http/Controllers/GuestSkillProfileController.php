<?php

namespace App\Http\Controllers;

use App\Models\AnonymousSession;
use App\Models\GuestProfile;
use App\Models\GuestSkillProfile;
use App\Services\GuestSkillProfileService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class GuestSkillProfileController extends Controller
{
    public function __construct(private readonly GuestSkillProfileService $skills) {}

    public function show(Request $request): JsonResponse
    {
        $profile = $this->ensureProfile($request);
        $skill = $this->skills->forProfile($profile);

        return response()->json([
            'skill_profile' => $this->skills->toArray($skill),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $this->rejectUnknownFields($request, [
            'knowledge_band',
            'hands_on',
            'detail_preference',
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
            'detail_preference' => ['sometimes', 'nullable', Rule::in(['simple', 'detailed'])],
        ])->validate();

        $profile = $this->ensureProfile($request);
        $skill = $this->skills->applyOnboardingQuiz($profile, $validated);

        return response()->json([
            'skill_profile' => $this->skills->toArray($skill),
        ]);
    }

    private function ensureProfile(Request $request): GuestProfile
    {
        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');
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
