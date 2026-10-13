<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DepartamentoController;
use App\Http\Controllers\Api\RolController;
use App\Http\Controllers\Api\TipoDocumentalController;
use App\Http\Controllers\Api\UsuarioController;
use App\Models\Usuario;
use Illuminate\Support\Facades\Route;

// M01 · Gestión de usuarios
Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('auth/me', [AuthController::class, 'me']);
    Route::post('auth/logout', [AuthController::class, 'logout']);

    // Catálogos: lectura para todo usuario autenticado.
    Route::get('departamentos', [DepartamentoController::class, 'index']);
    Route::get('departamentos/{registro}', [DepartamentoController::class, 'show']);
    Route::get('tipos-documentales', [TipoDocumentalController::class, 'index']);
    Route::get('tipos-documentales/{registro}', [TipoDocumentalController::class, 'show']);

    Route::middleware('rol:'.Usuario::ROL_ADMINISTRADOR)->group(function () {
        Route::apiResource('usuarios', UsuarioController::class);
        Route::apiResource('roles', RolController::class)->parameters(['roles' => 'registro']);
        Route::apiResource('departamentos', DepartamentoController::class)
            ->except(['index', 'show'])->parameters(['departamentos' => 'registro']);
        Route::apiResource('tipos-documentales', TipoDocumentalController::class)
            ->except(['index', 'show'])->parameters(['tipos-documentales' => 'registro']);
    });
});
