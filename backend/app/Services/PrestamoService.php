<?php

namespace App\Services;

use App\Models\Documento;
use App\Models\Prestamo;
use App\Models\SolicitudPrestamo;
use App\Models\Usuario;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Módulo M04. Concentra las reglas de negocio del ciclo de préstamo:
 * RN-03 (solo se presta un documento Disponible), RN-04 (un único préstamo activo por documento),
 * RN-05 (el estado cambia automáticamente) y RF-05.1 (cada operación deja movimiento).
 */
class PrestamoService
{
    /** RF-04.1 Solicitar préstamo. */
    public function solicitar(Documento $documento, Usuario $solicitante, ?string $motivo): SolicitudPrestamo
    {
        return DB::transaction(function () use ($documento, $solicitante, $motivo) {
            $documento = Documento::lockForUpdate()->findOrFail($documento->id_documento);

            if ($documento->estado !== Documento::DISPONIBLE) { // RN-03
                $this->rechazar('id_documento', 'El documento no está disponible: su estado es "'.$this->etiquetaEstado($documento->estado).'".');
            }
            $yaSolicitado = SolicitudPrestamo::where('id_documento', $documento->id_documento)
                ->where('id_solicitante', $solicitante->id_usuario)
                ->where('estado', SolicitudPrestamo::PENDIENTE)->exists();
            if ($yaSolicitado) {
                $this->rechazar('id_documento', 'Ya tiene una solicitud pendiente para este documento.');
            }

            $solicitud = SolicitudPrestamo::create([
                'id_documento' => $documento->id_documento,
                'id_solicitante' => $solicitante->id_usuario,
                'fecha_solicitud' => now(),
                'motivo' => $motivo,
                'estado' => SolicitudPrestamo::PENDIENTE,
            ]);
            Trazabilidad::registrar($documento, $solicitante, Trazabilidad::SOLICITUD, 'Solicitud de préstamo'.($motivo ? ": $motivo" : ''));

            return $solicitud;
        });
    }

    /** RF-04.2 Autorizar o rechazar una solicitud. */
    public function resolver(SolicitudPrestamo $solicitud, Usuario $responsable, bool $aprobar, ?string $observacion): SolicitudPrestamo
    {
        return DB::transaction(function () use ($solicitud, $responsable, $aprobar, $observacion) {
            $solicitud = SolicitudPrestamo::lockForUpdate()->findOrFail($solicitud->id_solicitud);
            if ($solicitud->estado !== SolicitudPrestamo::PENDIENTE) {
                $this->rechazar('estado', 'La solicitud ya fue resuelta.');
            }
            $documento = Documento::findOrFail($solicitud->id_documento);
            if ($aprobar && $documento->estado !== Documento::DISPONIBLE) { // RN-03
                $this->rechazar('id_documento', 'No se puede aprobar: el documento ya no está disponible.');
            }

            $solicitud->update([
                'estado' => $aprobar ? SolicitudPrestamo::APROBADA : SolicitudPrestamo::RECHAZADA,
                'observacion' => $observacion,
            ]);
            Trazabilidad::registrar(
                $documento,
                $responsable,
                $aprobar ? Trazabilidad::SOLICITUD_APROBADA : Trazabilidad::SOLICITUD_RECHAZADA,
                ($aprobar ? 'Solicitud aprobada' : 'Solicitud rechazada').($observacion ? ": $observacion" : ''),
            );

            return $solicitud;
        });
    }

    /** RF-04.3 Registrar préstamo (entrega). Puede originarse en una solicitud aprobada o ser directo. */
    public function entregar(
        Documento $documento,
        Usuario $responsable,
        Usuario $receptor,
        Carbon $devolucionPrevista,
        ?string $observacion,
        ?SolicitudPrestamo $solicitud = null,
    ): Prestamo {
        try {
            return DB::transaction(function () use ($documento, $responsable, $receptor, $devolucionPrevista, $observacion, $solicitud) {
                $documento = Documento::lockForUpdate()->findOrFail($documento->id_documento);

                if ($documento->estado !== Documento::DISPONIBLE) { // RN-03
                    $this->rechazar('id_documento', 'El documento no está disponible: su estado es "'.$this->etiquetaEstado($documento->estado).'".');
                }
                if (Prestamo::where('id_documento', $documento->id_documento)->where('estado', Prestamo::ACTIVO)->exists()) { // RN-04
                    $this->rechazar('id_documento', 'El documento ya tiene un préstamo activo.');
                }
                if (! $receptor->estado) {
                    $this->rechazar('id_receptor', 'El usuario receptor está desactivado.');
                }
                if ($solicitud) {
                    if ($solicitud->id_documento !== $documento->id_documento || $solicitud->estado !== SolicitudPrestamo::APROBADA) {
                        $this->rechazar('id_solicitud', 'La solicitud no está aprobada para este documento.');
                    }
                    if ($solicitud->prestamo()->exists()) {
                        $this->rechazar('id_solicitud', 'La solicitud ya generó un préstamo.');
                    }
                }

                $anterior = $documento->estado;
                $prestamo = Prestamo::create([
                    'id_documento' => $documento->id_documento,
                    'id_solicitud' => $solicitud?->id_solicitud,
                    'entregado_por' => $responsable->id_usuario,
                    'recibido_por' => $receptor->id_usuario,
                    'fecha_entrega' => now(),
                    'fecha_devolucion_prevista' => $devolucionPrevista,
                    'observacion' => $observacion,
                    'estado' => Prestamo::ACTIVO,
                ]);
                $documento->update(['estado' => Documento::PRESTADO, 'fecha_actualizacion' => now()]); // RN-05
                Trazabilidad::registrar(
                    $documento,
                    $responsable,
                    Trazabilidad::PRESTAMO,
                    "Entregado a {$receptor->nombres} {$receptor->apellidos}; devolución prevista {$devolucionPrevista->format('d/m/Y')}",
                    $anterior,
                    Documento::PRESTADO,
                    $prestamo->id_prestamo,
                );

                return $prestamo;
            });
        } catch (UniqueConstraintViolationException) {
            // Respaldo de RN-04 en la base de datos ante una carrera entre dos entregas simultáneas.
            $this->rechazar('id_documento', 'El documento ya tiene un préstamo activo.');
        }
    }

    /** RF-04.4 Registrar devolución · RF-04.5 observación de devolución · RF-04.6 estado. */
    public function devolver(Prestamo $prestamo, Usuario $responsable, ?string $observacion): Prestamo
    {
        return DB::transaction(function () use ($prestamo, $responsable, $observacion) {
            $prestamo = Prestamo::lockForUpdate()->findOrFail($prestamo->id_prestamo);
            if ($prestamo->estado !== Prestamo::ACTIVO) {
                $this->rechazar('estado', 'El préstamo ya fue devuelto.');
            }
            $documento = Documento::lockForUpdate()->findOrFail($prestamo->id_documento);

            $prestamo->update([
                'estado' => Prestamo::DEVUELTO,
                'fecha_devolucion_real' => now(),
                'observacion' => $observacion ?: $prestamo->observacion,
            ]);
            $anterior = $documento->estado;
            $documento->update(['estado' => Documento::DISPONIBLE, 'fecha_actualizacion' => now()]); // RN-05
            Trazabilidad::registrar(
                $documento,
                $responsable,
                Trazabilidad::DEVOLUCION,
                'Documento devuelto'.($observacion ? ": $observacion" : ''),
                $anterior,
                Documento::DISPONIBLE,
                $prestamo->id_prestamo,
            );

            return $prestamo;
        });
    }

    private function etiquetaEstado(string $estado): string
    {
        return ['disponible' => 'Disponible', 'prestado' => 'Prestado', 'de_baja' => 'De baja'][$estado] ?? $estado;
    }

    private function rechazar(string $campo, string $mensaje): never
    {
        throw ValidationException::withMessages([$campo => $mensaje]);
    }
}
