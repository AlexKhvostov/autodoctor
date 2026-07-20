<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('consents', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('anonymous_session_id')
                ->constrained('anonymous_sessions')
                ->cascadeOnDelete();
            $table->string('purpose', 64);
            $table->string('document_version', 64);
            $table->boolean('granted');
            $table->timestampTz('decided_at');
            $table->timestampsTz();
            $table->unique(
                ['anonymous_session_id', 'purpose', 'document_version'],
                'consents_session_purpose_version_unique',
            );
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('consents');
    }
};
