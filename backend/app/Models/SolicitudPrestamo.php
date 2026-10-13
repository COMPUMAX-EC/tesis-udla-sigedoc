<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SolicitudPrestamo extends Model
{
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
}
