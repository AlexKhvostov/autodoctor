<?php

use App\Http\Controllers\TelegramWebhookController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'service' => 'autodoctor-api',
        'documentation' => '/api/v1/health',
    ]);
});

Route::post('/telegram/webhook', TelegramWebhookController::class);
