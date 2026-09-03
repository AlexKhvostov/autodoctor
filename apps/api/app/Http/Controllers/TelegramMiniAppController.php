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
use App\Services\VehicleService;
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
        private readonly VehicleService $vehicles,
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

    public function updateVehicle(
        Request $request,
        TelegramInitDataValidator $validator,
        TelegramAllowlist $allowlist,
    ): JsonResponse {
        $profile = $this->authorizedProfile($request, $validator, $allowlist);
        if ($profile instanceof JsonResponse) {
            return $profile;
        }

        $this->rejectUnknownFields($request, [
            'vehicle_id',
            'version',
            'make',
            'model',
            'production_year',
            'mileage',
            'vin',
        ]);

        $validated = Validator::make($request->all(), [
            'vehicle_id' => ['required', 'uuid'],
            'version' => ['required', 'integer', 'min:1'],
            'make' => ['sometimes', 'string', 'min:1', 'max:100'],
            'model' => ['sometimes', 'string', 'min:1', 'max:100'],
            'production_year' => ['sometimes', 'integer', 'between:1886,2100'],
            'mileage' => ['sometimes', 'array:value,unit'],
            'mileage.value' => ['required_with:mileage', 'integer', 'min:0'],
            'mileage.unit' => ['required_with:mileage', Rule::in(['km', 'mi'])],
            'vin' => ['sometimes', 'nullable', 'string', 'regex:/^[A-HJ-NPR-Z0-9]{17}$/'],
        ])->validate();

        if (count(array_diff(array_keys($validated), ['vehicle_id', 'version'])) === 0) {
            throw ValidationException::withMessages([
                'vehicle_id' => [__('validation.required')],
            ]);
        }

        $vehicle = Vehicle::query()
            ->whereKey($validated['vehicle_id'])
            ->whereHas('anonymousSession', fn ($query) => $query->where('guest_profile_id', $profile->id))
            ->with('anonymousSession')
            ->first();

        if ($vehicle === null) {
            return response()->json([
                'ok' => false,
                'error' => 'vehicle_not_found',
            ], 404);
        }

        $patch = array_diff_key($validated, ['vehicle_id' => true]);
        $updated = $this->vehicles->update($vehicle->anonymousSession, (string) $vehicle->id, $patch);

        return response()->json([
            'ok' => true,
            'vehicle_id' => $updated->id,
            'version' => $updated->version,
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
