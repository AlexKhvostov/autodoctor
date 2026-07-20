<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('anonymous_sessions', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->char('token_hash', 64)->unique();
            $table->string('status', 16)->default('active');
            $table->string('locale', 32);
            $table->string('platform', 16);
            $table->string('app_version')->nullable();
            $table->timestampTz('last_activity_at');
            $table->timestampTz('expires_at')->index();
            $table->unsignedInteger('version')->default(1);
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('anonymous_sessions');
    }
};
