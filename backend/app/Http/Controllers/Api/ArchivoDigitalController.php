<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ArchivoDigital;
use App\Models\Documento;
use App\Services\Trazabilidad;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Symfony\Component\HttpFoundation\StreamedResponse;

/** Copia digital (escaneo) asociada a un documento físico. */
class ArchivoDigitalController extends Controller
{
    public function index(Request $request, Documento $documento): JsonResponse
    {
        abort_unless($documento->esVisiblePara($request->user()), 403, 'No tiene acceso a este documento.');

        return response()->json($documento->archivos()->with('subidoPor:id_usuario,nombres,apellidos')->orderByDesc('fecha_carga')->get());
    }

    public function store(Request $request, Documento $documento): JsonResponse
    {
        $request->validate(['archivo' => ['required', 'file', 'max:20480', 'mimes:pdf,jpg,jpeg,png,webp']]);
        $subido = $request->file('archivo');
        $ruta = $subido->store("documentos/{$documento->id_documento}", 'local');

        $archivo = ArchivoDigital::create([
            'id_documento' => $documento->id_documento,
            'nombre_archivo' => mb_substr($subido->getClientOriginalName(), 0, 200),
            'ruta_archivo' => $ruta,
            'tipo_mime' => $subido->getMimeType(),
            'tamano_bytes' => $subido->getSize(),
            'subido_por' => $request->user()->id_usuario,
            'fecha_carga' => now(),
        ]);
        Trazabilidad::registrar($documento, $request->user(), Trazabilidad::ARCHIVO_ADJUNTO, "Archivo adjunto: {$archivo->nombre_archivo}");

        return response()->json($archivo->load('subidoPor:id_usuario,nombres,apellidos'), 201);
    }

    /** Enlace temporal firmado para descargar sin enviar cabeceras (se abre en el navegador). */
    public function enlace(Request $request, ArchivoDigital $archivo): JsonResponse
    {
        abort_unless($archivo->documento->esVisiblePara($request->user()), 403, 'No tiene acceso a este documento.');

        return response()->json([
            'url' => URL::temporarySignedRoute('archivos.contenido', now()->addMinutes(5), ['archivo' => $archivo->id_archivo]),
        ]);
    }

    public function contenido(ArchivoDigital $archivo): StreamedResponse
    {
        abort_unless(Storage::disk('local')->exists($archivo->ruta_archivo), 404, 'El archivo ya no está disponible.');

        return Storage::disk('local')->response($archivo->ruta_archivo, $archivo->nombre_archivo, [
            'Content-Type' => $archivo->tipo_mime ?: 'application/octet-stream',
        ]);
    }

    public function destroy(Request $request, ArchivoDigital $archivo): JsonResponse
    {
        Storage::disk('local')->delete($archivo->ruta_archivo);
        Trazabilidad::registrar($archivo->id_documento, $request->user(), Trazabilidad::ARCHIVO_ELIMINADO, "Archivo eliminado: {$archivo->nombre_archivo}");
        $archivo->delete();

        return response()->json(['message' => 'Archivo eliminado.']);
    }
}
