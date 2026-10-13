<?php

namespace Database\Seeders;

use App\Models\Departamento;
use App\Models\Rol;
use App\Models\TipoDocumental;
use App\Models\Usuario;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    /** Catálogo entregado por VIALZACHIN E.P. — docs/tipos-documentales.md */
    private const TIPOS_POR_DEPARTAMENTO = [
        'Gerencia' => ['Oficio interno', 'Oficio externo', 'Memorándum', 'Resolución', 'Informe de gestión'],
        'Financiero' => ['Oficio', 'Memorándum', 'Informe financiero'],
        'Secretaría' => ['Oficio', 'Memorándum', 'Convocatoria y acta de reunión'],
        'Coordinación Administrativa' => ['Oficio', 'Memorándum', 'Informe administrativo', 'Solicitud y requerimiento interno'],
        'Jurídico' => ['Oficio', 'Memorándum', 'Informe y criterio jurídico', 'Contrato y convenio', 'Documento de proceso legal o administrativo'],
        'Tesorería' => ['Oficio', 'Memorándum', 'Factura y comprobante de pago', 'Comprobante y reporte de transferencia o pago'],
        'Talento Humano' => ['Oficio', 'Memorándum', 'Expediente y registro del personal', 'Permiso, vacaciones y asistencia'],
    ];

    public function run(): void
    {
        $roles = [];
        foreach ([
            Usuario::ROL_ADMINISTRADOR => 'Configuración, usuarios, roles, departamentos y tipos documentales',
            Usuario::ROL_RESPONSABLE => 'Registro, clasificación, ubicación, QR, préstamos, trazabilidad y reportes',
            Usuario::ROL_FUNCIONARIO => 'Consulta, escaneo QR y solicitud de préstamos',
        ] as $nombre => $descripcion) {
            $roles[$nombre] = Rol::updateOrCreate(['nombre' => $nombre], ['descripcion' => $descripcion, 'estado' => true]);
        }

        $deps = [];
        foreach (self::TIPOS_POR_DEPARTAMENTO as $departamento => $tipos) {
            $deps[$departamento] = Departamento::updateOrCreate(['nombre' => $departamento], ['estado' => true]);
            foreach ($tipos as $tipo) {
                TipoDocumental::updateOrCreate(
                    ['id_departamento' => $deps[$departamento]->id_departamento, 'nombre' => $tipo],
                    ['estado' => true],
                );
            }
        }

        // Usuarios iniciales (uno por rol). Clave desde SIGEDOC_DEMO_CLAVE o aleatoria.
        $clave = env('SIGEDOC_DEMO_CLAVE') ?: Str::password(12, symbols: false);
        $creados = [];
        foreach ([
            ['admin', 'Administrador', 'del Sistema', Usuario::ROL_ADMINISTRADOR, null],
            ['secretaria', 'Responsable', 'del Archivo', Usuario::ROL_RESPONSABLE, 'Secretaría'],
            ['funcionario', 'Funcionario', 'Departamental', Usuario::ROL_FUNCIONARIO, 'Jurídico'],
        ] as [$usuario, $nombres, $apellidos, $rol, $dep]) {
            $u = Usuario::firstOrCreate(['nombre_usuario' => $usuario], [
                'nombres' => $nombres,
                'apellidos' => $apellidos,
                'correo' => "$usuario@vialzachin.gob.ec",
                'id_rol' => $roles[$rol]->id_rol,
                'id_departamento' => $dep ? $deps[$dep]->id_departamento : null,
                'clave_hash' => $clave,
                'estado' => true,
            ]);
            if ($u->wasRecentlyCreated) {
                $creados[] = $usuario;
            }
        }

        if ($creados) {
            $this->command?->info('Usuarios creados: '.implode(', ', $creados)." · clave: $clave");
        }
    }
}
