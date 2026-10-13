<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ubicacion extends Model
{
    protected $table = 'ubicacion';

    protected $primaryKey = 'id_ubicacion';

    public $timestamps = false;

    protected $fillable = ['area', 'archivador', 'estante', 'seccion', 'caja', 'descripcion', 'estado'];

    protected function casts(): array
    {
        return [
            'estado' => 'boolean',
        ];
    }
}
