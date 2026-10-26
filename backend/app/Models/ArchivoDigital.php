<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ArchivoDigital extends Model
{
    protected $table = 'archivo_digital';

    protected $primaryKey = 'id_archivo';

    public $timestamps = false;

    protected $fillable = ['id_documento', 'nombre_archivo', 'ruta_archivo', 'tipo_mime', 'tamano_bytes', 'subido_por', 'fecha_carga'];

    protected $hidden = ['ruta_archivo'];

    protected function casts(): array
    {
        return [
            'fecha_carga' => 'datetime',
        ];
    }

    public function documento(): BelongsTo
    {
        return $this->belongsTo(Documento::class, 'id_documento');
    }

    public function subidoPor(): BelongsTo
    {
        return $this->belongsTo(Usuario::class, 'subido_por');
    }
}
