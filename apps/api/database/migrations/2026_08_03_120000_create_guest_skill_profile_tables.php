<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('guest_skill_profiles', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('guest_profile_id')
                ->unique()
                ->constrained('guest_profiles')
                ->cascadeOnDelete();
            $table->unsignedTinyInteger('overall_score')->default(50);
            $table->string('self_reported_band', 32)->nullable();
            $table->boolean('hands_on')->nullable();
            $table->unsignedInteger('samples_count')->default(0);
            $table->timestamp('last_assessed_at')->nullable();
            $table->timestamps();
        });

        Schema::create('guest_skill_observations', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('guest_skill_profile_id')
                ->constrained('guest_skill_profiles')
                ->cascadeOnDelete();
            $table->smallInteger('delta');
            $table->string('source', 32);
            $table->string('raw_signal', 255)->nullable();
            $table->unsignedTinyInteger('score_before');
            $table->unsignedTinyInteger('score_after');
            $table->timestamps();

            $table->index(['guest_skill_profile_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('guest_skill_observations');
        Schema::dropIfExists('guest_skill_profiles');
    }
};
