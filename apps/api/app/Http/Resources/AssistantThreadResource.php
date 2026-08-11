<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\AssistantThread */
class AssistantThreadResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'title_source' => $this->title_source ?? 'auto',
            'status' => $this->status ?? 'active',
            'last_message_at' => optional($this->last_message_at)?->toIso8601String(),
            'resolved_at' => optional($this->resolved_at)?->toIso8601String(),
            'archived_at' => optional($this->archived_at)?->toIso8601String(),
            'messages_count' => $this->when(
                isset($this->messages_count),
                fn () => (int) $this->messages_count,
                fn () => $this->messages()->count(),
            ),
            'created_at' => optional($this->created_at)?->toIso8601String(),
            'updated_at' => optional($this->updated_at)?->toIso8601String(),
            'messages' => AssistantMessageResource::collection($this->whenLoaded('messages')),
        ];
    }
}
