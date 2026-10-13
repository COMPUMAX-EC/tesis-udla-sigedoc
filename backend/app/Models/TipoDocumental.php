<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TipoDocumental extends Model
{
    protected $table = 'tipo_documental';

    protected $primaryKey = 'id_tipo_documental';

    public $timestamps = false;

    protected $fillable = ['id_departamento', 'nombre', 'descripcion', 'estado'];

    protected function casts(): array
    {
        return [
            'estado' => 'boolean',
        ];
    }

    public function departamento(): BelongsTo
    {
        return $this->belongsTo(Departamento::class, 'id_departamento');
    }
}
