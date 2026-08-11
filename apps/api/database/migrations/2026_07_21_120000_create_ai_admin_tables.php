<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_prompt_versions', function (Blueprint $table) {
            $table->id();
            $table->string('code');
            $table->string('name');
            $table->longText('body');
            $table->string('status', 32)->default('draft'); // draft|approved|archived
            $table->timestamps();

            $table->index(['code', 'status']);
        });

        Schema::create('ai_config_versions', function (Blueprint $table) {
            $table->id();
            $table->string('primary_provider', 64);
            $table->string('primary_model', 128);
            $table->string('fallback_provider', 64)->nullable();
            $table->string('fallback_model', 128)->nullable();
            $table->boolean('enabled')->default(true);
            $table->foreignId('prompt_version_id')->constrained('ai_prompt_versions');
            $table->unsignedInteger('max_tokens')->nullable();
            $table->string('author')->nullable();
            $table->foreignId('previous_version_id')->nullable()->constrained('ai_config_versions')->nullOnDelete();
            $table->boolean('is_active')->default(false);
            $table->timestamps();

            $table->index(['is_active', 'enabled']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_config_versions');
        Schema::dropIfExists('ai_prompt_versions');
    }
};
