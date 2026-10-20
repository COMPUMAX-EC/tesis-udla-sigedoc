<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Bitácora de trazabilidad. Inmutable: un trigger de PostgreSQL impide modificarla o borrarla (RN-06). */
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

    public function documento(): BelongsTo
    {
        return $this->belongsTo(Documento::class, 'id_documento');
    }

    public function usuario(): BelongsTo
    {
        return $this->belongsTo(Usuario::class, 'id_usuario');
    }
}
