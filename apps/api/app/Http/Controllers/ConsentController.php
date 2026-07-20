<?php

namespace App\Http\Controllers;

use App\Http\Resources\ConsentReceiptResource;
use App\Models\AnonymousSession;
use App\Models\Consent;
use App\Services\IdempotencyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class ConsentController extends Controller
{
    public function __construct(private readonly IdempotencyService $idempotency) {}

    public function current(): JsonResponse
    {
        return response()->json([
            'items' => collect(config('guest_bootstrap.consent_documents'))
                ->map(function (array $document): array {
                    $translation = __($document['translation_key']);

                    return [
                        'purpose' => $document['purpose'],
                        'version' => $document['version'],
                        'title' => $translation['title'],
                        'text' => $translation['text'],
                        'required' => $document['required'],
                        'effective_at' => $document['effective_at'],
                    ];
                })
                ->values()
                ->all(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $this->validateShape($request);

        $validated = Validator::make($request->all(), [
            'decisions' => ['required', 'array', 'min:1'],
            'decisions.*' => ['required', 'array'],
            'decisions.*.purpose' => [
                'required',
                'string',
                'distinct',
                'in:essential_processing,ai_processing,analytics,marketing',
            ],
            'decisions.*.version' => ['required', 'string'],
            'decisions.*.granted' => ['required', 'boolean'],
        ])->validate();

        $documents = collect(config('guest_bootstrap.consent_documents'))->keyBy('purpose');
        $decisions = collect($validated['decisions'])->keyBy('purpose');
        $errors = [];

        foreach ($documents->where('required', true) as $purpose => $document) {
            if (! $decisions->has($purpose)) {
                $errors['decisions'][] = __('api.fields.required_consent_decision', ['purpose' => $purpose]);
            } elseif ($decisions[$purpose]['granted'] !== true) {
                $errors["decisions.{$purpose}.granted"][] = __('api.fields.required_consent_granted');
            }
        }

        foreach ($decisions as $purpose => $decision) {
            $document = $documents->get($purpose);
            if ($document === null || $document['version'] !== $decision['version']) {
                $errors["decisions.{$purpose}.version"][] = __('api.fields.stale_consent_version');
            }
        }

        if ($errors !== []) {
            throw ValidationException::withMessages($errors);
        }

        /** @var AnonymousSession $session */
        $session = $request->attributes->get('anonymous_session');

        return $this->idempotency->execute(
            $request,
            'anonymous:'.$session->id,
            'grantConsents',
            function () use ($session, $validated): JsonResponse {
                $items = [];

                foreach ($validated['decisions'] as $decision) {
                    $consent = Consent::query()->firstOrNew([
                        'anonymous_session_id' => $session->id,
                        'purpose' => $decision['purpose'],
                        'document_version' => $decision['version'],
                    ]);

                    if (! $consent->exists || $consent->granted !== $decision['granted']) {
                        $consent->fill([
                            'granted' => $decision['granted'],
                            'decided_at' => now(),
                        ])->save();
                    }

                    $items[] = (new ConsentReceiptResource($consent))->resolve();
                }

                return response()->json(['items' => $items], 201);
            },
        );
    }

    private function validateShape(Request $request): void
    {
        $errors = [];

        foreach (array_diff(array_keys($request->all()), ['decisions']) as $field) {
            $errors[$field][] = __('api.fields.unknown');
        }

        foreach ((array) $request->input('decisions', []) as $index => $decision) {
            if (! is_array($decision)) {
                continue;
            }

            foreach (array_diff(array_keys($decision), ['purpose', 'version', 'granted']) as $field) {
                $errors["decisions.{$index}.{$field}"][] = __('api.fields.unknown');
            }
        }

        if ($errors !== []) {
            throw ValidationException::withMessages($errors);
        }
    }
}
