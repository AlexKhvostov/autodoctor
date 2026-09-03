<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('telegram_allowlist_entries', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('telegram_user_id')->unique();
            $table->string('username', 64)->nullable();
            $table->string('note', 255)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('telegram_allowlist_entries');
    }
};
