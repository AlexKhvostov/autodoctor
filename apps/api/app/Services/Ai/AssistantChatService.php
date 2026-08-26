<?php

namespace App\Services\Ai;

use App\Exceptions\ApiException;
use App\Models\AiConfigVersion;
use App\Models\AnonymousSession;
use App\Models\GuestProfile;
use App\Models\GuestProfileAiNote;
use App\Models\Vehicle;
use App\Models\VehicleAiNote;
use App\Models\VehicleIssue;
use App\Models\AiUsageEvent;
use App\Services\AgentProfileService;
use App\Services\GuestSkillProfileService;
use Throwable;

class AssistantChatService
{
    public function __construct(
        private readonly LlmClient $llm,
        private readonly VehicleUserDossierBuilder $dossier,
        private readonly GuestSkillProfileService $skills,
        private readonly AgentProfileService $agents,
    ) {}

    /**
     * @param  list<array{role: string, content: string}>  $history
     * @return array{
     *     reply: string,
     *     provider: string,
     *     model: string,
     *     prompt_version: string,
     *     title: ?string,
     *     notes_saved: array{vehicle: list<string>, user: list<string>},
     *     issues_saved: list<array{id: string, title: string, status: string, action: string}>
     * }
     */
    public function reply(
        AnonymousSession $session,
        ?Vehicle $vehicle,
        string $message,
        array $history = [],
        bool $suggestTitle = false,
    ): array {
        $marked = AiConfigVersion::query()
            ->with('promptVersion')
            ->where('is_active', true)
            ->latest('id')
            ->first();
        if ($marked === null) {
            throw new ApiException(
                'AI_NOT_CONFIGURED',
                __('api.errors.ai_not_configured'),
                503,
            );
        }
        if (! $marked->enabled) {
            throw new ApiException(
                'AI_DISABLED',
                __('api.errors.ai_disabled_detail'),
                503,
            );
        }
        $config = $marked;

        $prompt = $config->promptVersion;
        if ($prompt === null || ! $prompt->isApproved()) {
            throw new ApiException(
                'AI_PROMPT_MISSING',
                __('api.errors.ai_prompt_missing'),
                503,
            );
        }

        $userTurn = $this->userTurnNumber($history);
        $profile = $this->resolveGuestProfile($session);
        $this->agents->assertHasFuel($profile);
        $dossier = $vehicle === null
            ? $this->dossier->buildWithoutVehicle($profile)
            : $this->dossier->build($profile, $vehicle);
        $system = $prompt->body
            ."\n\n## Контекст пользователя и автомобиля (данные AutoDoctor)\n"
            .$dossier
            ."\n\n## Текущий шаг диалога\n".$this->stageHint($userTurn, $vehicle !== null);

        $messages = [
            ['role' => 'system', 'content' => $system],
        ];

        foreach ($history as $item) {
            $role = $item['role'] ?? null;
            $content = $item['content'] ?? null;
            if (! is_string($role) || ! is_string($content)) {
                continue;
            }
            if (! in_array($role, ['user', 'assistant'], true)) {
                continue;
            }
            $trimmed = trim($content);
            if ($trimmed === '') {
                continue;
            }
            $messages[] = ['role' => $role, 'content' => $trimmed];
        }

        $messages[] = ['role' => 'user', 'content' => trim($message)];

        try {
            $result = $this->llm->chat(
                $config->primary_provider,
                $config->primary_model,
                $messages,
                $config->max_tokens,
            );
        } catch (Throwable $primaryError) {
            if (
                ! filled($config->fallback_provider)
                || ! filled($config->fallback_model)
            ) {
                throw $primaryError;
            }

            try {
                $result = $this->llm->chat(
                    (string) $config->fallback_provider,
                    (string) $config->fallback_model,
                    $messages,
                    $config->max_tokens,
                );
            } catch (Throwable) {
                throw $primaryError;
            }
        }

        $usageEvent = $this->agents->recordUsage(
            $profile,
            AiUsageEvent::SOURCE_CHAT,
            [
                'prompt_tokens' => $result['prompt_tokens'] ?? null,
                'completion_tokens' => $result['completion_tokens'] ?? null,
                'total_tokens' => $result['total_tokens'] ?? null,
                'provider' => $result['provider'] ?? null,
                'model' => $result['model'] ?? null,
            ],
            $vehicle,
        );

        $title = null;
        if ($suggestTitle) {
            $title = $this->suggestThreadTitle($config, trim($message), $profile, $vehicle);
        }

        $memory = $this->captureDurableMemory(
            $config,
            $profile,
            $vehicle,
            trim($message),
            $result['content'],
        );

        return [
            'reply' => $result['content'],
            'provider' => $result['provider'],
            'model' => $result['model'],
            'prompt_version' => $prompt->code.'#'.$prompt->id,
            'title' => $title,
            'notes_saved' => $memory['notes_saved'],
            'issues_saved' => $memory['issues_saved'],
            'tokens_spent' => (int) $usageEvent->fuel_ml,
        ];
    }

    /**
     * @param  list<string>  $issueIds
     */
    public function attachIssuesToThread(array $issueIds, string $threadId): void
    {
        if ($issueIds === []) {
            return;
        }

        VehicleIssue::query()
            ->whereIn('id', $issueIds)
            ->whereNull('source_thread_id')
            ->update(['source_thread_id' => $threadId]);
    }

    /**
     * @param  list<array{role: string, content: string}>  $history
     */
    private function userTurnNumber(array $history): int
    {
        $priorUser = 0;
        foreach ($history as $item) {
            if (($item['role'] ?? null) === 'user') {
                $priorUser++;
            }
        }

        return $priorUser + 1;
    }

    private function stageHint(int $userTurn, bool $hasVehicle): string
    {
        $base = match (true) {
            $userTurn <= 1 => 'Шаг 1 (первая жалоба): коротко подтверди понимание. Задай 1–3 наводящих вопроса и/или безопасные проверки. Не выдавай длинный список причин, текст для СТО и все блоки сразу. Срочность — одной короткой фразой, если уже ясно.',
            $userTurn === 2 => 'Шаг 2: по ответам локализуй. Дай 2–4 тезиса вероятных причин с доп. симптомами для исключения. При необходимости 1–2 уточнения. Предложи помощь со СТО мягко («могу помочь сформулировать обращение»), но полный текст — только если уже достаточно данных или пользователь просит.',
            default => 'Шаг 3+: обсуждай уже суженный круг. Реагируй на ответы/проверки пользователя. Если сужать больше нечем — вероятные причины тезисно + СТО + предложи/дай текст обращения к СТО. По-прежнему без простыни и без лишних блоков.',
        };

        if (! $hasVehicle) {
            $base .= ' Машины в гараже нет: можно помочь выбрать автомобиль, объяснить какие поля нужны, сравнить типичные варианты. Не отказывай в разговоре из‑за отсутствия авто.';
        }

        return $base.' Если в досье есть открытые/наблюдаемые кейсы жалоб — учитывай их; при уместности (особенно если прошло несколько дней или новая жалоба может быть связана) мягко уточни статус старой проблемы.';
    }

    private function resolveGuestProfile(AnonymousSession $session): GuestProfile
    {
        $session->loadMissing('guestProfile');
        if ($session->guestProfile !== null) {
            return $session->guestProfile;
        }

        $profile = GuestProfile::query()->create();
        $session->forceFill(['guest_profile_id' => $profile->id])->save();

        return $profile;
    }

    /**
     * @return array{
     *     notes_saved: array{vehicle: list<string>, user: list<string>},
     *     issues_saved: list<array{id: string, title: string, status: string, action: string}>
     * }
     */
    private function captureDurableMemory(
        AiConfigVersion $config,
        GuestProfile $profile,
        ?Vehicle $vehicle,
        string $userMessage,
        string $assistantReply,
    ): array {
        if ($vehicle === null) {
            return [
                'notes_saved' => ['vehicle' => [], 'user' => []],
                'issues_saved' => [],
            ];
        }
        $existingVehicle = $vehicle->aiNotes()
            ->orderByDesc('created_at')
            ->limit(40)
            ->pluck('body')
            ->all();
        $existingUser = $profile->aiNotes()
            ->orderByDesc('created_at')
            ->limit(40)
            ->pluck('body')
            ->all();
        $existingIssues = $vehicle->issues()
            ->orderByDesc('last_touched_at')
            ->limit(20)
            ->get();

        try {
            $result = $this->llm->chat(
                $config->primary_provider,
                $config->primary_model,
                [
                    [
                        'role' => 'system',
                        'content' => 'Ты обновляешь память AutoDoctor после хода диалога. '
                            .'Два раздела заметок: vehicle (машина) и user (человек), плюс issues (кейсы жалоб), '
                            .'плюс skill_signal (уровень знаний владельца). '
                            .'Заметки: если пользователь сам озвучил НЕвременный факт — сохрани. '
                            .'user: имя, вы/ты, стиль, город, профессия, семья, дети, кто ездит. '
                            .'Не сохраняй временное: сегодня устал, сейчас в пробке, разовое настроение. '
                            .'vehicle: цвет, кузов, привод, КПП, двигатель, опции; режим езды; обычный СТО; '
                            .'страховка; парковка; кто водит. Не сохраняй разовые симптомы в заметки — для симптомов есть issues. '
                            .'issues: жалобы/симптомы/неисправности. Создай или обнови кейс, если пользователь описал проблему. '
                            .'Не плоди дубликаты: если похожий open/watching уже есть — обнови его по id. '
                            .'status: open|watching|resolved|dismissed. resolved/dismissed — только если пользователь ясно сказал, '
                            .'что прошло / починили / неактуально. urgency: low|medium|high. '
                            .'checks_suggested — что ассистент предложил проверить; checks_done — что пользователь уже сделал. '
                            .'skill_signal: только при ЯВНЫХ устойчивых признаках уровня знаний '
                            .'«я механик / сам обслуживаю / работаю на СТО» (+5…+15) или '
                            .'«вообще не разбираюсь / боюсь лезть / только сервис» (−5…−15). '
                            .'НЕ реагируй на одно случайное техническое слово («форсунка», «ГРМ») — это null. '
                            .'delta целое −15…+15 или null; reason — короткая цитата/причина или null. '
                            .'Ответь ТОЛЬКО JSON: '
                            .'{"vehicle":{"add":["Цвет серый"],"remove":[]},'
                            .'"user":{"add":["Зовут Алексей"],"remove":[]},'
                            .'"issues":{"upsert":[{"id":null,"title":"Хруст слева при заднем ходе","status":"open",'
                            .'"urgency":"medium","symptoms":"хруст слева спереди назад","checks_suggested":["пыльник ШРУСа"],'
                            .'"checks_done":[],"recommendations":"при усилении — СТО","resolution_note":null}]},'
                            .'"skill_signal":{"delta":null,"reason":null}}. '
                            .'Пустые массивы, если нечего менять.',
                    ],
                    [
                        'role' => 'user',
                        'content' => "Уже сохранённые заметки о машине:\n"
                            .$this->formatExistingList($existingVehicle)
                            ."\n\nУже сохранённые заметки о пользователе:\n"
                            .$this->formatExistingList($existingUser)
                            ."\n\nУже известные кейсы жалоб:\n"
                            .$this->formatExistingIssues($existingIssues)
                            ."\n\nСообщение пользователя:\n{$userMessage}\n\nОтвет ассистента:\n{$assistantReply}",
                    ],
                ],
                450,
            );
        } catch (Throwable) {
            return [
                'notes_saved' => ['vehicle' => [], 'user' => []],
                'issues_saved' => [],
            ];
        }

        $this->agents->recordUsage(
            $profile,
            AiUsageEvent::SOURCE_MEMORY,
            [
                'prompt_tokens' => $result['prompt_tokens'] ?? null,
                'completion_tokens' => $result['completion_tokens'] ?? null,
                'total_tokens' => $result['total_tokens'] ?? null,
                'provider' => $result['provider'] ?? null,
                'model' => $result['model'] ?? null,
            ],
            $vehicle,
        );

        $parsed = $this->parseMemoryJson($result['content']);
        $this->removeVehicleNotes($vehicle, $parsed['vehicle']['remove']);
        $this->removeProfileNotes($profile, $parsed['user']['remove']);
        $savedVehicle = $this->persistVehicleNotes($vehicle, $parsed['vehicle']['add']);
        $savedUser = $this->persistProfileNotes($profile, $parsed['user']['add']);
        $issuesSaved = $this->persistIssues($vehicle, $parsed['issues']);
        $this->applySkillSignal($profile, $parsed['skill_signal']);

        return [
            'notes_saved' => [
                'vehicle' => $savedVehicle,
                'user' => $savedUser,
            ],
            'issues_saved' => $issuesSaved,
        ];
    }

    /**
     * @param  array{delta: ?int, reason: ?string}  $signal
     */
    private function applySkillSignal(GuestProfile $profile, array $signal): void
    {
        $delta = $signal['delta'] ?? null;
        if (! is_int($delta) || $delta === 0) {
            return;
        }

        $this->skills->applyChatSignal($profile, $delta, $signal['reason'] ?? null);
    }

    /**
     * @param  \Illuminate\Support\Collection<int, VehicleIssue>  $issues
     */
    private function formatExistingIssues($issues): string
    {
        if ($issues->isEmpty()) {
            return '(нет)';
        }

        $lines = [];
        foreach ($issues as $issue) {
            $status = match ((string) $issue->status) {
                'open' => 'открыт',
                'watching' => 'на наблюдении',
                'resolved' => 'закрыт',
                'dismissed' => 'снят',
                default => (string) $issue->status,
            };
            $urgency = match ((string) $issue->urgency) {
                'low' => 'низкая',
                'medium' => 'средняя',
                'high' => 'высокая',
                default => (string) $issue->urgency,
            };
            $lines[] = '- id='.$issue->id
                .' ['.$status.' / срочность '.$urgency.'] '
                .$issue->title
                .($issue->symptoms ? ' | симптомы: '.$issue->symptoms : '');
        }

        return implode("\n", $lines);
    }

    /**
     * @return array{
     *     vehicle: array{add: list<string>, remove: list<string>},
     *     user: array{add: list<string>, remove: list<string>},
     *     issues: list<array<string, mixed>>,
     *     skill_signal: array{delta: ?int, reason: ?string}
     * }
     */
    private function parseMemoryJson(string $raw): array
    {
        $empty = [
            'vehicle' => ['add' => [], 'remove' => []],
            'user' => ['add' => [], 'remove' => []],
            'issues' => [],
            'skill_signal' => ['delta' => null, 'reason' => null],
        ];

        $trimmed = trim($raw);
        if (preg_match('/\{[\s\S]*\}/u', $trimmed, $matches) === 1) {
            $trimmed = $matches[0];
        } elseif (preg_match('/\[[\s\S]*\]/u', $trimmed, $matches) === 1) {
            return [
                'vehicle' => ['add' => $this->normalizeNoteList(json_decode($matches[0], true) ?: []), 'remove' => []],
                'user' => ['add' => [], 'remove' => []],
                'issues' => [],
                'skill_signal' => ['delta' => null, 'reason' => null],
            ];
        }

        try {
            $decoded = json_decode($trimmed, true, flags: JSON_THROW_ON_ERROR);
        } catch (Throwable) {
            return $empty;
        }

        if (! is_array($decoded)) {
            return $empty;
        }

        if (array_is_list($decoded)) {
            return [
                'vehicle' => ['add' => $this->normalizeNoteList($decoded), 'remove' => []],
                'user' => ['add' => [], 'remove' => []],
                'issues' => [],
                'skill_signal' => ['delta' => null, 'reason' => null],
            ];
        }

        $issuesRaw = $decoded['issues']['upsert'] ?? $decoded['issues'] ?? [];

        return [
            'vehicle' => $this->normalizeMutation($decoded['vehicle'] ?? []),
            'user' => $this->normalizeMutation($decoded['user'] ?? []),
            'issues' => is_array($issuesRaw) ? $issuesRaw : [],
            'skill_signal' => $this->normalizeSkillSignal($decoded['skill_signal'] ?? null),
        ];
    }

    /**
     * @return array{delta: ?int, reason: ?string}
     */
    private function normalizeSkillSignal(mixed $value): array
    {
        if (! is_array($value)) {
            return ['delta' => null, 'reason' => null];
        }

        $rawDelta = $value['delta'] ?? null;
        $delta = null;
        if (is_int($rawDelta)) {
            $delta = max(-15, min(15, $rawDelta));
        } elseif (is_float($rawDelta) || (is_string($rawDelta) && is_numeric($rawDelta))) {
            $delta = max(-15, min(15, (int) round((float) $rawDelta)));
        }

        $reason = null;
        if (is_string($value['reason'] ?? null)) {
            $text = trim(\App\Support\Utf8::sanitize($value['reason']));
            if ($text !== '') {
                $reason = mb_substr($text, 0, 255);
            }
        }

        return ['delta' => $delta, 'reason' => $reason];
    }

    /**
     * @param  list<array<string, mixed>>  $items
     * @return list<array{id: string, title: string, status: string, action: string}>
     */
    private function persistIssues(Vehicle $vehicle, array $items): array
    {
        $saved = [];
        $count = 0;
        foreach ($items as $item) {
            if (! is_array($item) || $count >= 3) {
                continue;
            }

            $title = $this->normalizeIssueText($item['title'] ?? null, 160);
            if ($title === null) {
                continue;
            }

            $status = is_string($item['status'] ?? null) && in_array($item['status'], VehicleIssue::STATUSES, true)
                ? $item['status']
                : VehicleIssue::STATUS_OPEN;
            $urgency = is_string($item['urgency'] ?? null) && in_array($item['urgency'], VehicleIssue::URGENCIES, true)
                ? $item['urgency']
                : VehicleIssue::URGENCY_MEDIUM;

            $id = is_string($item['id'] ?? null) && $item['id'] !== '' ? $item['id'] : null;
            $issue = null;
            $action = 'created';

            if ($id !== null) {
                $issue = $vehicle->issues()->whereKey($id)->first();
                if ($issue !== null) {
                    $action = 'updated';
                }
            }

            if ($issue === null) {
                $issue = $this->findSimilarOpenIssue($vehicle, $title);
                if ($issue !== null) {
                    $action = 'updated';
                }
            }

            $now = now();
            if ($issue === null) {
                $issue = new VehicleIssue([
                    'vehicle_id' => $vehicle->id,
                    'title' => $title,
                    'first_seen_at' => $now,
                    'last_touched_at' => $now,
                ]);
            }

            $issue->title = $title;
            $issue->urgency = $urgency;
            $issue->symptoms = $this->normalizeIssueText($item['symptoms'] ?? $issue->symptoms, 1000) ?? $issue->symptoms;
            $issue->recommendations = $this->normalizeIssueText($item['recommendations'] ?? $issue->recommendations, 1000)
                ?? $issue->recommendations;
            $issue->checks_suggested = $this->normalizeStringList($item['checks_suggested'] ?? $issue->checks_suggested);
            $issue->checks_done = $this->normalizeStringList($item['checks_done'] ?? $issue->checks_done);
            $resolutionNote = $this->normalizeIssueText($item['resolution_note'] ?? null, 500);
            $issue->applyStatus($status, $resolutionNote);
            $issue->save();

            $saved[] = [
                'id' => (string) $issue->id,
                'title' => $issue->title,
                'status' => $issue->status,
                'action' => $action,
            ];
            $count++;
        }

        return $saved;
    }

    private function findSimilarOpenIssue(Vehicle $vehicle, string $title): ?VehicleIssue
    {
        $needle = mb_strtolower($title);
        $open = $vehicle->issues()
            ->whereIn('status', [VehicleIssue::STATUS_OPEN, VehicleIssue::STATUS_WATCHING])
            ->orderByDesc('last_touched_at')
            ->limit(20)
            ->get();

        foreach ($open as $issue) {
            $existing = mb_strtolower($issue->title);
            if ($existing === $needle) {
                return $issue;
            }
            if (mb_strlen($needle) >= 8 && (str_contains($existing, $needle) || str_contains($needle, $existing))) {
                return $issue;
            }
        }

        return null;
    }

    private function normalizeIssueText(mixed $value, int $max): ?string
    {
        if (! is_string($value)) {
            return null;
        }
        $text = \App\Support\Utf8::sanitize($value);
        $text = trim(preg_replace('/\s+/u', ' ', $text) ?? $text);
        if ($text === '' || mb_strlen($text) < 3) {
            return null;
        }
        if (mb_strlen($text) > $max) {
            $text = rtrim(mb_substr($text, 0, $max));
        }

        return $text;
    }

    /**
     * @param  mixed  $items
     * @return list<string>
     */
    private function normalizeStringList(mixed $items): array
    {
        if (! is_array($items)) {
            return [];
        }
        $out = [];
        foreach ($items as $item) {
            $text = $this->normalizeIssueText($item, 200);
            if ($text === null) {
                continue;
            }
            $out[] = $text;
            if (count($out) >= 8) {
                break;
            }
        }

        return $out;
    }

    /**
     * @param  list<string>  $items
     */
    private function formatExistingList(array $items): string
    {
        if ($items === []) {
            return '(нет)';
        }

        return implode("\n", array_map(fn (string $n): string => '- '.$n, $items));
    }

    /**
     * @param  mixed  $value
     * @return array{add: list<string>, remove: list<string>}
     */
    private function normalizeMutation(mixed $value): array
    {
        if (! is_array($value)) {
            return ['add' => [], 'remove' => []];
        }

        // Old format: ["Кабриолет"]
        if (array_is_list($value)) {
            return ['add' => $this->normalizeNoteList($value), 'remove' => []];
        }

        return [
            'add' => $this->normalizeNoteList($value['add'] ?? []),
            'remove' => $this->normalizeNoteList($value['remove'] ?? []),
        ];
    }

    /**
     * @param  mixed  $items
     * @return list<string>
     */
    private function normalizeNoteList(mixed $items): array
    {
        if (! is_array($items)) {
            return [];
        }

        $out = [];
        foreach ($items as $item) {
            if (! is_string($item)) {
                continue;
            }
            $note = \App\Support\Utf8::sanitize($item);
            $note = trim(preg_replace('/\s+/u', ' ', $note) ?? $note);
            $note = trim($note, " \t\n\r\0\x0B\"'«»“”.");
            if ($note === '' || mb_strlen($note) < 3) {
                continue;
            }
            if (mb_strlen($note) > 280) {
                $note = rtrim(mb_substr($note, 0, 280));
            }
            $out[] = $note;
            if (count($out) >= 5) {
                break;
            }
        }

        return $out;
    }

    /**
     * @param  list<string>  $notes
     * @return list<string>
     */
    private function persistVehicleNotes(Vehicle $vehicle, array $notes): array
    {
        $saved = [];
        foreach ($notes as $note) {
            if ($this->vehicleNoteExists($vehicle, $note)) {
                continue;
            }
            VehicleAiNote::query()->create([
                'vehicle_id' => $vehicle->id,
                'body' => $note,
                'source' => 'chat',
            ]);
            $saved[] = $note;
        }

        return $saved;
    }

    /**
     * @param  list<string>  $notes
     * @return list<string>
     */
    private function persistProfileNotes(GuestProfile $profile, array $notes): array
    {
        $saved = [];
        foreach ($notes as $note) {
            if ($this->profileNoteExists($profile, $note)) {
                continue;
            }
            GuestProfileAiNote::query()->create([
                'guest_profile_id' => $profile->id,
                'body' => $note,
                'source' => 'chat',
            ]);
            $saved[] = $note;
        }

        return $saved;
    }

    /**
     * @param  list<string>  $notes
     */
    private function removeVehicleNotes(Vehicle $vehicle, array $notes): void
    {
        foreach ($notes as $note) {
            $needle = mb_strtolower($note);
            $vehicle->aiNotes()
                ->get()
                ->filter(fn (VehicleAiNote $row): bool => mb_strtolower($row->body) === $needle)
                ->each(fn (VehicleAiNote $row) => $row->delete());
        }
    }

    /**
     * @param  list<string>  $notes
     */
    private function removeProfileNotes(GuestProfile $profile, array $notes): void
    {
        foreach ($notes as $note) {
            $needle = mb_strtolower($note);
            $profile->aiNotes()
                ->get()
                ->filter(fn (GuestProfileAiNote $row): bool => mb_strtolower($row->body) === $needle)
                ->each(fn (GuestProfileAiNote $row) => $row->delete());
        }
    }

    private function vehicleNoteExists(Vehicle $vehicle, string $note): bool
    {
        $needle = mb_strtolower($note);

        return $vehicle->aiNotes()
            ->get(['body'])
            ->contains(fn (VehicleAiNote $row): bool => mb_strtolower($row->body) === $needle);
    }

    private function profileNoteExists(GuestProfile $profile, string $note): bool
    {
        $needle = mb_strtolower($note);

        return $profile->aiNotes()
            ->get(['body'])
            ->contains(fn (GuestProfileAiNote $row): bool => mb_strtolower($row->body) === $needle);
    }

    private function suggestThreadTitle(
        AiConfigVersion $config,
        string $message,
        GuestProfile $profile,
        ?Vehicle $vehicle,
    ): ?string {
        try {
            $result = $this->llm->chat(
                $config->primary_provider,
                $config->primary_model,
                [
                    [
                        'role' => 'system',
                        'content' => 'Ты придумываешь короткие названия тем чата в приложении AutoDoctor. '
                            .'Ответь ТОЛЬКО названием темы: 3–7 слов по сути проблемы/симптома, '
                            .'без кавычек, без точки в конце, без слова «чат». Язык как у пользователя. '
                            .'Примеры: «Хруст спереди слева», «Скрип тормозов», «Гул на трассе».',
                    ],
                    ['role' => 'user', 'content' => $message],
                ],
                32,
            );

            $this->agents->recordUsage(
                $profile,
                AiUsageEvent::SOURCE_TITLE,
                [
                    'prompt_tokens' => $result['prompt_tokens'] ?? null,
                    'completion_tokens' => $result['completion_tokens'] ?? null,
                    'total_tokens' => $result['total_tokens'] ?? null,
                    'provider' => $result['provider'] ?? null,
                    'model' => $result['model'] ?? null,
                ],
                $vehicle,
            );

            return $this->normalizeTitle($result['content']);
        } catch (Throwable) {
            return null;
        }
    }

    private function normalizeTitle(string $raw): ?string
    {
        $title = trim(\App\Support\Utf8::sanitize($raw));
        $title = trim($title, " \t\n\r\0\x0B\"'«»“”.");
        $title = preg_replace('/\s+/u', ' ', $title) ?? $title;
        if ($title === '') {
            return null;
        }
        if (mb_strlen($title) > 48) {
            $title = rtrim(mb_substr($title, 0, 48)).'…';
        }

        return $title;
    }

}
