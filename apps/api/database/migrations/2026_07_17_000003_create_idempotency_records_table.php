<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('idempotency_records', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('scope', 128);
            $table->string('operation', 128);
            $table->uuid('idempotency_key');
            $table->char('request_hash', 64);
            $table->unsignedSmallInteger('status_code');
            $table->text('response_body')->nullable();
            $table->timestampsTz();
            $table->unique(
                ['scope', 'operation', 'idempotency_key'],
                'idempotency_scope_operation_key_unique',
            );
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('idempotency_records');
    }
};
