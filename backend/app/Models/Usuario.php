<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class Usuario extends Authenticatable
{
    use HasApiTokens;

    public const ROL_ADMINISTRADOR = 'Administrador';

    public const ROL_RESPONSABLE = 'Responsable del archivo';

    public const ROL_FUNCIONARIO = 'Funcionario departamental';

    protected $table = 'usuario';

    protected $primaryKey = 'id_usuario';

    public $timestamps = false;

    protected $fillable = [
        'id_rol', 'id_departamento', 'nombres', 'apellidos', 'correo',
        'nombre_usuario', 'clave_hash', 'estado', 'ultimo_acceso',
    ];

    protected $hidden = ['clave_hash'];

    protected function casts(): array
    {
        return [
            'clave_hash' => 'hashed',
            'estado' => 'boolean',
            'fecha_creacion' => 'datetime',
            'ultimo_acceso' => 'datetime',
        ];
    }

    public function getAuthPasswordName(): string
    {
        return 'clave_hash';
    }

    public function getRememberTokenName(): ?string
    {
        return null;
    }

    public function rol(): BelongsTo
    {
        return $this->belongsTo(Rol::class, 'id_rol');
    }

    public function departamento(): BelongsTo
    {
        return $this->belongsTo(Departamento::class, 'id_departamento');
    }

    public function tieneRol(string ...$roles): bool
    {
        return in_array($this->rol?->nombre, $roles, true);
    }
}
