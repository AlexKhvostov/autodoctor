<?php

namespace App\Http\Controllers;

use App\Services\Ai\AiHealthReporter;
use Illuminate\Http\JsonResponse;

class SystemController extends Controller
{
    public function __construct(private readonly AiHealthReporter $health) {}

    public function health(): JsonResponse
    {
        $checks = $this->health->snapshot();

        return response()->json([
            'status' => $checks['status'],
            'service' => 'autodoctor-api',
            'version' => config('guest_bootstrap.api_version'),
            'time' => now()->toISOString(),
            'checks' => [
                'database' => $checks['database'],
                'ai' => $checks['ai'],
            ],
        ]);
    }

    public function capabilities(): JsonResponse
    {
        return response()->json(config('guest_bootstrap.capabilities'));
    }

    public function probeAi(): JsonResponse
    {
        $checks = $this->health->snapshot();
        $probe = $this->health->probe();

        return response()->json([
            'status' => $probe['ok'] ? 'ok' : 'error',
            'checks' => [
                'database' => $checks['database'],
                'ai' => $checks['ai'],
            ],
            'probe' => $probe,
        ], $probe['ok'] ? 200 : 503);
    }
}
