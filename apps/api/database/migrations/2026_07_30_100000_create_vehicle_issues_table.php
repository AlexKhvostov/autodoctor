<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicle_issues', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('vehicle_id');
            $table->uuid('source_thread_id')->nullable();
            $table->string('title', 160);
            $table->string('status', 24)->default('open'); // open|watching|resolved|dismissed
            $table->string('urgency', 16)->default('medium'); // low|medium|high
            $table->text('symptoms')->nullable();
            $table->json('checks_suggested')->nullable();
            $table->json('checks_done')->nullable();
            $table->text('recommendations')->nullable();
            $table->text('resolution_note')->nullable();
            $table->timestampTz('first_seen_at')->nullable();
            $table->timestampTz('last_touched_at')->nullable();
            $table->timestampTz('resolved_at')->nullable();
            $table->timestampsTz();

            $table->foreign('vehicle_id')
                ->references('id')->on('vehicles')->cascadeOnDelete();
            $table->foreign('source_thread_id')
                ->references('id')->on('assistant_threads')->nullOnDelete();

            $table->index(['vehicle_id', 'status']);
            $table->index(['vehicle_id', 'last_touched_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicle_issues');
    }
};
