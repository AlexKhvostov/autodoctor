<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\IdempotencyRecord;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;

class IdempotencyService
{
    public function execute(
        Request $request,
        string $scope,
        string $operation,
        Closure $callback,
        ?Closure $storedBody = null,
        ?Closure $replayedBody = null,
    ): Response {
        $key = $request->header('Idempotency-Key');

        if (! is_string($key) || ! Str::isUuid($key)) {
            throw ValidationException::withMessages([
                'Idempotency-Key' => [__('api.errors.idempotency_key_uuid')],
            ]);
        }

        $requestHash = hash('sha256', json_encode(
            $this->canonicalize($request->json()->all()),
            JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE,
        ));

        $existing = IdempotencyRecord::query()
            ->where('scope', $scope)
            ->where('operation', $operation)
            ->where('idempotency_key', $key)
            ->first();

        if ($existing !== null) {
            if (! hash_equals($existing->request_hash, $requestHash)) {
                throw new ApiException(
                    'IDEMPOTENCY_KEY_CONFLICT',
                    __('api.errors.idempotency_key_conflict'),
                    409,
                );
            }

            $body = $existing->response_body;
            if ($replayedBody !== null) {
                $body = $replayedBody($body, $key);
            }

            return $body === null
                ? response(status: $existing->status_code)
                : response()->json($body, $existing->status_code);
        }

        return DB::transaction(function () use (
            $callback,
            $key,
            $operation,
            $requestHash,
            $scope,
            $storedBody,
        ): Response {
            $response = $callback($key);
            $body = $response instanceof JsonResponse
                ? $response->getData(true)
                : null;

            IdempotencyRecord::query()->create([
                'scope' => $scope,
                'operation' => $operation,
                'idempotency_key' => $key,
                'request_hash' => $requestHash,
                'status_code' => $response->getStatusCode(),
                'response_body' => $storedBody === null ? $body : $storedBody($body),
            ]);

            return $response;
        });
    }

    private function canonicalize(mixed $value): mixed
    {
        if (! is_array($value)) {
            return $value;
        }

        if (array_is_list($value)) {
            return array_map($this->canonicalize(...), $value);
        }

        ksort($value);

        return array_map($this->canonicalize(...), $value);
    }
}
