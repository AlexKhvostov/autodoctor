<?php

namespace App\Services\Ai;

use App\Models\AnonymousSession;
use App\Models\AssistantMessage;
use App\Models\AssistantThread;
use App\Models\GuestProfile;
use App\Models\Vehicle;
use Illuminate\Support\Str;

class AssistantThreadPersister
{
    /**
     * @return array{thread_id: string, title: ?string}
     */
    public function persistTurn(
        AnonymousSession $session,
        ?Vehicle $vehicle,
        string $userMessage,
        string $assistantReply,
        ?string $threadId,
        ?string $suggestedTitle,
        ?string $provider,
        ?string $model,
        ?string $promptVersion,
    ): array {
        $profile = $this->resolveProfile($session);
        $id = filled($threadId) ? (string) $threadId : (string) Str::uuid();
        $now = now();
        $incomingVehicleId = $vehicle?->id;

        $thread = AssistantThread::query()->firstOrNew(['id' => $id]);
        if (! $thread->exists) {
            $thread->guest_profile_id = $profile->id;
            $thread->vehicle_id = $incomingVehicleId;
            $thread->anonymous_session_id = $session->id;
            $thread->title = $suggestedTitle ?: $this->fallbackTitle($userMessage);
            $thread->title_source = AssistantThread::TITLE_SOURCE_AUTO;
            $thread->status = AssistantThread::STATUS_ACTIVE;
        } else {
            $threadVehicleId = $thread->vehicle_id;
            $vehicleConflict = $threadVehicleId !== null
                && $incomingVehicleId !== null
                && $threadVehicleId !== $incomingVehicleId;
            if ($thread->guest_profile_id !== $profile->id || $vehicleConflict) {
                // Client reused a foreign thread id — start a fresh thread.
                $id = (string) Str::uuid();
                $thread = new AssistantThread([
                    'id' => $id,
                    'guest_profile_id' => $profile->id,
                    'vehicle_id' => $incomingVehicleId,
                    'anonymous_session_id' => $session->id,
                    'title' => $suggestedTitle ?: $this->fallbackTitle($userMessage),
                    'title_source' => AssistantThread::TITLE_SOURCE_AUTO,
                    'status' => AssistantThread::STATUS_ACTIVE,
                ]);
            } else {
                if ($threadVehicleId === null && $incomingVehicleId !== null) {
                    $thread->vehicle_id = $incomingVehicleId;
                }
                if (! $thread->isTitleLockedByUser() || $this->isPlaceholderTitle($thread->title)) {
                    if (filled($suggestedTitle)) {
                        $thread->title = $suggestedTitle;
                        $thread->title_source = AssistantThread::TITLE_SOURCE_AUTO;
                    } elseif (! filled($thread->title) || $this->isPlaceholderTitle($thread->title)) {
                        $thread->title = $this->fallbackTitle($userMessage);
                        $thread->title_source = AssistantThread::TITLE_SOURCE_AUTO;
                    }
                }
                $thread->anonymous_session_id = $session->id;
            }
        }

        $thread->last_message_at = $now;
        $thread->save();

        AssistantMessage::query()->create([
            'assistant_thread_id' => $thread->id,
            'role' => 'user',
            'content' => $userMessage,
            'created_at' => $now,
        ]);

        AssistantMessage::query()->create([
            'assistant_thread_id' => $thread->id,
            'role' => 'assistant',
            'content' => $assistantReply,
            'provider' => $provider,
            'model' => $model,
            'prompt_version' => $promptVersion,
            'created_at' => $now->copy()->addSecond(),
        ]);

        return [
            'thread_id' => $thread->id,
            'title' => $thread->title,
        ];
    }

    private function resolveProfile(AnonymousSession $session): GuestProfile
    {
        $session->loadMissing('guestProfile');
        if ($session->guestProfile !== null) {
            return $session->guestProfile;
        }

        $profile = GuestProfile::query()->create();
        $session->forceFill(['guest_profile_id' => $profile->id])->save();

        return $profile;
    }

    private function fallbackTitle(string $message): string
    {
        $title = trim(preg_replace('/\s+/u', ' ', $message) ?? $message);
        if ($title === '') {
            return 'Диалог';
        }
        if (mb_strlen($title) > 48) {
            return rtrim(mb_substr($title, 0, 48)).'…';
        }

        return $title;
    }

    private function isPlaceholderTitle(?string $title): bool
    {
        $normalized = mb_strtolower(trim((string) $title));

        return $normalized === ''
            || $normalized === 'новый чат'
            || $normalized === 'new chat'
            || $normalized === 'диалог';
    }
}
