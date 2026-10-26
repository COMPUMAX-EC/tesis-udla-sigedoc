<?php

namespace Tests\Feature;

use App\Models\Documento;
use App\Models\Movimiento;
use App\Models\Usuario;
use Illuminate\Support\Str;
use Tests\TestCase;

/** M02 Gestión documental · RN-01 · RF-05.1. */
class DocumentoTest extends TestCase
{
    public function test_registra_documento_con_codigo_unico_qr_y_movimiento(): void
    {
        $this->responsable();
        $ubicacion = $this->ubicacion();

        $d = $this->registrarDocumento(['id_ubicacion' => $ubicacion->id_ubicacion, 'nivel_acceso' => 'interno']);

        $this->assertMatchesRegularExpression('/^JUR-\d{4}-\d{4}$/', $d['codigo_documental']); // RN-01
        $this->assertSame('disponible', $d['estado']);
        $this->assertNotNull($d['qr']['identificador']); // RF-03.1 / RF-03.2
        $this->assertDatabaseHas('movimiento', ['id_documento' => $d['id_documento'], 'tipo_movimiento' => 'registro']);
        $this->assertDatabaseHas('movimiento', ['id_documento' => $d['id_documento'], 'tipo_movimiento' => 'qr_generado']);
    }

    public function test_los_codigos_son_consecutivos_y_no_se_repiten(): void
    {
        $this->responsable();
        $a = $this->registrarDocumento()['codigo_documental'];
        $b = $this->registrarDocumento()['codigo_documental'];

        $this->assertNotSame($a, $b);
        $this->assertSame((int) substr($a, -4) + 1, (int) substr($b, -4));
    }

    public function test_exige_tipo_documental_y_titulo(): void
    {
        $this->responsable();
        $this->postJson('/api/documentos', [])->assertStatus(422)->assertJsonValidationErrors(['id_tipo_documental', 'titulo']);
    }

    public function test_no_se_puede_fechar_un_documento_en_el_futuro(): void
    {
        $this->responsable();
        $this->postJson('/api/documentos', ['id_tipo_documental' => 1, 'titulo' => 'X', 'fecha_documento' => now()->addDays(3)->toDateString()])
            ->assertStatus(422)->assertJsonValidationErrors('fecha_documento');
    }

    public function test_cambiar_la_ubicacion_deja_rastro(): void
    {
        $this->responsable();
        $d = $this->registrarDocumento();
        $nueva = $this->ubicacion();

        $this->putJson("/api/documentos/{$d['id_documento']}", ['id_ubicacion' => $nueva->id_ubicacion])->assertOk();

        $this->assertDatabaseHas('movimiento', ['id_documento' => $d['id_documento'], 'tipo_movimiento' => 'cambio_ubicacion']);
        $this->getJson("/api/documentos/{$d['id_documento']}/ubicacion")->assertOk()->assertJsonPath('ubicacion.id_ubicacion', $nueva->id_ubicacion);
    }

    public function test_el_estado_no_se_cambia_editando_el_documento(): void
    {
        $this->responsable();
        $d = $this->registrarDocumento();

        $this->putJson("/api/documentos/{$d['id_documento']}", ['estado' => 'prestado', 'titulo' => 'Nuevo título'])->assertOk();
        $this->assertSame('disponible', Documento::find($d['id_documento'])->estado);
    }

    public function test_busqueda_por_texto_y_filtros(): void
    {
        $this->responsable();
        $clave = Str::lower(Str::random(10));
        $d = $this->registrarDocumento(['titulo' => "Contrato especial $clave"]);

        $this->getJson("/api/documentos?buscar=$clave")->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id_documento', $d['id_documento']);
        $this->getJson("/api/documentos?buscar=$clave&estado=prestado")->assertOk()->assertJsonCount(0, 'data');
        $this->getJson("/api/documentos?buscar={$d['codigo_documental']}")->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_dar_de_baja_y_reactivar_conserva_el_historial(): void
    {
        $this->responsable();
        $d = $this->registrarDocumento();

        $this->deleteJson("/api/documentos/{$d['id_documento']}")->assertOk()->assertJsonPath('estado', 'de_baja');
        $this->assertDatabaseHas('documento', ['id_documento' => $d['id_documento']]); // no se elimina (RN-06)
        $this->postJson("/api/documentos/{$d['id_documento']}/reactivar")->assertOk()->assertJsonPath('estado', 'disponible');
        $this->getJson("/api/documentos/{$d['id_documento']}/historial")->assertOk()->assertJsonCount(4); // registro, QR, baja, reactivación
    }

    public function test_documento_confidencial_solo_lo_ve_su_departamento(): void
    {
        $this->responsable();
        $d = $this->registrarDocumento(['nivel_acceso' => 'confidencial'], 'Jurídico');

        $this->como(Usuario::ROL_FUNCIONARIO, 'Tesorería');
        $this->getJson("/api/documentos/{$d['id_documento']}")->assertForbidden();
        $this->getJson("/api/documentos?buscar={$d['codigo_documental']}")->assertOk()->assertJsonCount(0, 'data');

        $this->como(Usuario::ROL_FUNCIONARIO, 'Jurídico');
        $this->getJson("/api/documentos/{$d['id_documento']}")->assertOk();
    }

    public function test_el_funcionario_no_ve_quien_tiene_el_documento(): void
    {
        $doc = $this->documentoModelo();
        $this->postJson('/api/prestamos', [
            'id_documento' => $doc->id_documento,
            'id_receptor' => $this->usuario(Usuario::ROL_FUNCIONARIO)->id_usuario,
            'fecha_devolucion_prevista' => now()->addDays(5)->toDateString(),
        ])->assertCreated();

        $this->como(Usuario::ROL_FUNCIONARIO);
        $r = $this->getJson("/api/documentos/{$doc->id_documento}")->assertOk()->json();
        $this->assertSame('prestado', $r['estado']);
        $this->assertArrayNotHasKey('recibido_por', $r['prestamo_activo']);
        $this->getJson("/api/documentos/{$doc->id_documento}/historial")->assertForbidden();
    }

    public function test_el_historial_de_movimientos_es_inmutable(): void
    {
        $this->responsable();
        $d = $this->registrarDocumento();
        $mov = Movimiento::where('id_documento', $d['id_documento'])->firstOrFail();

        $this->expectException(\Illuminate\Database\QueryException::class); // trigger de RN-06
        $mov->update(['descripcion' => 'alterado']);
    }
}
