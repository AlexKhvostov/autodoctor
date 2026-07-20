<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ApiErrorResponse
{
    public static function make(
        Request $request,
        string $code,
        string $message,
        int $status,
        array $fields = [],
        array $details = [],
    ): JsonResponse {
        $error = [
            'code' => $code,
            'message' => $message,
            'request_id' => (string) $request->attributes->get('request_id'),
        ];

        if ($fields !== []) {
            $error['fields'] = $fields;
        }

        if ($details !== []) {
            $error['details'] = $details;
        }

        return response()->json(['error' => $error], $status);
    }
}
