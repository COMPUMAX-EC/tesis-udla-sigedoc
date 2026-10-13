<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ArchivoDigital extends Model
{
    protected $table = 'archivo_digital';

    protected $primaryKey = 'id_archivo';

    public $timestamps = false;

    protected $fillable = ['id_documento', 'nombre_archivo', 'ruta_archivo', 'tipo_mime', 'tamano_bytes', 'subido_por', 'fecha_carga'];

    protected function casts(): array
    {
        return [
            'fecha_carga' => 'datetime',
        ];
    }
}
