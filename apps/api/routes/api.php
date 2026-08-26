<?php

use App\Http\Controllers\AssistantController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ConditionObservationController;
use App\Http\Controllers\AgentProfileController;
use App\Http\Controllers\ConsentController;
use App\Http\Controllers\GuestProfileAiNoteController;
use App\Http\Controllers\GuestSkillProfileController;
use App\Http\Controllers\HistoryAnswerController;
use App\Http\Controllers\MaintenanceController;
use App\Http\Controllers\MileageForecastController;
use App\Http\Controllers\MileageObservationController;
use App\Http\Controllers\ServiceRecordController;
use App\Http\Controllers\SessionController;
use App\Http\Controllers\SystemController;
use App\Http\Controllers\VehicleAiNoteController;
use App\Http\Controllers\VehicleController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', [SystemController::class, 'health']);
    Route::get('/capabilities', [SystemController::class, 'capabilities']);
    Route::post('/diagnostics/ai', [SystemController::class, 'probeAi'])
        ->middleware('session.auth');

    Route::post('/sessions/anonymous', [SessionController::class, 'store']);
    Route::get('/consents/current', [ConsentController::class, 'current']);
    Route::post('/auth/google', [AuthController::class, 'google']);

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);
    });

    Route::middleware('session.auth')->group(function (): void {
        Route::get('/sessions/current', [SessionController::class, 'show']);
        Route::delete('/sessions/current', [SessionController::class, 'destroy']);
        Route::get('/guest/skill-profile', [GuestSkillProfileController::class, 'show']);
        Route::patch('/guest/skill-profile', [GuestSkillProfileController::class, 'update']);
        Route::get('/guest/agent-profile', [AgentProfileController::class, 'show']);
        Route::patch('/guest/agent-profile/preferences', [AgentProfileController::class, 'updatePreferences']);
        Route::patch('/guest/agent-profile/skill', [AgentProfileController::class, 'updateSkill']);
        Route::post('/guest/agent-profile/refuel-stub', [AgentProfileController::class, 'refuelStub']);
        Route::get('/guest/ai-notes', [GuestProfileAiNoteController::class, 'index']);
        Route::delete('/guest/ai-notes/{note}', [GuestProfileAiNoteController::class, 'destroy']);
        Route::post('/consents', [ConsentController::class, 'store']);
        Route::get('/vehicles', [VehicleController::class, 'index']);
        Route::post('/vehicles', [VehicleController::class, 'store']);
        Route::get('/vehicles/{vehicle}', [VehicleController::class, 'show']);
        Route::patch('/vehicles/{vehicle}', [VehicleController::class, 'update']);
        Route::delete('/vehicles/{vehicle}', [VehicleController::class, 'destroy']);
        Route::put('/vehicles/{vehicle}/mileage', [VehicleController::class, 'updateMileage']);
        Route::get('/vehicles/{vehicle}/mileage-observations', [MileageObservationController::class, 'index']);
        Route::get('/vehicles/{vehicle}/mileage-forecast', [MileageForecastController::class, 'show']);
        Route::get('/vehicles/{vehicle}/condition-observations', [ConditionObservationController::class, 'index']);
        Route::post('/vehicles/{vehicle}/condition-observations', [ConditionObservationController::class, 'store']);
        Route::patch('/vehicles/{vehicle}/condition-observations/{observation}', [ConditionObservationController::class, 'update']);
        Route::delete('/vehicles/{vehicle}/condition-observations/{observation}', [ConditionObservationController::class, 'destroy']);
        Route::get('/vehicles/{vehicle}/history', [ServiceRecordController::class, 'index']);
        Route::post('/vehicles/{vehicle}/history', [ServiceRecordController::class, 'store']);
        Route::patch('/vehicles/{vehicle}/history/{record}', [ServiceRecordController::class, 'update']);
        Route::delete('/vehicles/{vehicle}/history/{record}', [ServiceRecordController::class, 'destroy']);
        Route::get('/vehicles/{vehicle}/maintenance-plan', [MaintenanceController::class, 'show']);
        Route::get('/vehicles/{vehicle}/timeline', [MaintenanceController::class, 'timeline']);
        Route::get('/vehicles/{vehicle}/consumables', [MaintenanceController::class, 'consumables']);
        Route::post('/vehicles/{vehicle}/history-answers', [HistoryAnswerController::class, 'store']);
        Route::get('/vehicles/{vehicle}/ai-notes', [VehicleAiNoteController::class, 'index']);
        Route::delete('/vehicles/{vehicle}/ai-notes/{note}', [VehicleAiNoteController::class, 'destroy']);
        Route::post('/assistant/messages', [AssistantController::class, 'storeProfileMessage']);
        Route::get('/assistant/threads', [AssistantController::class, 'indexAll']);
        Route::get('/assistant/threads/{thread}', [AssistantController::class, 'showOwned']);
        Route::patch('/assistant/threads/{thread}', [AssistantController::class, 'updateOwned']);
        Route::delete('/assistant/threads/{thread}', [AssistantController::class, 'destroyOwned']);
        Route::post('/vehicles/{vehicle}/assistant/messages', [AssistantController::class, 'storeMessage']);
        Route::get('/vehicles/{vehicle}/assistant/threads', [AssistantController::class, 'index']);
        Route::get('/vehicles/{vehicle}/assistant/threads/{thread}', [AssistantController::class, 'show']);
        Route::patch('/vehicles/{vehicle}/assistant/threads/{thread}', [AssistantController::class, 'update']);
        Route::delete('/vehicles/{vehicle}/assistant/threads/{thread}', [AssistantController::class, 'destroy']);
    });
});
