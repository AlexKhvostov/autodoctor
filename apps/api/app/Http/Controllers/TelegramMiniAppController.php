<?php

namespace App\Http\Controllers;

use App\Models\GuestProfile;
use App\Models\GuestSkillProfile;
use App\Models\Vehicle;
use App\Services\AgentProfileService;
use App\Services\GuestSkillProfileService;
use App\Services\Telegram\TelegramAllowlist;
use App\Services\Telegram\TelegramInitDataValidator;
use App\Services\Telegram\TelegramMiniAppSnapshot;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class TelegramMiniAppController extends Controller
{
    public function __construct(
        private readonly AgentProfileService $agents,
        private readonly GuestSkillProfileService $skills,
    ) {}

    public function show(): View
    {
        return view('telegram.mini-app');
    }

    public function state(
        Request $request,
        TelegramInitDataValidator $validator,
        TelegramAllowlist $allowlist,
        TelegramMiniAppSnapshot $snapshot,
    ): JsonResponse {
        $initData = (string) $request->header('X-Telegram-Init-Data', '');
        $userId = $validator->userId($initData);
        if ($userId === null) {
            return response()->json([
                'ok' => false,
                'error' => 'open_in_telegram',
            ], 401);
        }

        if (! $allowlist->allows($userId)) {
            return response()->json([
                'ok' => true,
                'allowed' => false,
                ...$snapshot->deniedResponse(),
            ]);
        }

        $vehicleId = null;
        $profile = GuestProfile::query()->where('telegram_id', $userId)->first();
        if ($profile !== null) {
            $vehicleId = $this->vehicleIdFromRequest($request, $profile);
        }

        return response()->json([
            'ok' => true,
            'allowed' => true,
            ...$snapshot->forTelegramUser($userId, $vehicleId),
        ]);
    }

    public function updateAgentPreferences(
        Request $request,
        TelegramInitDataValidator $validator,
        TelegramAllowlist $allowlist,
    ): JsonResponse {
        $profile = $this->authorizedProfile($request, $validator, $allowlist);
        if ($profile instanceof JsonResponse) {
            return $profile;
        }

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

        $prefs = $this->agents->updatePreferences($profile, $validated);

        return response()->json([
            'ok' => true,
            'preferences' => $this->agents->preferencesToArray($prefs),
        ]);
    }

    public function updateAgentSkill(
        Request $request,
        TelegramInitDataValidator $validator,
        TelegramAllowlist $allowlist,
    ): JsonResponse {
        $profile = $this->authorizedProfile($request, $validator, $allowlist);
        if ($profile instanceof JsonResponse) {
            return $profile;
        }

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

        $skill = $this->skills->applyOnboardingQuiz($profile, $validated);

        return response()->json([
            'ok' => true,
            'skill' => $this->skills->toArray($skill),
        ]);
    }

    private function authorizedProfile(
        Request $request,
        TelegramInitDataValidator $validator,
        TelegramAllowlist $allowlist,
    ): GuestProfile|JsonResponse {
        $initData = (string) $request->header('X-Telegram-Init-Data', '');
        $userId = $validator->userId($initData);
        if ($userId === null) {
            return response()->json([
                'ok' => false,
                'error' => 'open_in_telegram',
            ], 401);
        }

        if (! $allowlist->allows($userId)) {
            return response()->json([
                'ok' => true,
                'allowed' => false,
            ], 403);
        }

        $profile = GuestProfile::query()->where('telegram_id', $userId)->first();
        if ($profile === null) {
            return response()->json([
                'ok' => false,
                'error' => 'profile_missing',
            ], 404);
        }

        return $profile;
    }

    private function vehicleIdFromRequest(Request $request, GuestProfile $profile): ?string
    {
        $vehicleId = $request->query('vehicle_id');
        if (! is_string($vehicleId) || $vehicleId === '') {
            return null;
        }

        $owned = Vehicle::query()
            ->whereKey($vehicleId)
            ->whereHas('anonymousSession', fn ($query) => $query->where('guest_profile_id', $profile->id))
            ->exists();

        return $owned ? $vehicleId : null;
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
