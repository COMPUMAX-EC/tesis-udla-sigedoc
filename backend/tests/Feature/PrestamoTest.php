<?php

namespace Tests\Feature;

use App\Models\Documento;
use App\Models\Prestamo;
use App\Models\Usuario;
use Tests\TestCase;

/** M04 Préstamos · RN-03 · RN-04 · RN-05 · RN-06 · RF-05.1. */
class PrestamoTest extends TestCase
{
    private function entregar(Documento $doc, Usuario $receptor, array $extra = [])
    {
        return $this->postJson('/api/prestamos', [
            'id_documento' => $doc->id_documento,
            'id_receptor' => $receptor->id_usuario,
            'fecha_devolucion_prevista' => now()->addDays(7)->toDateString(),
            ...$extra,
        ]);
    }

    public function test_ciclo_completo_solicitud_aprobacion_entrega_y_devolucion(): void
    {
        $doc = $this->documentoModelo();
        $func = $this->como(Usuario::ROL_FUNCIONARIO, 'Jurídico');

        $solicitud = $this->postJson('/api/solicitudes', ['id_documento' => $doc->id_documento, 'motivo' => 'Revisión'])->assertCreated()->json();
        $this->assertSame('pendiente', $solicitud['estado']);
        $this->assertSame('disponible', $doc->fresh()->estado); // solicitar no cambia el estado

        $this->responsable();
        $this->postJson("/api/solicitudes/{$solicitud['id_solicitud']}/resolver", ['decision' => 'aprobar'])->assertOk()->assertJsonPath('estado', 'aprobada');

        $prestamo = $this->entregar($doc, $func, ['id_solicitud' => $solicitud['id_solicitud']])->assertCreated()->json();
        $this->assertSame('prestado', $doc->fresh()->estado); // RN-05
        $this->assertDatabaseHas('movimiento', ['id_documento' => $doc->id_documento, 'tipo_movimiento' => 'prestamo', 'estado_anterior' => 'disponible', 'estado_nuevo' => 'prestado']);

        $this->postJson("/api/prestamos/{$prestamo['id_prestamo']}/devolver", ['observacion' => 'Sin novedades'])
            ->assertOk()->assertJsonPath('estado', 'devuelto')->assertJsonPath('observacion', 'Sin novedades');
        $this->assertSame('disponible', $doc->fresh()->estado); // RN-05
        $this->assertNotNull(Prestamo::find($prestamo['id_prestamo'])->fecha_devolucion_real);
        $this->assertDatabaseHas('movimiento', ['id_documento' => $doc->id_documento, 'tipo_movimiento' => 'devolucion', 'estado_nuevo' => 'disponible']);
    }

    public function test_no_se_presta_un_documento_no_disponible(): void
    {
        $doc = $this->documentoModelo();
        $receptor = $this->usuario(Usuario::ROL_FUNCIONARIO);
        $this->entregar($doc, $receptor)->assertCreated();

        $this->entregar($doc, $receptor)->assertStatus(422)->assertJsonValidationErrors('id_documento'); // RN-03 / RN-04

        $this->como(Usuario::ROL_FUNCIONARIO, 'Jurídico');
        $this->postJson('/api/solicitudes', ['id_documento' => $doc->id_documento])->assertStatus(422)->assertJsonValidationErrors('id_documento');
    }

    public function test_un_documento_nunca_tiene_dos_prestamos_activos(): void
    {
        $doc = $this->documentoModelo();
        $a = $this->usuario(Usuario::ROL_FUNCIONARIO);
        $b = $this->usuario(Usuario::ROL_FUNCIONARIO);

        $this->entregar($doc, $a)->assertCreated();
        $this->entregar($doc, $b)->assertStatus(422);
        $this->assertSame(1, Prestamo::where('id_documento', $doc->id_documento)->where('estado', 'activo')->count());

        // Respaldo en base de datos: el índice parcial único rechaza el segundo activo aunque se salte la API.
        $this->expectException(\Illuminate\Database\UniqueConstraintViolationException::class);
        Prestamo::create([
            'id_documento' => $doc->id_documento, 'entregado_por' => $a->id_usuario, 'recibido_por' => $b->id_usuario,
            'fecha_entrega' => now(), 'fecha_devolucion_prevista' => now()->addDay(), 'estado' => 'activo',
        ]);
    }

    public function test_no_se_devuelve_dos_veces(): void
    {
        $doc = $this->documentoModelo();
        $p = $this->entregar($doc, $this->usuario(Usuario::ROL_FUNCIONARIO))->assertCreated()->json();

        $this->postJson("/api/prestamos/{$p['id_prestamo']}/devolver")->assertOk();
        $this->postJson("/api/prestamos/{$p['id_prestamo']}/devolver")->assertStatus(422);
    }

    public function test_solicitud_rechazada_no_permite_entrega_ni_resolverse_otra_vez(): void
    {
        $doc = $this->documentoModelo();
        $func = $this->como(Usuario::ROL_FUNCIONARIO, 'Jurídico');
        $s = $this->postJson('/api/solicitudes', ['id_documento' => $doc->id_documento])->assertCreated()->json();

        $this->responsable();
        $this->postJson("/api/solicitudes/{$s['id_solicitud']}/resolver", ['decision' => 'rechazar', 'observacion' => 'No sale del archivo'])->assertOk();
        $this->postJson("/api/solicitudes/{$s['id_solicitud']}/resolver", ['decision' => 'aprobar'])->assertStatus(422);
        $this->entregar($doc, $func, ['id_solicitud' => $s['id_solicitud']])->assertStatus(422)->assertJsonValidationErrors('id_solicitud');
    }

    public function test_solo_el_responsable_gestiona_prestamos_y_el_funcionario_ve_los_suyos(): void
    {
        $doc = $this->documentoModelo();
        $func = $this->usuario(Usuario::ROL_FUNCIONARIO);
        $otro = $this->usuario(Usuario::ROL_FUNCIONARIO);
        $this->entregar($doc, $func)->assertCreated();

        $this->actingAs($func, 'sanctum');
        $this->postJson('/api/prestamos', [])->assertForbidden();
        $this->getJson('/api/prestamos')->assertOk()->assertJsonCount(1, 'data');

        $this->actingAs($otro, 'sanctum');
        $this->getJson('/api/prestamos')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_prestamo_vencido_aparece_en_mora(): void
    {
        $doc = $this->documentoModelo();
        $p = $this->entregar($doc, $this->usuario(Usuario::ROL_FUNCIONARIO))->assertCreated()->json();
        Prestamo::whereKey($p['id_prestamo'])->update(['fecha_devolucion_prevista' => now()->subDays(2)]);

        $this->getJson('/api/prestamos?en_mora=1')->assertOk()->assertJsonFragment(['id_prestamo' => $p['id_prestamo'], 'en_mora' => true]);
    }

    public function test_el_historial_de_prestamos_no_se_puede_eliminar(): void
    {
        $doc = $this->documentoModelo();
        $p = $this->entregar($doc, $this->usuario(Usuario::ROL_FUNCIONARIO))->assertCreated()->json();
        $this->postJson("/api/prestamos/{$p['id_prestamo']}/devolver")->assertOk();

        $this->deleteJson("/api/prestamos/{$p['id_prestamo']}")->assertStatus(405); // no existe la operación (RN-06)
        $this->expectException(\Illuminate\Database\QueryException::class); // y la base de datos lo impide
        Prestamo::whereKey($p['id_prestamo'])->delete();
    }

    public function test_no_se_da_de_baja_un_documento_prestado(): void
    {
        $doc = $this->documentoModelo();
        $this->entregar($doc, $this->usuario(Usuario::ROL_FUNCIONARIO))->assertCreated();

        $this->deleteJson("/api/documentos/{$doc->id_documento}")->assertStatus(422);
    }

    public function test_la_fecha_de_devolucion_no_puede_ser_pasada(): void
    {
        $doc = $this->documentoModelo();
        $this->entregar($doc, $this->usuario(Usuario::ROL_FUNCIONARIO), ['fecha_devolucion_prevista' => now()->subDay()->toDateString()])
            ->assertStatus(422)->assertJsonValidationErrors('fecha_devolucion_prevista');
    }
}
