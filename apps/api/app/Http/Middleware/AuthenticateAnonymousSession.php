<?php

namespace App\Http\Middleware;

use App\Exceptions\ApiException;
use App\Models\AnonymousSession;
use App\Models\IdempotencyRecord;
use App\Support\LocaleResolver;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateAnonymousSession
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->header('X-Session-Token');

        if (! is_string($token) || $token === '') {
            throw new ApiException('SESSION_TOKEN_REQUIRED', __('api.errors.session_token_required'), 401);
        }

        $session = AnonymousSession::query()
            ->where('token_hash', hash('sha256', $token))
            ->first();

        if ($session === null) {
            throw new ApiException('INVALID_SESSION_TOKEN', __('api.errors.invalid_session_token'), 401);
        }

        if (! LocaleResolver::hasAcceptLanguage($request)) {
            App::setLocale(LocaleResolver::normalize($session->locale) ?? LocaleResolver::FALLBACK_LOCALE);
        }

        if ($session->status !== 'active' && ! $this->isCloseReplay($request, $session)) {
            throw new ApiException('SESSION_REVOKED', __('api.errors.session_revoked'), 401);
        }

        if ($session->status === 'active' && $session->expires_at->isPast()) {
            $session->update(['status' => 'expired']);

            throw new ApiException('SESSION_EXPIRED', __('api.errors.session_expired'), 401);
        }

        if ($session->status === 'active') {
            $now = now();
            $session->forceFill([
                'last_activity_at' => $now,
                'expires_at' => $now->copy()->addDays((int) config('guest_bootstrap.session_ttl_days')),
            ])->save();
        }

        $request->attributes->set('anonymous_session', $session);

        return $next($request);
    }

    private function isCloseReplay(Request $request, AnonymousSession $session): bool
    {
        $key = $request->header('Idempotency-Key');

        return $request->isMethod('DELETE')
            && $request->is('api/v1/sessions/current')
            && is_string($key)
            && IdempotencyRecord::query()
                ->where('scope', 'anonymous:'.$session->id)
                ->where('operation', 'closeCurrentSession')
                ->where('idempotency_key', $key)
                ->exists();
    }
}
