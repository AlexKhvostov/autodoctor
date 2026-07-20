<?php

use App\Http\Controllers\ConditionObservationController;
use App\Http\Controllers\ConsentController;
use App\Http\Controllers\HistoryAnswerController;
use App\Http\Controllers\MaintenanceController;
use App\Http\Controllers\MileageForecastController;
use App\Http\Controllers\ServiceRecordController;
use App\Http\Controllers\SessionController;
use App\Http\Controllers\SystemController;
use App\Http\Controllers\VehicleController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('/health', [SystemController::class, 'health']);
    Route::get('/capabilities', [SystemController::class, 'capabilities']);

    Route::post('/sessions/anonymous', [SessionController::class, 'store']);
    Route::get('/consents/current', [ConsentController::class, 'current']);

    Route::middleware('session.auth')->group(function (): void {
        Route::get('/sessions/current', [SessionController::class, 'show']);
        Route::delete('/sessions/current', [SessionController::class, 'destroy']);
        Route::post('/consents', [ConsentController::class, 'store']);
        Route::get('/vehicles', [VehicleController::class, 'index']);
        Route::post('/vehicles', [VehicleController::class, 'store']);
        Route::get('/vehicles/{vehicle}', [VehicleController::class, 'show']);
        Route::patch('/vehicles/{vehicle}', [VehicleController::class, 'update']);
        Route::delete('/vehicles/{vehicle}', [VehicleController::class, 'destroy']);
        Route::put('/vehicles/{vehicle}/mileage', [VehicleController::class, 'updateMileage']);
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
    });
});
