<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Prestamo extends Model
{
    public const ACTIVO = 'activo';

    public const DEVUELTO = 'devuelto';

    protected $table = 'prestamo';

    protected $primaryKey = 'id_prestamo';

    public $timestamps = false;

    protected $fillable = ['id_documento', 'id_solicitud', 'entregado_por', 'recibido_por', 'fecha_entrega', 'fecha_devolucion_prevista', 'fecha_devolucion_real', 'observacion', 'estado'];

    protected $appends = ['en_mora'];

    protected function casts(): array
    {
        return [
            'fecha_entrega' => 'datetime',
            'fecha_devolucion_prevista' => 'datetime',
            'fecha_devolucion_real' => 'datetime',
        ];
    }

    /** Préstamo activo cuya fecha prevista de devolución ya pasó. */
    public function getEnMoraAttribute(): bool
    {
        return $this->estado === self::ACTIVO && $this->fecha_devolucion_prevista?->isPast() === true;
    }

    public function documento(): BelongsTo
    {
        return $this->belongsTo(Documento::class, 'id_documento');
    }

    public function solicitud(): BelongsTo
    {
        return $this->belongsTo(SolicitudPrestamo::class, 'id_solicitud');
    }

    public function entregadoPor(): BelongsTo
    {
        return $this->belongsTo(Usuario::class, 'entregado_por');
    }

    public function recibidoPor(): BelongsTo
    {
        return $this->belongsTo(Usuario::class, 'recibido_por');
    }
}
