<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Categoria extends Model
{
    protected $table = 'categoria';

    protected $primaryKey = 'id_categoria';

    public $timestamps = false;

    protected $fillable = ['nombre', 'descripcion', 'estado'];

    protected function casts(): array
    {
        return [
            'estado' => 'boolean',
        ];
    }
}
