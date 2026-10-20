<?php

namespace App\Services;

use App\Models\CodigoQr;
use App\Models\Documento;
use BaconQrCode\Renderer\Image\SvgImageBackEnd;
use BaconQrCode\Renderer\ImageRenderer;
use BaconQrCode\Renderer\RendererStyle\RendererStyle;
use BaconQrCode\Writer;
use Illuminate\Support\Str;

/**
 * RF-03.1 Generar identificador único · RF-03.2 Generar código QR.
 * RN-02: cada documento tiene un único QR (restricción UNIQUE en codigo_qr.id_documento).
 */
class GestorQr
{
    public const PREFIJO = 'SIGEDOC:';

    public static function generar(Documento $documento): CodigoQr
    {
        $identificador = (string) Str::uuid(); // UUID v4: no predecible, no permite enumerar documentos

        return CodigoQr::create([
            'id_documento' => $documento->id_documento,
            'identificador' => $identificador,
            'contenido' => self::PREFIJO.$identificador,
            'fecha_generacion' => now(),
            'estado' => true,
        ]);
    }

    public static function svg(CodigoQr $qr, int $lado = 320): string
    {
        $renderer = new ImageRenderer(new RendererStyle($lado, 2), new SvgImageBackEnd);

        return (new Writer($renderer))->writeString($qr->contenido);
    }

    /** Extrae el UUID de lo leído por la cámara: "SIGEDOC:uuid", un UUID suelto o una URL que lo contenga. */
    public static function extraerIdentificador(string $leido): ?string
    {
        return preg_match('/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i', $leido, $m)
            ? strtolower($m[0])
            : null;
    }
}
