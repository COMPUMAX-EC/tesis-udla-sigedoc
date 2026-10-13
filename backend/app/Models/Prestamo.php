<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Prestamo extends Model
{
    protected $table = 'prestamo';

    protected $primaryKey = 'id_prestamo';

    public $timestamps = false;

    protected $fillable = ['id_documento', 'id_solicitud', 'entregado_por', 'recibido_por', 'fecha_entrega', 'fecha_devolucion_prevista', 'fecha_devolucion_real', 'observacion', 'estado'];

    protected function casts(): array
    {
        return [
            'fecha_entrega' => 'datetime',
            'fecha_devolucion_prevista' => 'datetime',
            'fecha_devolucion_real' => 'datetime',
        ];
    }
}
