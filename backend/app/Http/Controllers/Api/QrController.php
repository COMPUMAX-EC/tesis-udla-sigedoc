<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CodigoQr;
use App\Models\Documento;
use App\Services\GestorQr;
use App\Services\Trazabilidad;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\URL;

/** M03 Gestión QR: imagen (RF-03.2), etiqueta imprimible (RF-03.3) y lectura (RF-03.4). */
class QrController extends Controller
{
    /** RF-03.2 Código QR del documento: identificador, contenido codificado e imagen SVG. */
    public function mostrar(Documento $documento): JsonResponse
    {
        $qr = $documento->qr()->firstOrFail();

        return response()->json([
            'identificador' => $qr->identificador,
            'contenido' => $qr->contenido,
            'estado' => $qr->estado,
            'svg' => GestorQr::svg($qr),
        ]);
    }

    /** RF-03.3 Enlace temporal firmado a la etiqueta imprimible (se abre en el navegador sin cabeceras). */
    public function enlaceEtiqueta(Documento $documento): JsonResponse
    {
        $documento->qr()->firstOrFail();

        return response()->json([
            'url' => URL::temporarySignedRoute('etiquetas.ver', now()->addMinutes(10), ['documento' => $documento->id_documento]),
        ]);
    }

    /** Etiqueta HTML lista para imprimir (ruta firmada, sin autenticación por cabecera). */
    public function etiqueta(Documento $documento): Response
    {
        $documento->load('tipoDocumental.departamento', 'ubicacion', 'qr');
        $qr = $documento->qr()->firstOrFail();

        return response()->view('etiqueta', ['documento' => $documento, 'svg' => GestorQr::svg($qr, 260)]);
    }

    /** RF-03.4 Leer QR: resuelve el contenido leído por la cámara (o ingresado a mano) al documento. */
    public function resolver(Request $request): JsonResponse
    {
        $datos = $request->validate(['codigo' => ['required', 'string', 'max:500']]);
        $identificador = GestorQr::extraerIdentificador($datos['codigo']);
        $qr = $identificador ? CodigoQr::where('identificador', $identificador)->first() : null;

        if (! $qr || ! $qr->estado) {
            return response()->json(['message' => 'Código no válido: no corresponde a un documento de SIGEDOC.'], 404);
        }
        $documento = Documento::with(['tipoDocumental.departamento', 'categoria', 'ubicacion'])->findOrFail($qr->id_documento);
        if (! $documento->esVisiblePara($request->user())) {
            return response()->json(['message' => 'No tiene acceso a este documento.'], 403);
        }
        Trazabilidad::registrar($documento, $request->user(), Trazabilidad::CONSULTA_QR, 'Consulta por lectura de código QR');

        return response()->json($documento);
    }
}
