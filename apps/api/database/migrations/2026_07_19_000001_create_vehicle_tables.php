<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicle_configurations', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('make', 100);
            $table->string('model', 100);
            $table->string('generation', 100)->nullable();
            $table->unsignedInteger('engine_displacement_cc')->nullable();
            $table->string('engine_code', 100)->nullable();
            $table->decimal('engine_power_kw', 8, 2)->nullable();
            $table->string('fuel_type', 16);
            $table->string('transmission_type', 16);
            $table->unsignedTinyInteger('transmission_gears')->nullable();
            $table->string('drivetrain', 16)->nullable();
            $table->string('market', 100)->nullable();
            $table->json('field_provenance');
            $table->string('source', 24)->default('user');
            $table->timestampTz('confirmed_at');
            $table->timestampsTz();
        });

        Schema::create('vehicles', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('anonymous_session_id')->nullable();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->uuid('configuration_id')->unique();
            $table->text('vin_ciphertext');
            $table->char('vin_hash', 64)->unique();
            $table->char('vin_last4', 4);
            $table->unsignedSmallInteger('production_year');
            $table->date('first_use_date')->nullable();
            $table->unsignedBigInteger('current_mileage');
            $table->string('mileage_unit', 2);
            $table->string('profile_status', 24)->default('pending_review');
            $table->string('plan_eligibility', 32)->default('universal_type_only');
            $table->unsignedInteger('version')->default(1);
            $table->timestampsTz();

            $table->foreign('anonymous_session_id')
                ->references('id')->on('anonymous_sessions')->cascadeOnDelete();
            $table->foreign('configuration_id')
                ->references('id')->on('vehicle_configurations')->cascadeOnDelete();
            $table->index(['anonymous_session_id', 'created_at']);
        });

        Schema::create('mileage_observations', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('vehicle_id');
            $table->unsignedBigInteger('value');
            $table->string('unit', 2);
            $table->string('source', 16)->default('manual');
            $table->timestampTz('observed_at');
            $table->timestampsTz();

            $table->foreign('vehicle_id')->references('id')->on('vehicles')->cascadeOnDelete();
            $table->index(['vehicle_id', 'observed_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mileage_observations');
        Schema::dropIfExists('vehicles');
        Schema::dropIfExists('vehicle_configurations');
    }
};
