<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ubicacion extends Model
{
    protected $table = 'ubicacion';

    protected $primaryKey = 'id_ubicacion';

    public $timestamps = false;

    protected $fillable = ['area', 'archivador', 'estante', 'seccion', 'caja', 'descripcion', 'estado'];

    protected $appends = ['etiqueta'];

    protected function casts(): array
    {
        return [
            'estado' => 'boolean',
        ];
    }

    /** Texto legible de la ubicación física: "Archivo general · Archivador A-03 · Estante 2 · Caja 14". */
    public function getEtiquetaAttribute(): string
    {
        return collect([
            $this->area,
            $this->archivador ? "Archivador $this->archivador" : null,
            $this->estante ? "Estante $this->estante" : null,
            $this->seccion ? "Sección $this->seccion" : null,
            $this->caja ? "Caja $this->caja" : null,
        ])->filter()->implode(' · ');
    }
}
