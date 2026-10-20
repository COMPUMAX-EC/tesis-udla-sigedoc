<?php

use App\Http\Controllers\Api\ArchivoDigitalController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoriaController;
use App\Http\Controllers\Api\DepartamentoController;
use App\Http\Controllers\Api\DocumentoController;
use App\Http\Controllers\Api\PanelController;
use App\Http\Controllers\Api\PrestamoController;
use App\Http\Controllers\Api\QrController;
use App\Http\Controllers\Api\ReporteController;
use App\Http\Controllers\Api\RolController;
use App\Http\Controllers\Api\SolicitudController;
use App\Http\Controllers\Api\TipoDocumentalController;
use App\Http\Controllers\Api\UbicacionController;
use App\Http\Controllers\Api\UsuarioController;
use App\Models\Usuario;
use Illuminate\Support\Facades\Route;

$admin = Usuario::ROL_ADMINISTRADOR;
$responsable = Usuario::ROL_RESPONSABLE;
$funcionario = Usuario::ROL_FUNCIONARIO;

// M01 · Gestión de usuarios
Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

// Información pública del entorno (la interfaz muestra el aviso de datos de demostración).
Route::get('entorno', fn () => response()->json(['demo' => (bool) config('app.demo'), 'nombre' => 'SIGEDOC', 'organizacion' => 'VIALZACHIN E.P.']));

// Enlaces temporales firmados (se abren en el navegador, sin cabecera Authorization).
Route::middleware('signed')->group(function () {
    Route::get('etiquetas/{documento}', [QrController::class, 'etiqueta'])->name('etiquetas.ver');
    Route::get('archivos/{archivo}/contenido', [ArchivoDigitalController::class, 'contenido'])->name('archivos.contenido');
    Route::get('reportes/{tipo}/csv', [ReporteController::class, 'csv'])->name('reportes.csv');
});

Route::middleware('auth:sanctum')->group(function () use ($admin, $responsable, $funcionario) {
    Route::get('auth/me', [AuthController::class, 'me']);
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::get('panel/resumen', [PanelController::class, 'resumen']);

    // Catálogos: lectura para todo usuario autenticado.
    Route::get('departamentos', [DepartamentoController::class, 'index']);
    Route::get('departamentos/{registro}', [DepartamentoController::class, 'show']);
    Route::get('tipos-documentales', [TipoDocumentalController::class, 'index']);
    Route::get('tipos-documentales/{registro}', [TipoDocumentalController::class, 'show']);
    Route::get('categorias', [CategoriaController::class, 'index']);
    Route::get('ubicaciones', [UbicacionController::class, 'index']);

    // M01 · solo Administrador
    Route::middleware("rol:$admin")->group(function () {
        Route::apiResource('usuarios', UsuarioController::class);
        Route::apiResource('roles', RolController::class)->parameters(['roles' => 'registro']);
        Route::apiResource('departamentos', DepartamentoController::class)
            ->except(['index', 'show'])->parameters(['departamentos' => 'registro']);
        Route::apiResource('tipos-documentales', TipoDocumentalController::class)
            ->except(['index', 'show'])->parameters(['tipos-documentales' => 'registro']);
    });

    // Categorías y ubicaciones físicas: las gestionan Administrador y Responsable del archivo.
    Route::middleware("rol:$admin,$responsable")->group(function () {
        Route::apiResource('categorias', CategoriaController::class)->except(['index'])->parameters(['categorias' => 'registro']);
        Route::apiResource('ubicaciones', UbicacionController::class)->except(['index'])->parameters(['ubicaciones' => 'registro']);

        // M06 · Reportes
        Route::get('reportes/{tipo}', [ReporteController::class, 'ver']);
        Route::post('reportes/{tipo}/enlace-csv', [ReporteController::class, 'enlaceCsv']);
    });

    // M02 · M03 · M04 · M05: consulta (Responsable y Funcionario)
    Route::middleware("rol:$responsable,$funcionario")->group(function () {
        Route::get('documentos', [DocumentoController::class, 'index']);
        Route::get('documentos/{documento}', [DocumentoController::class, 'show']);
        Route::get('documentos/{documento}/ubicacion', [DocumentoController::class, 'ubicacion']); // RF-05.3
        Route::get('documentos/{documento}/archivos', [ArchivoDigitalController::class, 'index']);
        Route::get('archivos/{archivo}/enlace', [ArchivoDigitalController::class, 'enlace']);
        Route::post('qr/resolver', [QrController::class, 'resolver']); // RF-03.4

        Route::get('solicitudes', [SolicitudController::class, 'index']);
        Route::get('prestamos', [PrestamoController::class, 'index']);
        Route::get('prestamos/{prestamo}', [PrestamoController::class, 'show']);
    });

    // Funcionario: solicitar préstamo (RF-04.1)
    Route::post('solicitudes', [SolicitudController::class, 'store'])->middleware("rol:$funcionario");

    // Responsable del archivo: registro, QR, préstamos y trazabilidad
    Route::middleware("rol:$responsable")->group(function () {
        Route::get('directorio-usuarios', [UsuarioController::class, 'directorio']); // receptores de préstamo
        Route::post('documentos', [DocumentoController::class, 'store']);
        Route::put('documentos/{documento}', [DocumentoController::class, 'update']);
        Route::delete('documentos/{documento}', [DocumentoController::class, 'destroy']);
        Route::post('documentos/{documento}/reactivar', [DocumentoController::class, 'reactivar']);
        Route::get('documentos/{documento}/historial', [DocumentoController::class, 'historial']); // RF-05.2
        Route::get('documentos/{documento}/prestamos', [DocumentoController::class, 'prestamos']); // RF-05.2

        Route::get('documentos/{documento}/qr', [QrController::class, 'mostrar']);
        Route::post('documentos/{documento}/qr/etiqueta', [QrController::class, 'enlaceEtiqueta']); // RF-03.3

        Route::post('documentos/{documento}/archivos', [ArchivoDigitalController::class, 'store']);
        Route::delete('archivos/{archivo}', [ArchivoDigitalController::class, 'destroy']);

        Route::post('solicitudes/{solicitud}/resolver', [SolicitudController::class, 'resolver']); // RF-04.2
        Route::post('prestamos', [PrestamoController::class, 'store']); // RF-04.3
        Route::post('prestamos/{prestamo}/devolver', [PrestamoController::class, 'devolver']); // RF-04.4/04.5
    });
});
