<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Documento extends Model
{
    public const DISPONIBLE = 'disponible';

    public const PRESTADO = 'prestado';

    public const DE_BAJA = 'de_baja';

    public const NIVELES_ACCESO = ['publico', 'interno', 'confidencial'];

    protected $table = 'documento';

    protected $primaryKey = 'id_documento';

    public $timestamps = false;

    protected $fillable = ['id_categoria', 'id_tipo_documental', 'id_ubicacion', 'creado_por', 'codigo_documental', 'titulo', 'descripcion', 'fecha_documento', 'nivel_acceso', 'estado', 'fecha_registro', 'fecha_actualizacion'];

    protected function casts(): array
    {
        return [
            'fecha_documento' => 'date:Y-m-d',
            'fecha_registro' => 'datetime',
            'fecha_actualizacion' => 'datetime',
        ];
    }

    public function tipoDocumental(): BelongsTo
    {
        return $this->belongsTo(TipoDocumental::class, 'id_tipo_documental');
    }

    public function categoria(): BelongsTo
    {
        return $this->belongsTo(Categoria::class, 'id_categoria');
    }

    public function ubicacion(): BelongsTo
    {
        return $this->belongsTo(Ubicacion::class, 'id_ubicacion');
    }

    public function creador(): BelongsTo
    {
        return $this->belongsTo(Usuario::class, 'creado_por');
    }

    public function qr(): HasOne
    {
        return $this->hasOne(CodigoQr::class, 'id_documento');
    }

    public function archivos(): HasMany
    {
        return $this->hasMany(ArchivoDigital::class, 'id_documento');
    }

    public function prestamos(): HasMany
    {
        return $this->hasMany(Prestamo::class, 'id_documento');
    }

    public function prestamoActivo(): HasOne
    {
        return $this->hasOne(Prestamo::class, 'id_documento')->where('estado', Prestamo::ACTIVO);
    }

    public function movimientos(): HasMany
    {
        return $this->hasMany(Movimiento::class, 'id_documento');
    }

    /**
     * Nivel de acceso: los documentos confidenciales solo los ve el personal de archivo
     * y los funcionarios del departamento que los genera.
     */
    public function scopeVisiblePara(Builder $q, Usuario $usuario): Builder
    {
        if (! $usuario->tieneRol(Usuario::ROL_FUNCIONARIO)) {
            return $q;
        }

        return $q->where(function (Builder $w) use ($usuario) {
            $w->where('nivel_acceso', '!=', 'confidencial')
                ->orWhereHas('tipoDocumental', fn (Builder $t) => $t->where('id_departamento', $usuario->id_departamento));
        });
    }

    public function esVisiblePara(Usuario $usuario): bool
    {
        return static::query()->visiblePara($usuario)->whereKey($this->getKey())->exists();
    }
}
