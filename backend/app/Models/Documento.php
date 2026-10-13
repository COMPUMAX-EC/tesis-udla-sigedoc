<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Documento extends Model
{
    protected $table = 'documento';

    protected $primaryKey = 'id_documento';

    public $timestamps = false;

    protected $fillable = ['id_categoria', 'id_tipo_documental', 'id_ubicacion', 'creado_por', 'codigo_documental', 'titulo', 'descripcion', 'fecha_documento', 'nivel_acceso', 'estado', 'fecha_registro', 'fecha_actualizacion'];

    protected function casts(): array
    {
        return [
            'fecha_documento' => 'date',
            'fecha_registro' => 'datetime',
            'fecha_actualizacion' => 'datetime',
        ];
    }
}
