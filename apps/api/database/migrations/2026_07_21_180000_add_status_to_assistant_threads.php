<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('assistant_threads', function (Blueprint $table) {
            $table->string('status', 16)->default('active')->after('title');
            $table->string('title_source', 16)->default('auto')->after('status');
            $table->timestampTz('resolved_at')->nullable()->after('title_source');
            $table->timestampTz('archived_at')->nullable()->after('resolved_at');

            $table->index(['vehicle_id', 'status', 'last_message_at']);
        });
    }

    public function down(): void
    {
        Schema::table('assistant_threads', function (Blueprint $table) {
            $table->dropIndex(['vehicle_id', 'status', 'last_message_at']);
            $table->dropColumn(['status', 'title_source', 'resolved_at', 'archived_at']);
        });
    }
};
