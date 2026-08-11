<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('session_ai_notes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('anonymous_session_id');
            $table->string('body', 280);
            $table->string('source', 32)->default('chat');
            $table->timestampsTz();

            $table->foreign('anonymous_session_id')
                ->references('id')->on('anonymous_sessions')->cascadeOnDelete();
            $table->index(['anonymous_session_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('session_ai_notes');
    }
};
