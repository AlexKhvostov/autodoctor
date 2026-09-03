<?php

namespace App\Services\Telegram;

use App\Exceptions\ApiException;
use App\Models\GuestProfile;
use App\Models\TelegramBotUser;
use Illuminate\Support\Facades\Log;
use Throwable;

class TelegramWebhookHandler
{
    public function __construct(
        private readonly TelegramAllowlist $allowlist,
        private readonly TelegramBotClient $bot,
        private readonly TelegramAccessRequestService $accessRequests,
        private readonly TelegramDialogueService $dialogue,
        private readonly TelegramVehicleCommitService $vehicleCommit,
        private readonly TelegramServiceRecordCommitService $serviceRecordCommit,
    ) {}

    public function handle(array $payload): void
    {
        $update = TelegramInboundUpdate::fromPayload($payload);
        if ($update === null || $update->isBot || ! $update->isPrivateChat()) {
            return;
        }

        $botUser = $this->rememberBotUser($update);

        if ($update->isAccessRequest()) {
            if ($this->allowlist->allows($update->telegramUserId)) {
                if ($update->callbackQueryId) {
                    $this->bot->answerCallbackQuery($update->callbackQueryId, 'Доступ уже есть');
                }

                return;
            }
            $this->accessRequests->handle($update, $botUser);

            return;
        }

        if (! $this->allowlist->allows($update->telegramUserId)) {
            if ($update->isCallback && $update->callbackQueryId) {
                $this->bot->answerCallbackQuery($update->callbackQueryId);

                return;
            }
            Log::info('telegram.allowlist.denied', [
                'telegram_user_id' => $update->telegramUserId,
                'username' => $update->username,
            ]);
            $this->bot->sendMessage(
                $update->chatId,
                (string) config('telegram.messages.closed_pilot'),
                $this->bot->accessRequestKeyboard(),
            );

            return;
        }

        if ($update->isSaveVehicle()) {
            if ($update->callbackQueryId) {
                $this->bot->answerCallbackQuery($update->callbackQueryId);
            }
            if (! $this->allowlist->allows($update->telegramUserId)) {
                return;
            }
            $profile = $this->rememberProfile($update);
            try {
                $text = $this->vehicleCommit->commit($profile);
            } catch (ApiException $exception) {
                $text = $exception->getMessage() !== ''
                    ? $exception->getMessage()
                    : (string) config('telegram.messages.ai_unavailable');
            } catch (Throwable $exception) {
                Log::error('telegram.save_vehicle_failed', ['message' => $exception->getMessage()]);
                $text = (string) config('telegram.messages.ai_unavailable');
            }
            $this->bot->sendMessage($update->chatId, $text);

            return;
        }

        if ($update->isSaveServiceRecord()) {
            if ($update->callbackQueryId) {
                $this->bot->answerCallbackQuery($update->callbackQueryId);
            }
            if (! $this->allowlist->allows($update->telegramUserId)) {
                return;
            }
            $profile = $this->rememberProfile($update);
            try {
                $text = $this->serviceRecordCommit->commit($profile);
            } catch (ApiException $exception) {
                $text = $exception->getMessage() !== ''
                    ? $exception->getMessage()
                    : (string) config('telegram.messages.ai_unavailable');
            } catch (Throwable $exception) {
                Log::error('telegram.save_service_record_failed', ['message' => $exception->getMessage()]);
                $text = (string) config('telegram.messages.ai_unavailable');
            }
            $this->bot->sendMessage($update->chatId, $text);

            return;
        }

        if ($update->isCallback) {
            if ($update->callbackQueryId) {
                $this->bot->answerCallbackQuery($update->callbackQueryId);
            }

            return;
        }

        $profile = $this->rememberProfile($update);

        if ($update->isStart) {
            $opening = (string) config('telegram.messages.start');
            $this->dialogue->recordOpening($profile, $opening);
            $this->bot->attachOpenAppMenu($update->chatId);
            $this->bot->sendMessage(
                $update->chatId,
                $opening,
                $this->bot->openAppReplyKeyboard(),
            );

            return;
        }

        if ($update->isGarage()) {
            $this->bot->attachOpenAppMenu($update->chatId);
            $this->bot->sendMessage(
                $update->chatId,
                (string) config('telegram.messages.start'),
                $this->bot->openAppReplyKeyboard(),
            );

            return;
        }

        $text = trim((string) $update->text);
        if ($text === '') {
            return;
        }

        try {
            $reply = $this->dialogue->reply($profile, $text);
        } catch (ApiException $exception) {
            $reply = $exception->getMessage() !== ''
                ? $exception->getMessage()
                : (string) config('telegram.messages.ai_unavailable');
        } catch (Throwable $exception) {
            Log::error('telegram.dialogue_failed', ['message' => $exception->getMessage()]);
            $reply = (string) config('telegram.messages.ai_unavailable');
        }

        $this->bot->sendMessage($update->chatId, $reply, $this->bot->openAppReplyKeyboard());

        if ($this->dialogue->hasVehicle($profile)) {
            $summary = $this->serviceRecordCommit->offerSummary($profile, $reply);
            if ($summary === null) {
                return;
            }

            $this->bot->sendMessage(
                $update->chatId,
                $summary,
                $this->bot->saveDraftKeyboard('save_service_record'),
            );

            return;
        }

        $summary = $this->vehicleCommit->offerSummary($profile);
        if ($summary === null) {
            return;
        }

        $this->bot->sendMessage(
            $update->chatId,
            $summary,
            $this->bot->saveDraftKeyboard('save_vehicle'),
        );
    }

    private function rememberBotUser(TelegramInboundUpdate $update): TelegramBotUser
    {
        $user = TelegramBotUser::query()->firstOrNew([
            'telegram_user_id' => $update->telegramUserId,
        ]);
        $user->username = $update->username ?: $user->username;
        $user->first_name = $update->firstName ?: $user->first_name;
        $user->last_name = $update->lastName ?: $user->last_name;
        $user->last_message_at = now();
        if (! $update->isCallback) {
            $user->message_count = (int) $user->message_count + 1;
        }
        $user->save();

        return $user;
    }

    private function rememberProfile(TelegramInboundUpdate $update): GuestProfile
    {
        $profile = GuestProfile::query()->firstOrNew([
            'telegram_id' => $update->telegramUserId,
        ]);
        $profile->telegram_username = $update->username;
        $profile->telegram_first_name = $update->firstName;
        $profile->save();

        return $profile;
    }
}
