<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('assistant_threads', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('guest_profile_id');
            $table->uuid('vehicle_id');
            $table->uuid('anonymous_session_id')->nullable();
            $table->string('title', 120)->nullable();
            $table->timestampTz('last_message_at')->nullable();
            $table->timestampsTz();

            $table->foreign('guest_profile_id')
                ->references('id')->on('guest_profiles')->cascadeOnDelete();
            $table->foreign('vehicle_id')
                ->references('id')->on('vehicles')->cascadeOnDelete();
            $table->foreign('anonymous_session_id')
                ->references('id')->on('anonymous_sessions')->nullOnDelete();

            $table->index(['last_message_at']);
            $table->index(['guest_profile_id', 'last_message_at']);
        });

        Schema::create('assistant_messages', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('assistant_thread_id');
            $table->string('role', 16); // user|assistant
            $table->text('content');
            $table->string('provider', 64)->nullable();
            $table->string('model', 128)->nullable();
            $table->string('prompt_version', 120)->nullable();
            $table->timestampTz('created_at')->useCurrent();

            $table->foreign('assistant_thread_id')
                ->references('id')->on('assistant_threads')->cascadeOnDelete();
            $table->index(['assistant_thread_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('assistant_messages');
        Schema::dropIfExists('assistant_threads');
    }
};
