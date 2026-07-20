<?php

namespace App\Http\Controllers;

use App\Models\AnonymousSession;
use App\Services\MileageForecastService;
use App\Services\VehicleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MileageForecastController extends Controller
{
    public function __construct(
        private readonly VehicleService $vehicles,
        private readonly MileageForecastService $forecasts,
    ) {}

    public function show(Request $request, string $vehicle): JsonResponse
    {
        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');
        $model = $this->vehicles->owned($session, $vehicle);

        return response()->json($this->forecasts->make($model, $request));
    }
}
