<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicle_ai_notes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('vehicle_id');
            $table->string('body', 280);
            $table->string('source', 32)->default('chat');
            $table->timestampsTz();

            $table->foreign('vehicle_id')
                ->references('id')->on('vehicles')->cascadeOnDelete();
            $table->index(['vehicle_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicle_ai_notes');
    }
};
