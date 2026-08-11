<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('guest_skill_profiles', function (Blueprint $table): void {
            $table->string('hands_on_level', 32)->nullable()->after('hands_on');
        });
    }

    public function down(): void
    {
        Schema::table('guest_skill_profiles', function (Blueprint $table): void {
            $table->dropColumn('hands_on_level');
        });
    }
};
