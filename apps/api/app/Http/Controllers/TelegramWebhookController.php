<?php

namespace App\Http\Controllers;

use App\Services\Telegram\TelegramWebhookHandler;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class TelegramWebhookController extends Controller
{
    public function __invoke(Request $request, TelegramWebhookHandler $handler): JsonResponse
    {
        $expected = (string) config('telegram.webhook_secret');
        if ($expected === '') {
            return response()->json(['ok' => false], 401);
        }

        $provided = (string) $request->header('X-Telegram-Bot-Api-Secret-Token', '');
        if ($provided === '' || ! hash_equals($expected, $provided)) {
            return response()->json(['ok' => false], 401);
        }

        try {
            $handler->handle($request->all());
        } catch (Throwable $exception) {
            Log::error('telegram.webhook_failed', [
                'message' => $exception->getMessage(),
            ]);
        }

        return response()->json(['ok' => true]);
    }
}
