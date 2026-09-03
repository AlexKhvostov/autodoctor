<?php

namespace Tests\Unit;

use App\Models\TelegramBotUser;
use App\Services\Telegram\TelegramAllowlist;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TelegramAllowlistTest extends TestCase
{
    use RefreshDatabase;

    public function test_empty_env_and_empty_table_allow_nobody(): void
    {
        config(['telegram.allowlist_ids' => '']);

        $list = app(TelegramAllowlist::class);

        $this->assertSame([], $list->allowedIds());
        $this->assertFalse($list->allows(123456));
    }

    public function test_env_ids_are_parsed_and_allow_listed_users(): void
    {
        config(['telegram.allowlist_ids' => ' 111, 222 ; not-a-number, 0, 111 ']);

        $list = app(TelegramAllowlist::class);

        $this->assertSame([111, 222], $list->idsFromEnv());
        $this->assertTrue($list->allows(111));
        $this->assertTrue($list->allows(222));
        $this->assertFalse($list->allows(333));
    }

    public function test_database_allowlist_and_removal_timestamps(): void
    {
        config(['telegram.allowlist_ids' => '']);

        $allowed = TelegramBotUser::query()->create([
            'telegram_user_id' => 999001,
            'username' => 'pilot',
        ]);
        $allowed->setAllowlisted(true);

        $writer = TelegramBotUser::query()->create([
            'telegram_user_id' => 999002,
            'is_allowlisted' => false,
        ]);

        $list = app(TelegramAllowlist::class);

        $this->assertTrue($list->allows(999001));
        $this->assertFalse($list->allows(999002));
        $this->assertNotNull($allowed->fresh()->allowlisted_at);
        $this->assertNull($allowed->fresh()->removed_from_allowlist_at);

        $allowed->setAllowlisted(false);
        $allowed->refresh();

        $this->assertFalse($list->allows(999001));
        $this->assertNotNull($allowed->removed_from_allowlist_at);
        $this->assertFalse($writer->is_allowlisted);
    }
}
