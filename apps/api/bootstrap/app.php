<?php

use App\Exceptions\ApiException;
use App\Http\Middleware\AssignRequestId;
use App\Http\Middleware\AuthenticateAnonymousSession;
use App\Http\Middleware\ResolveApiLocale;
use App\Support\ApiErrorResponse;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->prepend(ResolveApiLocale::class);
        $middleware->prependToGroup('api', AssignRequestId::class);
        $middleware->alias([
            'session.auth' => AuthenticateAnonymousSession::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );

        $exceptions->render(function (ApiException $exception, Request $request) {
            return ApiErrorResponse::make(
                $request,
                $exception->errorCode,
                $exception->getMessage(),
                $exception->status,
                details: $exception->details,
            );
        });

        $exceptions->render(function (ValidationException $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return ApiErrorResponse::make(
                $request,
                'VALIDATION_FAILED',
                __('api.errors.validation_failed'),
                422,
                fields: $exception->errors(),
            );
        });

        $exceptions->render(function (Throwable $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            $status = $exception instanceof HttpExceptionInterface
                ? $exception->getStatusCode()
                : 500;

            return ApiErrorResponse::make(
                $request,
                $status === 404 ? 'NOT_FOUND' : 'INTERNAL_SERVER_ERROR',
                $status === 404
                    ? __('api.errors.not_found')
                    : __('api.errors.internal_server_error'),
                $status,
            );
        });
    })->create();
