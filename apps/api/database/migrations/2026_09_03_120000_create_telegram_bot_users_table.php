<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('telegram_bot_users', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('telegram_user_id')->unique();
            $table->string('username', 64)->nullable();
            $table->string('first_name', 128)->nullable();
            $table->string('last_name', 128)->nullable();
            $table->string('note', 255)->nullable();
            $table->unsignedInteger('message_count')->default(0);
            $table->timestampTz('last_message_at')->nullable()->index();
            $table->boolean('is_allowlisted')->default(false)->index();
            $table->timestampTz('allowlisted_at')->nullable();
            $table->timestampTz('removed_from_allowlist_at')->nullable();
            $table->timestampsTz();
        });

        if (Schema::hasTable('telegram_allowlist_entries')) {
            $rows = DB::table('telegram_allowlist_entries')->orderBy('id')->get();
            foreach ($rows as $row) {
                DB::table('telegram_bot_users')->insert([
                    'telegram_user_id' => $row->telegram_user_id,
                    'username' => $row->username,
                    'note' => $row->note,
                    'message_count' => 0,
                    'is_allowlisted' => (bool) $row->is_active,
                    'allowlisted_at' => $row->is_active ? ($row->created_at ?? now()) : null,
                    'removed_from_allowlist_at' => $row->is_active ? null : ($row->updated_at ?? now()),
                    'created_at' => $row->created_at ?? now(),
                    'updated_at' => $row->updated_at ?? now(),
                ]);
            }
            Schema::drop('telegram_allowlist_entries');
        }
    }

    public function down(): void
    {
        Schema::create('telegram_allowlist_entries', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('telegram_user_id')->unique();
            $table->string('username', 64)->nullable();
            $table->string('note', 255)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
        });

        $rows = DB::table('telegram_bot_users')->orderBy('id')->get();
        foreach ($rows as $row) {
            DB::table('telegram_allowlist_entries')->insert([
                'telegram_user_id' => $row->telegram_user_id,
                'username' => $row->username,
                'note' => $row->note,
                'is_active' => (bool) $row->is_allowlisted,
                'created_at' => $row->created_at,
                'updated_at' => $row->updated_at,
            ]);
        }

        Schema::drop('telegram_bot_users');
    }
};
