<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('condition_observations', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('vehicle_id');
            $table->uuid('work_catalog_item_id');
            $table->unsignedTinyInteger('wear_percent');
            $table->date('observed_at');
            $table->unsignedBigInteger('mileage_value')->nullable();
            $table->string('mileage_unit', 2)->nullable();
            $table->string('source', 16);
            $table->text('note')->nullable();
            $table->timestampsTz();

            $table->foreign('vehicle_id')->references('id')->on('vehicles')->cascadeOnDelete();
            $table->foreign('work_catalog_item_id')->references('id')->on('work_catalog_items')->restrictOnDelete();
            $table->index(
                ['vehicle_id', 'work_catalog_item_id', 'observed_at', 'created_at', 'id'],
                'condition_observations_latest_index',
            );
        });

        Schema::create('vehicle_plan_item_ui_preferences', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('vehicle_id');
            $table->uuid('work_catalog_item_id');
            $table->boolean('collapsed')->default(false);
            $table->unsignedInteger('version')->default(1);
            $table->timestampsTz();

            $table->foreign('vehicle_id')->references('id')->on('vehicles')->cascadeOnDelete();
            $table->foreign('work_catalog_item_id')->references('id')->on('work_catalog_items')->restrictOnDelete();
            $table->unique(
                ['vehicle_id', 'work_catalog_item_id'],
                'vehicle_plan_ui_preferences_vehicle_work_unique',
            );
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicle_plan_item_ui_preferences');
        Schema::dropIfExists('condition_observations');
    }
};
