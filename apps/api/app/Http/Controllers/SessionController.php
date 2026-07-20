<?php

namespace App\Http\Controllers;

use App\Http\Resources\SessionResource;
use App\Models\AnonymousSession;
use App\Services\IdempotencyService;
use App\Support\LocaleResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class SessionController extends Controller
{
    public function __construct(private readonly IdempotencyService $idempotency) {}

    public function store(Request $request): JsonResponse
    {
        $this->rejectUnknownFields($request, ['locale', 'platform', 'app_version']);

        $validated = Validator::make($request->all(), [
            'locale' => ['required', 'string', 'max:32', 'regex:/^(?:ru|en)(?:[-_][A-Za-z]{2})?$/i'],
            'platform' => ['required', 'in:android,ios'],
            'app_version' => ['sometimes', 'nullable', 'string', 'max:255'],
        ])->validate();
        $validated['locale'] = LocaleResolver::normalize($validated['locale']);

        return $this->idempotency->execute(
            $request,
            'public',
            'createAnonymousSession',
            function (string $key) use ($validated): JsonResponse {
                $token = $this->tokenForIdempotencyKey($key);
                $now = now();
                $session = AnonymousSession::query()->create([
                    ...$validated,
                    'token_hash' => hash('sha256', $token),
                    'status' => 'active',
                    'last_activity_at' => $now,
                    'expires_at' => $now->copy()->addDays((int) config('guest_bootstrap.session_ttl_days')),
                ]);

                return response()->json([
                    'session' => (new SessionResource($session))->resolve(),
                    'session_token' => $token,
                ], 201);
            },
            // The token is never persisted. A replay derives it with a keyed HMAC
            // because OpenAPI has no installation identifier for a safer public scope.
            fn (array $body): array => ['session' => $body['session']],
            fn (array $body, string $key): array => [
                ...$body,
                'session_token' => $this->tokenForIdempotencyKey($key),
            ],
        );
    }

    public function show(Request $request): JsonResponse
    {
        return response()->json(
            (new SessionResource($request->attributes->get('anonymous_session')))->resolve(),
        );
    }

    public function destroy(Request $request): Response
    {
        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');

        return $this->idempotency->execute(
            $request,
            'anonymous:'.$session->id,
            'closeCurrentSession',
            function () use ($session): Response {
                $session->update(['status' => 'closed']);

                return response(status: 204);
            },
        );
    }

    private function tokenForIdempotencyKey(string $key): string
    {
        $binary = hash_hmac(
            'sha256',
            'anonymous-session:'.$key,
            (string) config('app.key'),
            true,
        );

        return rtrim(strtr(base64_encode($binary), '+/', '-_'), '=');
    }

    private function rejectUnknownFields(Request $request, array $allowed): void
    {
        $unknown = array_diff(array_keys($request->all()), $allowed);

        if ($unknown !== []) {
            throw ValidationException::withMessages(
                array_fill_keys($unknown, [__('api.fields.unknown')]),
            );
        }
    }
}
