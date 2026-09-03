<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('telegram_bot_users', function (Blueprint $table) {
            $table->timestampTz('access_requested_at')->nullable()->after('removed_from_allowlist_at');
        });
    }

    public function down(): void
    {
        Schema::table('telegram_bot_users', function (Blueprint $table) {
            $table->dropColumn('access_requested_at');
        });
    }
};
