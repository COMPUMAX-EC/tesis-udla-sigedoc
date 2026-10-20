<?php

namespace App\Services;

use App\Models\Documento;
use App\Models\Movimiento;
use App\Models\Usuario;

/** RF-05.1 Registrar movimiento: toda operación sobre un documento deja rastro en la bitácora. */
class Trazabilidad
{
    public const REGISTRO = 'registro';

    public const ACTUALIZACION = 'actualizacion';

    public const CAMBIO_UBICACION = 'cambio_ubicacion';

    public const QR_GENERADO = 'qr_generado';

    public const CONSULTA_QR = 'consulta_qr';

    public const ARCHIVO_ADJUNTO = 'archivo_adjunto';

    public const ARCHIVO_ELIMINADO = 'archivo_eliminado';

    public const SOLICITUD = 'solicitud';

    public const SOLICITUD_APROBADA = 'solicitud_aprobada';

    public const SOLICITUD_RECHAZADA = 'solicitud_rechazada';

    public const PRESTAMO = 'prestamo';

    public const DEVOLUCION = 'devolucion';

    public const BAJA = 'baja';

    public const REACTIVACION = 'reactivacion';

    public static function registrar(
        Documento|int $documento,
        ?Usuario $usuario,
        string $tipo,
        ?string $descripcion = null,
        ?string $estadoAnterior = null,
        ?string $estadoNuevo = null,
        ?int $idPrestamo = null,
    ): Movimiento {
        return Movimiento::create([
            'id_documento' => $documento instanceof Documento ? $documento->id_documento : $documento,
            'id_usuario' => $usuario?->id_usuario,
            'id_prestamo' => $idPrestamo,
            'tipo_movimiento' => $tipo,
            'descripcion' => $descripcion === null ? null : mb_substr($descripcion, 0, 250),
            'estado_anterior' => $estadoAnterior,
            'estado_nuevo' => $estadoNuevo,
            'fecha_movimiento' => now(),
            'direccion_ip' => request()?->ip(),
        ]);
    }
}
