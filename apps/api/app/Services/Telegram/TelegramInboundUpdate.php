<?php

namespace App\Services\Telegram;

final class TelegramInboundUpdate
{
    public function __construct(
        public readonly int $telegramUserId,
        public readonly int $chatId,
        public readonly string $chatType,
        public readonly ?string $username,
        public readonly ?string $firstName,
        public readonly ?string $lastName,
        public readonly ?string $text,
        public readonly bool $isBot,
        public readonly bool $isStart,
    ) {}

    public static function fromPayload(array $payload): ?self
    {
        $message = $payload['message'] ?? $payload['edited_message'] ?? null;
        $from = null;
        $chat = null;
        $text = null;

        if (is_array($message)) {
            $from = $message['from'] ?? null;
            $chat = $message['chat'] ?? null;
            $text = isset($message['text']) ? (string) $message['text'] : null;
        } elseif (isset($payload['callback_query']) && is_array($payload['callback_query'])) {
            $from = $payload['callback_query']['from'] ?? null;
            $chat = $payload['callback_query']['message']['chat'] ?? null;
            $text = isset($payload['callback_query']['data'])
                ? (string) $payload['callback_query']['data']
                : null;
        }

        if (! is_array($from) || ! is_array($chat)) {
            return null;
        }

        $telegramUserId = (int) ($from['id'] ?? 0);
        $chatId = (int) ($chat['id'] ?? 0);
        if ($telegramUserId <= 0 || $chatId === 0) {
            return null;
        }

        $trimmed = is_string($text) ? trim($text) : '';
        $command = strtolower(strtok($trimmed, ' ') ?: '');

        return new self(
            telegramUserId: $telegramUserId,
            chatId: $chatId,
            chatType: (string) ($chat['type'] ?? ''),
            username: isset($from['username']) ? (string) $from['username'] : null,
            firstName: isset($from['first_name']) ? (string) $from['first_name'] : null,
            lastName: isset($from['last_name']) ? (string) $from['last_name'] : null,
            text: $text,
            isBot: (bool) ($from['is_bot'] ?? false),
            isStart: $command === '/start' || str_starts_with($command, '/start@'),
        );
    }

    public function isPrivateChat(): bool
    {
        return $this->chatType === 'private';
    }
}
