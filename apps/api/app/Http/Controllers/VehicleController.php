<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreVehicleRequest;
use App\Http\Requests\UpdateVehicleRequest;
use App\Http\Resources\MileageObservationResource;
use App\Http\Resources\VehicleResource;
use App\Models\AnonymousSession;
use App\Models\Vehicle;
use App\Services\IdempotencyService;
use App\Services\VehicleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class VehicleController extends Controller
{
    public function __construct(
        private readonly VehicleService $vehicles,
        private readonly IdempotencyService $idempotency,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $pagination = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', Rule::in([20, 50, 100])],
        ]);
        $session = $this->session($request);
        $page = $pagination['page'] ?? 1;
        $perPage = $pagination['per_page'] ?? 20;
        $paginator = Vehicle::query()
            ->with('configuration')
            ->where('anonymous_session_id', $session->id)
            ->latest('created_at')
            ->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'items' => VehicleResource::collection($paginator->items())->resolve(),
            'meta' => [
                'page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'total_pages' => $paginator->lastPage(),
            ],
        ]);
    }

    public function store(StoreVehicleRequest $request): JsonResponse
    {
        $session = $this->session($request);

        return $this->idempotency->execute(
            $request,
            'anonymous:'.$session->id,
            'createVehicle',
            function () use ($session, $request): JsonResponse {
                $vehicle = $this->vehicles->create($session, $request->validated());

                return response()->json((new VehicleResource($vehicle))->resolve(), 201);
            },
        );
    }

    public function show(Request $request, string $vehicle): JsonResponse
    {
        $model = $this->vehicles->owned($this->session($request), $vehicle);

        return response()->json((new VehicleResource($model))->resolve());
    }

    public function update(UpdateVehicleRequest $request, string $vehicle): JsonResponse
    {
        $session = $this->session($request);

        return $this->idempotency->execute(
            $request,
            'anonymous:'.$session->id,
            'updateVehicle:'.$vehicle,
            function () use ($session, $vehicle, $request): JsonResponse {
                $model = $this->vehicles->update($session, $vehicle, $request->validated());

                return response()->json((new VehicleResource($model))->resolve());
            },
        );
    }

    public function updateMileage(Request $request, string $vehicle): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'mileage' => ['required', 'array'],
            'mileage.value' => ['required', 'integer', 'min:0'],
            'mileage.unit' => ['required', Rule::in(['km', 'mi'])],
            'observed_at' => [
                'required',
                'date',
                'regex:/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/',
            ],
            'decrease_confirmed' => ['sometimes', 'boolean'],
            'decrease_reason' => ['nullable', 'string', 'min:1', 'max:500', 'required_if:decrease_confirmed,true'],
            'version' => ['required', 'integer', 'min:1'],
        ]);
        $validator->after(function ($validator) use ($request): void {
            if (array_diff(array_keys($request->all()), [
                'mileage', 'observed_at', 'decrease_confirmed', 'decrease_reason', 'version',
            ]) !== []) {
                $validator->errors()->add('request', __('api.fields.unknown'));
            }
            if (is_array($request->input('mileage'))
                && array_diff(array_keys($request->input('mileage')), ['value', 'unit']) !== []) {
                $validator->errors()->add('mileage', __('api.fields.unknown'));
            }
        });
        if ($validator->fails()) {
            throw new ValidationException($validator);
        }
        $validated = $validator->validated();
        $session = $this->session($request);

        return $this->idempotency->execute(
            $request,
            'anonymous:'.$session->id,
            'updateVehicleMileage:'.$vehicle,
            function () use ($session, $vehicle, $validated, $request): JsonResponse {
                [$model, $observation, $snapshot] = $this->vehicles->updateMileage($session, $vehicle, $validated);

                return response()->json([
                    'vehicle_id' => $model->id,
                    'vehicle_version' => $model->version,
                    'current_mileage' => [
                        'value' => $model->current_mileage,
                        'unit' => $model->mileage_unit,
                    ],
                    'observation' => (new MileageObservationResource($observation))->resolve($request),
                    'maintenance_plan_id' => $snapshot->id,
                ]);
            },
        );
    }

    public function destroy(Request $request, string $vehicle): Response
    {
        $session = $this->session($request);

        return $this->idempotency->execute(
            $request,
            'anonymous:'.$session->id,
            'deleteVehicle:'.$vehicle,
            function () use ($session, $vehicle): Response {
                $this->vehicles->delete($session, $vehicle);

                return response(status: 204);
            },
        );
    }

    private function session(Request $request): AnonymousSession
    {
        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');

        return $session;
    }
}
