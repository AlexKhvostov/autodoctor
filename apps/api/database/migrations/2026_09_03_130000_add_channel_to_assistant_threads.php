<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('assistant_threads', function (Blueprint $table) {
            $table->string('channel', 16)->default('app')->after('status');
            $table->index('channel');
        });
    }

    public function down(): void
    {
        Schema::table('assistant_threads', function (Blueprint $table) {
            $table->dropIndex(['channel']);
            $table->dropColumn('channel');
        });
    }
};
