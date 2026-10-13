<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Movimiento extends Model
{
    protected $table = 'movimiento';

    protected $primaryKey = 'id_movimiento';

    public $timestamps = false;

    protected $fillable = ['id_documento', 'id_usuario', 'id_prestamo', 'tipo_movimiento', 'descripcion', 'estado_anterior', 'estado_nuevo', 'fecha_movimiento', 'direccion_ip'];

    protected function casts(): array
    {
        return [
            'fecha_movimiento' => 'datetime',
        ];
    }
}
