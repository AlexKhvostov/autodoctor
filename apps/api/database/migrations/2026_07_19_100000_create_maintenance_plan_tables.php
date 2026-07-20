<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('maintenance_sources', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('source_kind', 32);
            $table->string('title', 160);
            $table->string('publisher', 160);
            $table->string('document_version', 80);
            $table->string('publication_status', 24);
            $table->text('methodology_note');
            $table->string('url', 2048)->nullable();
            $table->boolean('official_oem')->default(false);
            $table->date('effective_date')->nullable();
            $table->timestampTz('verified_at')->nullable();
            $table->timestampsTz();
        });

        Schema::create('ruleset_versions', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('version', 80)->unique();
            $table->string('content_hash', 71);
            $table->timestampTz('published_at')->nullable();
            $table->timestampsTz();
        });

        Schema::create('work_catalog_items', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('code', 80)->unique();
            $table->json('localized_name');
            $table->timestampsTz();
        });

        Schema::create('maintenance_rules', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('ruleset_version_id');
            $table->uuid('source_id');
            $table->uuid('work_catalog_item_id');
            $table->string('work_code', 80);
            $table->string('rule_level', 24);
            $table->string('rule_type', 24);
            $table->string('rule_kind', 24);
            $table->unsignedInteger('mileage_interval_km')->nullable();
            $table->unsignedInteger('time_interval_days')->nullable();
            $table->json('applicability');
            $table->json('localized_content');
            $table->string('criticality', 24);
            $table->unsignedInteger('version')->default(1);
            $table->timestampsTz();

            $table->foreign('ruleset_version_id')->references('id')->on('ruleset_versions')->cascadeOnDelete();
            $table->foreign('source_id')->references('id')->on('maintenance_sources')->restrictOnDelete();
            $table->foreign('work_catalog_item_id')->references('id')->on('work_catalog_items')->restrictOnDelete();
            $table->unique(['ruleset_version_id', 'work_code']);
        });

        Schema::create('maintenance_plan_snapshots', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('vehicle_id');
            $table->uuid('ruleset_version_id');
            $table->string('algorithm_version', 40);
            $table->string('config_version', 80);
            $table->json('input_snapshot');
            $table->string('input_hash', 71);
            $table->string('content_hash', 71);
            $table->json('warnings');
            $table->timestampTz('calculated_at');
            $table->timestampsTz();

            $table->foreign('vehicle_id')->references('id')->on('vehicles')->cascadeOnDelete();
            $table->foreign('ruleset_version_id')->references('id')->on('ruleset_versions')->restrictOnDelete();
            $table->unique(
                ['vehicle_id', 'ruleset_version_id', 'algorithm_version', 'input_hash'],
                'maintenance_snapshot_reuse_unique',
            );
        });

        Schema::create('plan_items', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('snapshot_id');
            $table->uuid('rule_id');
            $table->string('status', 24);
            $table->string('urgency', 24);
            $table->unsignedBigInteger('due_mileage_km')->nullable();
            $table->date('due_date')->nullable();
            $table->json('interval_metadata');
            $table->json('warnings');
            $table->json('explanation');
            $table->timestampsTz();

            $table->foreign('snapshot_id')->references('id')->on('maintenance_plan_snapshots')->cascadeOnDelete();
            $table->foreign('rule_id')->references('id')->on('maintenance_rules')->restrictOnDelete();
            $table->unique(['snapshot_id', 'rule_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('plan_items');
        Schema::dropIfExists('maintenance_plan_snapshots');
        Schema::dropIfExists('maintenance_rules');
        Schema::dropIfExists('work_catalog_items');
        Schema::dropIfExists('ruleset_versions');
        Schema::dropIfExists('maintenance_sources');
    }
};
