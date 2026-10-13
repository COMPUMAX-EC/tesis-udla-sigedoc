<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Departamento extends Model
{
    protected $table = 'departamento';

    protected $primaryKey = 'id_departamento';

    public $timestamps = false;

    protected $fillable = ['nombre', 'descripcion', 'estado'];

    protected function casts(): array
    {
        return [
            'estado' => 'boolean',
        ];
    }

    public function tiposDocumentales(): HasMany
    {
        return $this->hasMany(TipoDocumental::class, 'id_departamento');
    }
}
