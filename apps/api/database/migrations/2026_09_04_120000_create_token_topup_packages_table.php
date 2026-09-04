<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('token_topup_packages', function (Blueprint $table) {
            $table->id();
            $table->string('key', 64)->unique();
            $table->string('type', 32); // stars|mileage|invite
            $table->string('title');
            $table->string('subtitle')->nullable();
            $table->string('icon', 16)->nullable();
            $table->unsignedInteger('tokens_amount')->nullable();
            $table->unsignedInteger('stars_price')->nullable();
            $table->unsignedInteger('cooldown_hours')->nullable();
            $table->string('badge', 64)->nullable();
            $table->boolean('enabled')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(100);
            $table->timestamps();

            $table->index(['enabled', 'sort_order']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('token_topup_packages');
    }
};
