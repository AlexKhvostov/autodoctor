<?php

namespace App\Services\Telegram;

use App\Models\AnonymousSession;
use App\Models\AssistantMessage;
use App\Models\AssistantThread;
use App\Models\GuestProfile;
use App\Models\Vehicle;
use App\Services\Ai\AssistantChatService;
use App\Services\Ai\AssistantThreadPersister;
use Illuminate\Support\Str;

class TelegramDialogueService
{
    public function __construct(
        private readonly AssistantChatService $assistant,
        private readonly AssistantThreadPersister $threads,
    ) {}

    public function reply(GuestProfile $profile, string $message): string
    {
        $session = $this->sessionFor($profile);
        $thread = $this->activeThread($profile);
        $vehicle = $this->vehicleFor($session, $thread);
        $history = $this->history($thread);

        $result = $this->assistant->reply(
            $session,
            $vehicle,
            $message,
            $history,
            $thread === null,
        );

        $persisted = $this->threads->persistTurn(
            $session,
            $vehicle,
            trim($message),
            $result['reply'],
            $thread?->id,
            $result['title'],
            $result['provider'] ?? null,
            $result['model'] ?? null,
            $result['prompt_version'] ?? null,
        );

        $issueIds = array_map(
            static fn (array $row): string => $row['id'],
            $result['issues_saved'] ?? [],
        );
        $this->assistant->attachIssuesToThread($issueIds, $persisted['thread_id']);

        $reply = trim((string) $result['reply']);
        if (mb_strlen($reply) > 4000) {
            return rtrim(mb_substr($reply, 0, 3990)).'…';
        }

        return $reply;
    }

    public function recordOpening(GuestProfile $profile, string $assistantText): void
    {
        if ($this->activeThread($profile) !== null) {
            return;
        }

        $session = $this->sessionFor($profile);
        $this->threads->persistTurn(
            $session,
            null,
            '/start',
            $assistantText,
            null,
            'Telegram',
            null,
            null,
            null,
        );
    }

    public function hasVehicle(GuestProfile $profile): bool
    {
        return $profile->vehicles()->exists();
    }

    public function sessionFor(GuestProfile $profile): AnonymousSession
    {
        $session = AnonymousSession::query()
            ->where('guest_profile_id', $profile->id)
            ->where('status', 'active')
            ->orderByDesc('last_activity_at')
            ->first();

        if ($session !== null) {
            $session->forceFill(['last_activity_at' => now()])->save();

            return $session;
        }

        $now = now();

        return AnonymousSession::query()->create([
            'guest_profile_id' => $profile->id,
            'locale' => 'ru',
            'platform' => 'telegram',
            'app_version' => 'telegram-bot',
            'token_hash' => hash('sha256', 'telegram:'.$profile->id.':'.Str::uuid()),
            'status' => 'active',
            'last_activity_at' => $now,
            'expires_at' => $now->copy()->addYears(10),
        ]);
    }

    private function activeThread(GuestProfile $profile): ?AssistantThread
    {
        return AssistantThread::query()
            ->where('guest_profile_id', $profile->id)
            ->where('status', AssistantThread::STATUS_ACTIVE)
            ->orderByDesc('last_message_at')
            ->orderByDesc('created_at')
            ->first();
    }

    private function vehicleFor(AnonymousSession $session, ?AssistantThread $thread): ?Vehicle
    {
        if ($thread?->vehicle_id) {
            return Vehicle::query()->find($thread->vehicle_id);
        }

        return $session->vehicles()->orderByDesc('created_at')->first();
    }

    /**
     * @return list<array{role: string, content: string}>
     */
    private function history(?AssistantThread $thread): array
    {
        if ($thread === null) {
            return [];
        }

        return AssistantMessage::query()
            ->where('assistant_thread_id', $thread->id)
            ->orderByDesc('created_at')
            ->limit(40)
            ->get()
            ->reverse()
            ->values()
            ->map(fn ($message): array => [
                'role' => (string) $message->role,
                'content' => (string) $message->content,
            ])
            ->all();
    }
}
