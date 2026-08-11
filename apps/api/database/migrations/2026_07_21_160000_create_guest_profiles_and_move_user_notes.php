<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('guest_profiles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->timestampsTz();
        });

        Schema::table('anonymous_sessions', function (Blueprint $table) {
            $table->uuid('guest_profile_id')->nullable()->after('id');
            $table->foreign('guest_profile_id')
                ->references('id')->on('guest_profiles')->nullOnDelete();
            $table->index('guest_profile_id');
        });

        Schema::create('guest_profile_ai_notes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('guest_profile_id');
            $table->string('body', 280);
            $table->string('source', 32)->default('chat');
            $table->timestampsTz();

            $table->foreign('guest_profile_id')
                ->references('id')->on('guest_profiles')->cascadeOnDelete();
            $table->index(['guest_profile_id', 'created_at']);
        });

        // Backfill: one profile per existing session; move session notes onto profiles.
        $sessions = DB::table('anonymous_sessions')->select('id')->get();
        foreach ($sessions as $session) {
            $profileId = (string) Str::uuid();
            $now = now();
            DB::table('guest_profiles')->insert([
                'id' => $profileId,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
            DB::table('anonymous_sessions')
                ->where('id', $session->id)
                ->update(['guest_profile_id' => $profileId]);
        }

        if (Schema::hasTable('session_ai_notes')) {
            $notes = DB::table('session_ai_notes')->get();
            foreach ($notes as $note) {
                $profileId = DB::table('anonymous_sessions')
                    ->where('id', $note->anonymous_session_id)
                    ->value('guest_profile_id');
                if ($profileId === null) {
                    continue;
                }
                DB::table('guest_profile_ai_notes')->insert([
                    'id' => $note->id,
                    'guest_profile_id' => $profileId,
                    'body' => $note->body,
                    'source' => $note->source,
                    'created_at' => $note->created_at,
                    'updated_at' => $note->updated_at,
                ]);
            }
            Schema::dropIfExists('session_ai_notes');
        }
    }

    public function down(): void
    {
        Schema::create('session_ai_notes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('anonymous_session_id');
            $table->string('body', 280);
            $table->string('source', 32)->default('chat');
            $table->timestampsTz();

            $table->foreign('anonymous_session_id')
                ->references('id')->on('anonymous_sessions')->cascadeOnDelete();
            $table->index(['anonymous_session_id', 'created_at']);
        });

        $notes = DB::table('guest_profile_ai_notes')->get();
        foreach ($notes as $note) {
            $sessionId = DB::table('anonymous_sessions')
                ->where('guest_profile_id', $note->guest_profile_id)
                ->orderByDesc('created_at')
                ->value('id');
            if ($sessionId === null) {
                continue;
            }
            DB::table('session_ai_notes')->insert([
                'id' => $note->id,
                'anonymous_session_id' => $sessionId,
                'body' => $note->body,
                'source' => $note->source,
                'created_at' => $note->created_at,
                'updated_at' => $note->updated_at,
            ]);
        }

        Schema::dropIfExists('guest_profile_ai_notes');

        Schema::table('anonymous_sessions', function (Blueprint $table) {
            $table->dropForeign(['guest_profile_id']);
            $table->dropColumn('guest_profile_id');
        });

        Schema::dropIfExists('guest_profiles');
    }
};
