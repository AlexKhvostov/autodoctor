<?php

namespace App\Http\Controllers;

use App\Exceptions\ApiException;
use App\Http\Resources\GuestProfileAiNoteResource;
use App\Models\AnonymousSession;
use App\Models\GuestProfile;
use App\Models\GuestProfileAiNote;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GuestProfileAiNoteController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $profile = $this->ensureProfile($request);
        $notes = $profile->aiNotes()->orderByDesc('created_at')->limit(50)->get();

        return response()->json([
            'items' => GuestProfileAiNoteResource::collection($notes)->resolve(),
        ]);
    }

    public function destroy(Request $request, string $note): JsonResponse
    {
        $profile = $this->ensureProfile($request);
        $model = GuestProfileAiNote::query()
            ->whereKey($note)
            ->where('guest_profile_id', $profile->id)
            ->first();

        if ($model === null) {
            throw new ApiException('AI_NOTE_NOT_FOUND', 'Note not found.', 404);
        }

        $model->delete();

        return response()->json(null, 204);
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
}
