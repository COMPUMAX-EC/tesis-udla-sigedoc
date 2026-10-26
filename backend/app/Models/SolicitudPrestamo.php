<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class SolicitudPrestamo extends Model
{
    public const PENDIENTE = 'pendiente';

    public const APROBADA = 'aprobada';

    public const RECHAZADA = 'rechazada';

    protected $table = 'solicitud_prestamo';

    protected $primaryKey = 'id_solicitud';

    public $timestamps = false;

    protected $fillable = ['id_documento', 'id_solicitante', 'fecha_solicitud', 'motivo', 'estado', 'observacion'];

    protected function casts(): array
    {
        return [
            'fecha_solicitud' => 'datetime',
        ];
    }

    public function documento(): BelongsTo
    {
        return $this->belongsTo(Documento::class, 'id_documento');
    }

    public function solicitante(): BelongsTo
    {
        return $this->belongsTo(Usuario::class, 'id_solicitante');
    }

    public function prestamo(): HasOne
    {
        return $this->hasOne(Prestamo::class, 'id_solicitud');
    }
}
