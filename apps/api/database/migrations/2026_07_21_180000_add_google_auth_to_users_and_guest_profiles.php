<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('google_id')->nullable()->unique()->after('id');
            $table->boolean('is_admin')->default(false)->after('password');
        });

        DB::table('users')
            ->where('email', 'admin@autodoctor.local')
            ->update(['is_admin' => true]);

        Schema::table('guest_profiles', function (Blueprint $table) {
            $table->foreignId('user_id')
                ->nullable()
                ->after('id')
                ->constrained('users')
                ->nullOnDelete();
            $table->unique('user_id');
        });
    }

    public function down(): void
    {
        Schema::table('guest_profiles', function (Blueprint $table) {
            $table->dropConstrainedForeignId('user_id');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['google_id', 'is_admin']);
        });
    }
};
