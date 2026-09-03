<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('telegram_bot_users', function (Blueprint $table) {
            $table->json('pending_vehicle_draft')->nullable();
            $table->json('pending_service_record_draft')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('telegram_bot_users', function (Blueprint $table) {
            $table->dropColumn(['pending_vehicle_draft', 'pending_service_record_draft']);
        });
    }
};
