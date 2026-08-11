<?php

namespace App\Http\Controllers;

use App\Http\Resources\MileageObservationResource;
use App\Models\AnonymousSession;
use App\Models\MileageObservation;
use App\Services\VehicleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MileageObservationController extends Controller
{
    public function __construct(
        private readonly VehicleService $vehicles,
    ) {}

    public function index(Request $request, string $vehicle): JsonResponse
    {
        $model = $this->vehicles->owned($this->session($request), $vehicle);
        $validated = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', Rule::in([20, 50, 100, 200])],
        ]);
        $page = MileageObservation::query()
            ->where('vehicle_id', $model->id)
            ->orderBy('observed_at')
            ->orderBy('created_at')
            ->orderBy('id')
            ->paginate($validated['per_page'] ?? 100, ['*'], 'page', $validated['page'] ?? 1);

        return response()->json([
            'items' => MileageObservationResource::collection($page->getCollection())->resolve($request),
            'meta' => [
                'page' => $page->currentPage(),
                'per_page' => $page->perPage(),
                'total' => $page->total(),
                'total_pages' => max(1, $page->lastPage()),
            ],
        ]);
    }

    private function session(Request $request): AnonymousSession
    {
        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');

        return $session;
    }
}
