<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('vehicle_configurations', function (Blueprint $table): void {
            $table->string('transmission_type', 16)->nullable()->change();
            $table->unsignedTinyInteger('transmission_gears')->nullable()->change();
        });

        Schema::table('vehicles', function (Blueprint $table): void {
            $table->text('vin_ciphertext')->nullable()->change();
            $table->char('vin_hash', 64)->nullable()->change();
            $table->char('vin_last4', 4)->nullable()->change();
            $table->unsignedBigInteger('current_mileage')->nullable()->change();
            $table->string('mileage_unit', 2)->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('vehicle_configurations', function (Blueprint $table): void {
            $table->string('transmission_type', 16)->nullable(false)->change();
        });

        Schema::table('vehicles', function (Blueprint $table): void {
            $table->text('vin_ciphertext')->nullable(false)->change();
            $table->char('vin_hash', 64)->nullable(false)->change();
            $table->char('vin_last4', 4)->nullable(false)->change();
            $table->unsignedBigInteger('current_mileage')->nullable(false)->change();
            $table->string('mileage_unit', 2)->nullable(false)->change();
        });
    }
};
