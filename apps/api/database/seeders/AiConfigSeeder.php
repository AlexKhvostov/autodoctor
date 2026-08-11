<?php

namespace Database\Seeders;

use App\Models\AiConfigVersion;
use App\Models\AiPromptVersion;
use Illuminate\Database\Seeder;

class AiConfigSeeder extends Seeder
{
    public function run(): void
    {
        $promptPath = base_path('../../prompts/ai-chat-system.md');
        if (! is_file($promptPath)) {
            $promptPath = base_path('../prompts/ai-chat-system.md');
        }

        $raw = is_file($promptPath)
            ? (string) file_get_contents($promptPath)
            : $this->fallbackPrompt();

        $body = $this->extractPromptBody($raw);

        $prompt = AiPromptVersion::query()->firstOrNew(['code' => 'ai-chat-system']);
        $prompt->fill([
            'name' => 'AutoDoctor AI Chat v17 — human labels, no raw DB codes',
            'body' => $body,
            'status' => AiPromptVersion::STATUS_APPROVED,
        ]);
        $prompt->save();

        if (! $prompt->isApproved()) {
            $prompt->approve();
        }

        if (AiConfigVersion::query()->where('is_active', true)->exists()) {
            return;
        }

        AiConfigVersion::query()->create([
            'primary_provider' => 'abacus',
            'primary_model' => config('ai.providers.abacus.default_model', 'route-llm'),
            'fallback_provider' => 'deepseek',
            'fallback_model' => config('ai.providers.deepseek.default_model', 'deepseek-chat'),
            'enabled' => true,
            'prompt_version_id' => $prompt->id,
            'max_tokens' => 1024,
            'author' => 'seeder',
            'is_active' => true,
        ]);
    }

    private function extractPromptBody(string $markdown): string
    {
        if (preg_match('/^---\s*$/m', $markdown, $matches, PREG_OFFSET_CAPTURE) === 1) {
            $offset = $matches[0][1] + strlen($matches[0][0]);

            return trim(substr($markdown, $offset));
        }

        return trim($markdown);
    }

    private function fallbackPrompt(): string
    {
        return <<<'PROMPT'
Ты — AI-ассистент приложения AutoDoctor: помощник автовладельца по обслуживанию, износу узлов, плану работ и пониманию срочности.

Роль: отвечай коротко и по делу; опирайся на факты о машине, если они переданы; если данных мало — скажи, чего не хватает.

Границы: не заменяешь диагностику на СТО; не выдумывай жёсткие регламенты OEM; не советуй опасные действия.

Стиль: язык пользователя; краткий вывод → что проверить → срочность → что сделать в AutoDoctor.
PROMPT;
    }
}
