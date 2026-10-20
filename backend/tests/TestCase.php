<?php

namespace Tests;

use App\Models\Departamento;
use App\Models\Documento;
use App\Models\Rol;
use App\Models\TipoDocumental;
use App\Models\Ubicacion;
use App\Models\Usuario;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;

/**
 * Las pruebas corren sobre PostgreSQL y se revierten con DatabaseTransactions: nunca borran datos reales
 * ni de demostración. Los datos propios de cada prueba usan nombres aleatorios para no chocar con ellos.
 */
abstract class TestCase extends BaseTestCase
{
    use DatabaseTransactions;

    protected function setUp(): void
    {
        parent::setUp();
        if (Rol::count() === 0) {
            $this->seed(DatabaseSeeder::class);
        }
    }

    protected function usuario(string $rol, ?string $departamento = 'Secretaría', bool $activo = true): Usuario
    {
        $sufijo = Str::lower(Str::random(8));

        return Usuario::create([
            'id_rol' => Rol::where('nombre', $rol)->firstOrFail()->id_rol,
            'id_departamento' => $departamento ? Departamento::where('nombre', $departamento)->firstOrFail()->id_departamento : null,
            'nombres' => 'Prueba',
            'apellidos' => ucfirst($sufijo),
            'correo' => "prueba.$sufijo@test.local",
            'nombre_usuario' => "prueba_$sufijo",
            'clave_hash' => 'clave-de-prueba-123',
            'estado' => $activo,
        ]);
    }

    protected function como(string $rol, ?string $departamento = 'Secretaría'): Usuario
    {
        $u = $this->usuario($rol, $departamento);
        Sanctum::actingAs($u);

        return $u;
    }

    protected function responsable(): Usuario
    {
        return $this->como(Usuario::ROL_RESPONSABLE);
    }

    /** Registra un documento por la API (como lo haría el Responsable del archivo) y devuelve el JSON. */
    protected function registrarDocumento(array $extra = [], string $departamento = 'Jurídico'): array
    {
        $tipo = TipoDocumental::whereHas('departamento', fn ($d) => $d->where('nombre', $departamento))->orderBy('id_tipo_documental')->firstOrFail();

        return $this->postJson('/api/documentos', [
            'id_tipo_documental' => $tipo->id_tipo_documental,
            'titulo' => 'Oficio de prueba '.Str::random(6),
            'fecha_documento' => now()->subDay()->toDateString(),
            ...$extra,
        ])->assertCreated()->json();
    }

    protected function ubicacion(): Ubicacion
    {
        return Ubicacion::create(['area' => 'Prueba '.Str::random(5), 'archivador' => 'T-1', 'estante' => '1', 'caja' => '1', 'estado' => true]);
    }

    protected function documentoModelo(array $override = []): Documento
    {
        $this->responsable();

        return Documento::findOrFail($this->registrarDocumento($override)['id_documento']);
    }
}
