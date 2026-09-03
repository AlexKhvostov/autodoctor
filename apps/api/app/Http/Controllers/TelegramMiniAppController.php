<?php

namespace App\Http\Controllers;

use App\Services\Telegram\TelegramAllowlist;
use App\Services\Telegram\TelegramInitDataValidator;
use App\Services\Telegram\TelegramMiniAppSnapshot;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class TelegramMiniAppController extends Controller
{
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
                'subtitle' => 'Откройте приложение кнопкой в боте AutoDoctor.',
            ], 401);
        }

        if (! $allowlist->allows($userId)) {
            return response()->json([
                'ok' => true,
                'allowed' => false,
                'greeting' => 'AutoDoctor',
                'subtitle' => 'Сейчас закрытый пилот. Напишите боту и нажмите «Запросить доступ».',
                'vehicle' => null,
                'works' => [],
            ]);
        }

        return response()->json([
            'ok' => true,
            ...$snapshot->forTelegramUser($userId),
        ]);
    }
}
