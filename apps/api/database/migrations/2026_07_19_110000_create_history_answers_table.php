<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('history_answers', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('vehicle_id');
            $table->uuid('work_catalog_item_id');
            $table->enum('answer', [
                'done_known',
                'done_unknown',
                'not_done',
                'unknown',
                'not_applicable',
            ]);
            $table->date('performed_date')->nullable();
            $table->unsignedBigInteger('performed_mileage_km')->nullable();
            $table->unsignedInteger('version')->default(1);
            $table->timestampsTz();

            $table->foreign('vehicle_id')->references('id')->on('vehicles')->cascadeOnDelete();
            $table->foreign('work_catalog_item_id')->references('id')->on('work_catalog_items')->restrictOnDelete();
            $table->unique(['vehicle_id', 'work_catalog_item_id'], 'history_answers_vehicle_work_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('history_answers');
    }
};
