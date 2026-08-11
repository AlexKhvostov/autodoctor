<?php

namespace App\Http\Controllers;

use App\Exceptions\ApiException;
use App\Http\Resources\AssistantThreadResource;
use App\Models\AnonymousSession;
use App\Models\AssistantThread;
use App\Models\GuestProfile;
use App\Services\Ai\AssistantChatService;
use App\Services\Ai\AssistantThreadPersister;
use App\Services\VehicleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AssistantController extends Controller
{
    public function __construct(
        private readonly VehicleService $vehicles,
        private readonly AssistantChatService $assistant,
        private readonly AssistantThreadPersister $threads,
    ) {}

    public function index(Request $request, string $vehicle): JsonResponse
    {
        $session = $this->session($request);
        $model = $this->vehicles->owned($session, $vehicle);
        $profile = $this->ensureProfile($session);
        $data = $request->validate([
            'status' => ['sometimes', 'string', Rule::in(['active', 'archived', 'all'])],
        ]);

        $status = $data['status'] ?? 'active';
        $query = AssistantThread::query()
            ->where('vehicle_id', $model->id)
            ->where('guest_profile_id', $profile->id)
            ->withCount('messages')
            ->orderByDesc('last_message_at')
            ->orderByDesc('created_at');

        if ($status === 'archived') {
            $query->where('status', AssistantThread::STATUS_ARCHIVED);
        } elseif ($status === 'active') {
            $query->whereIn('status', [
                AssistantThread::STATUS_ACTIVE,
                AssistantThread::STATUS_RESOLVED,
            ]);
        }

        $items = $query->limit(100)->get();

        return response()->json([
            'items' => AssistantThreadResource::collection($items)->resolve(),
        ]);
    }

    public function show(Request $request, string $vehicle, string $thread): JsonResponse
    {
        $model = $this->ownedThread($request, $vehicle, $thread);
        $model->load(['messages']);
        $model->loadCount('messages');

        return response()->json((new AssistantThreadResource($model))->resolve());
    }

    public function update(Request $request, string $vehicle, string $thread): JsonResponse
    {
        $model = $this->ownedThread($request, $vehicle, $thread);
        $data = $request->validate([
            'title' => ['sometimes', 'string', 'min:1', 'max:120'],
            'status' => ['sometimes', 'string', Rule::in([
                AssistantThread::STATUS_ACTIVE,
                AssistantThread::STATUS_RESOLVED,
                AssistantThread::STATUS_ARCHIVED,
            ])],
        ]);

        if (array_key_exists('title', $data)) {
            $model->title = trim($data['title']);
            $model->title_source = AssistantThread::TITLE_SOURCE_USER;
        }

        if (array_key_exists('status', $data)) {
            $model->applyStatus($data['status']);
        }

        $model->save();
        $model->loadCount('messages');

        return response()->json((new AssistantThreadResource($model))->resolve());
    }

    public function destroy(Request $request, string $vehicle, string $thread): JsonResponse
    {
        $model = $this->ownedThread($request, $vehicle, $thread);
        $model->messages()->delete();
        $model->delete();

        return response()->json(null, 204);
    }

    public function storeMessage(Request $request, string $vehicle): JsonResponse
    {
        $session = $this->session($request);
        $model = $this->vehicles->owned($session, $vehicle);

        $data = $request->validate([
            'message' => ['required', 'string', 'min:1', 'max:4000'],
            'thread_id' => ['sometimes', 'nullable', 'uuid'],
            'suggest_title' => ['sometimes', 'boolean'],
            'history' => ['sometimes', 'array', 'max:40'],
            'history.*.role' => ['required_with:history', 'in:user,assistant'],
            'history.*.content' => ['required_with:history', 'string', 'max:4000'],
        ]);

        $result = $this->assistant->reply(
            $session,
            $model,
            $data['message'],
            $data['history'] ?? [],
            (bool) ($data['suggest_title'] ?? false),
        );

        $persisted = $this->threads->persistTurn(
            $session,
            $model,
            trim($data['message']),
            $result['reply'],
            $data['thread_id'] ?? null,
            $result['title'],
            $result['provider'],
            $result['model'],
            $result['prompt_version'],
        );

        $issueIds = array_map(
            static fn (array $row): string => $row['id'],
            $result['issues_saved'],
        );
        $this->assistant->attachIssuesToThread($issueIds, $persisted['thread_id']);

        return response()->json([
            'reply' => $result['reply'],
            'provider' => $result['provider'],
            'model' => $result['model'],
            'prompt_version' => $result['prompt_version'],
            'thread_id' => $persisted['thread_id'],
            'title' => $result['title'] ?? $persisted['title'],
            'notes_saved' => $result['notes_saved'],
            'issues_saved' => $result['issues_saved'],
            'tokens_spent' => (int) ($result['tokens_spent'] ?? 0),
        ]);
    }

    private function ownedThread(Request $request, string $vehicle, string $threadId): AssistantThread
    {
        $session = $this->session($request);
        $vehicleModel = $this->vehicles->owned($session, $vehicle);
        $profile = $this->ensureProfile($session);

        $thread = AssistantThread::query()
            ->whereKey($threadId)
            ->where('vehicle_id', $vehicleModel->id)
            ->where('guest_profile_id', $profile->id)
            ->first();

        if ($thread === null) {
            throw new ApiException('ASSISTANT_THREAD_NOT_FOUND', 'Dialogue not found.', 404);
        }

        return $thread;
    }

    private function ensureProfile(AnonymousSession $session): GuestProfile
    {
        $session->loadMissing('guestProfile');
        if ($session->guestProfile !== null) {
            return $session->guestProfile;
        }

        $profile = GuestProfile::query()->create();
        $session->forceFill(['guest_profile_id' => $profile->id])->save();

        return $profile;
    }

    private function session(Request $request): AnonymousSession
    {
        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');

        return $session;
    }
}
