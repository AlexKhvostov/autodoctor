<?php

use App\Http\Controllers\TelegramMiniAppController;
use App\Http\Controllers\TelegramWebhookController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'service' => 'autodoctor-api',
        'documentation' => '/api/v1/health',
    ]);
});

Route::post('/telegram/webhook', TelegramWebhookController::class);
Route::get('/telegram/app', [TelegramMiniAppController::class, 'show']);
Route::get('/telegram/app/state', [TelegramMiniAppController::class, 'state']);
Route::patch('/telegram/app/agent/preferences', [TelegramMiniAppController::class, 'updateAgentPreferences']);
Route::patch('/telegram/app/agent/skill', [TelegramMiniAppController::class, 'updateAgentSkill']);
