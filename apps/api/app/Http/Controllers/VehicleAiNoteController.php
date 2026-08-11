<?php

namespace App\Http\Controllers;

use App\Exceptions\ApiException;
use App\Http\Resources\VehicleAiNoteResource;
use App\Models\AnonymousSession;
use App\Models\VehicleAiNote;
use App\Services\VehicleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VehicleAiNoteController extends Controller
{
    public function __construct(private readonly VehicleService $vehicles) {}

    public function index(Request $request, string $vehicle): JsonResponse
    {
        $model = $this->vehicles->owned($this->session($request), $vehicle);
        $notes = $model->aiNotes()->orderByDesc('created_at')->limit(50)->get();

        return response()->json([
            'items' => VehicleAiNoteResource::collection($notes)->resolve(),
        ]);
    }

    public function destroy(Request $request, string $vehicle, string $note): JsonResponse
    {
        $model = $this->vehicles->owned($this->session($request), $vehicle);
        $row = VehicleAiNote::query()
            ->whereKey($note)
            ->where('vehicle_id', $model->id)
            ->first();

        if ($row === null) {
            throw new ApiException('AI_NOTE_NOT_FOUND', 'Note not found.', 404);
        }

        $row->delete();

        return response()->json(null, 204);
    }

    private function session(Request $request): AnonymousSession
    {
        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');

        return $session;
    }
}
