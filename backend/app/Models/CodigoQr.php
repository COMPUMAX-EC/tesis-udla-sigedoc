<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CodigoQr extends Model
{
    protected $table = 'codigo_qr';

    protected $primaryKey = 'id_qr';

    public $timestamps = false;

    protected $fillable = ['id_documento', 'identificador', 'contenido', 'ruta_imagen', 'fecha_generacion', 'estado'];

    protected function casts(): array
    {
        return [
            'estado' => 'boolean',
            'fecha_generacion' => 'datetime',
        ];
    }
}
