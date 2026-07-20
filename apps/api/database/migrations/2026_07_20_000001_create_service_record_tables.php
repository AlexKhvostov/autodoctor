<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_records', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('vehicle_id');
            $table->date('service_date');
            $table->unsignedBigInteger('mileage_value')->nullable();
            $table->string('mileage_unit', 2)->nullable();
            $table->string('evidence_source', 24)->default('self');
            $table->text('note')->nullable();
            $table->unsignedInteger('version')->default(1);
            $table->timestampsTz();

            $table->foreign('vehicle_id')->references('id')->on('vehicles')->cascadeOnDelete();
            $table->index(['vehicle_id', 'service_date', 'created_at']);
        });

        Schema::create('service_record_items', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('service_record_id');
            $table->uuid('work_catalog_item_id');
            $table->timestampsTz();

            $table->foreign('service_record_id')->references('id')->on('service_records')->cascadeOnDelete();
            $table->foreign('work_catalog_item_id')->references('id')->on('work_catalog_items')->restrictOnDelete();
            $table->unique(['service_record_id', 'work_catalog_item_id'], 'service_record_work_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_record_items');
        Schema::dropIfExists('service_records');
    }
};
