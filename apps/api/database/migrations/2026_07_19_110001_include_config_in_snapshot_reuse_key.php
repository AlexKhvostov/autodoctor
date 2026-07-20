<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('maintenance_plan_snapshots', function (Blueprint $table): void {
            $table->dropUnique('maintenance_snapshot_reuse_unique');
            $table->unique(
                ['vehicle_id', 'ruleset_version_id', 'algorithm_version', 'config_version', 'input_hash'],
                'maintenance_snapshot_reuse_unique',
            );
        });
    }

    public function down(): void
    {
        Schema::table('maintenance_plan_snapshots', function (Blueprint $table): void {
            $table->dropUnique('maintenance_snapshot_reuse_unique');
            $table->unique(
                ['vehicle_id', 'ruleset_version_id', 'algorithm_version', 'input_hash'],
                'maintenance_snapshot_reuse_unique',
            );
        });
    }
};
