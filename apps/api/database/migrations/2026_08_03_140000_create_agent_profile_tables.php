<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('agent_preferences', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('guest_profile_id')
                ->unique()
                ->constrained('guest_profiles')
                ->cascadeOnDelete();
            $table->unsignedTinyInteger('simplicity')->default(3);
            $table->unsignedTinyInteger('verbosity')->default(3);
            $table->unsignedTinyInteger('directness')->default(5);
            $table->unsignedTinyInteger('initiative')->default(4);
            $table->string('custom_instructions', 800)->nullable();
            $table->timestamps();
        });

        Schema::create('agent_fuel_wallets', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('guest_profile_id')
                ->unique()
                ->constrained('guest_profiles')
                ->cascadeOnDelete();
            $table->unsignedInteger('balance_ml')->default(0);
            $table->unsignedInteger('capacity_ml')->default(0);
            $table->unsignedInteger('lifetime_consumed_ml')->default(0);
            $table->unsignedInteger('lifetime_prompt_tokens')->default(0);
            $table->unsignedInteger('lifetime_completion_tokens')->default(0);
            $table->decimal('lifetime_estimated_cost', 12, 6)->default(0);
            $table->string('currency', 8)->default('BYN');
            $table->timestamps();
        });

        Schema::create('ai_usage_events', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('guest_profile_id')
                ->constrained('guest_profiles')
                ->cascadeOnDelete();
            $table->foreignUuid('vehicle_id')->nullable()->constrained('vehicles')->nullOnDelete();
            $table->string('source', 32);
            $table->string('provider', 64)->nullable();
            $table->string('model', 128)->nullable();
            $table->unsignedInteger('prompt_tokens')->nullable();
            $table->unsignedInteger('completion_tokens')->nullable();
            $table->unsignedInteger('total_tokens')->nullable();
            $table->unsignedInteger('fuel_ml')->default(0);
            $table->decimal('estimated_cost', 12, 6)->nullable();
            $table->string('currency', 8)->nullable();
            $table->boolean('tokens_estimated')->default(false);
            $table->timestamps();

            $table->index(['guest_profile_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_usage_events');
        Schema::dropIfExists('agent_fuel_wallets');
        Schema::dropIfExists('agent_preferences');
    }
};
