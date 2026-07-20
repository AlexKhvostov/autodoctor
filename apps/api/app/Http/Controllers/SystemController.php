<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;

class SystemController extends Controller
{
    public function health(): JsonResponse
    {
        return response()->json([
            'status' => 'ok',
            'service' => 'autodoctor-api',
            'version' => config('guest_bootstrap.api_version'),
            'time' => now()->toISOString(),
        ]);
    }

    public function capabilities(): JsonResponse
    {
        return response()->json(config('guest_bootstrap.capabilities'));
    }
}
