<?php

namespace Tests\Feature;

use App\Models\Usuario;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

/** M03 Gestión QR · M06 Reportes · panel · RNF-02 (rendimiento de consulta). */
class QrYReportesTest extends TestCase
{
    public function test_el_qr_se_resuelve_desde_el_contenido_el_uuid_o_una_url(): void
    {
        $doc = $this->documentoModelo();
        $qr = $this->getJson("/api/documentos/{$doc->id_documento}/qr")->assertOk()->json();

        $this->assertStringStartsWith('SIGEDOC:', $qr['contenido']);
        $this->assertStringContainsString('<svg', $qr['svg']);

        $this->como(Usuario::ROL_FUNCIONARIO, 'Jurídico');
        foreach ([$qr['contenido'], $qr['identificador'], "https://sigedoc.example/q/{$qr['identificador']}"] as $leido) {
            $this->postJson('/api/qr/resolver', ['codigo' => $leido])->assertOk()->assertJsonPath('id_documento', $doc->id_documento);
        }
        $this->assertDatabaseHas('movimiento', ['id_documento' => $doc->id_documento, 'tipo_movimiento' => 'consulta_qr']);
    }

    public function test_un_codigo_desconocido_o_invalido_responde_404(): void
    {
        $this->como(Usuario::ROL_FUNCIONARIO);
        $this->postJson('/api/qr/resolver', ['codigo' => 'hola mundo'])->assertNotFound();
        $this->postJson('/api/qr/resolver', ['codigo' => 'SIGEDOC:'.Str::uuid()])->assertNotFound();
    }

    public function test_cada_documento_tiene_un_unico_qr(): void
    {
        $doc = $this->documentoModelo();
        $this->expectException(\Illuminate\Database\UniqueConstraintViolationException::class); // RN-02
        \App\Services\GestorQr::generar($doc);
    }

    public function test_la_etiqueta_solo_se_abre_con_enlace_firmado(): void
    {
        $doc = $this->documentoModelo();
        $url = $this->postJson("/api/documentos/{$doc->id_documento}/qr/etiqueta")->assertOk()->json('url');

        $this->get("/api/etiquetas/{$doc->id_documento}")->assertForbidden(); // sin firma
        $this->get($url)->assertOk()->assertSee($doc->codigo_documental)->assertSee('<svg', false);
    }

    public function test_el_funcionario_no_puede_generar_etiquetas(): void
    {
        $doc = $this->documentoModelo();
        $this->como(Usuario::ROL_FUNCIONARIO);
        $this->postJson("/api/documentos/{$doc->id_documento}/qr/etiqueta")->assertForbidden();
    }

    public function test_reporte_de_documentos_y_exportacion_csv(): void
    {
        $doc = $this->documentoModelo(['titulo' => 'Reporte '.Str::random(8)]);

        $r = $this->getJson('/api/reportes/documentos')->assertOk()->json();
        $this->assertSame('Código', $r['columnas'][0]);
        $this->assertContains($doc->codigo_documental, collect($r['filas'])->pluck(0)->all());

        $url = $this->postJson('/api/reportes/documentos/enlace-csv')->assertOk()->json('url');
        $csv = $this->get($url)->assertOk()->streamedContent();
        $this->assertStringContainsString($doc->codigo_documental, $csv);
        $this->assertStringStartsWith("\xEF\xBB\xBF", $csv);
        $this->getJson('/api/reportes/inexistente')->assertNotFound();
    }

    public function test_reporte_de_movimientos_y_de_prestamos(): void
    {
        $doc = $this->documentoModelo();
        $this->postJson('/api/prestamos', [
            'id_documento' => $doc->id_documento,
            'id_receptor' => $this->usuario(Usuario::ROL_FUNCIONARIO)->id_usuario,
            'fecha_devolucion_prevista' => now()->addDays(3)->toDateString(),
        ])->assertCreated();

        $this->getJson('/api/reportes/prestamos?estado=activo')->assertOk()
            ->assertSee($doc->codigo_documental, false);
        $mov = $this->getJson('/api/reportes/movimientos?tipo_movimiento=prestamo')->assertOk()->json();
        $this->assertGreaterThanOrEqual(1, $mov['total']);
        $this->getJson('/api/reportes/movimientos?desde=2026-12-31&hasta=2026-01-01')->assertStatus(422);
    }

    public function test_panel_resumen_por_rol(): void
    {
        $doc = $this->documentoModelo();
        $func = $this->usuario(Usuario::ROL_FUNCIONARIO);
        $this->postJson('/api/prestamos', [
            'id_documento' => $doc->id_documento, 'id_receptor' => $func->id_usuario,
            'fecha_devolucion_prevista' => now()->addDays(3)->toDateString(),
        ])->assertCreated();

        $inst = $this->getJson('/api/panel/resumen')->assertOk()->json();
        $this->assertSame('institucional', $inst['alcance']);
        $this->assertGreaterThanOrEqual(1, $inst['prestamos_activos']);
        $this->assertCount(6, $inst['prestamos_por_mes']);

        $this->actingAs($func, 'sanctum');
        $pers = $this->getJson('/api/panel/resumen')->assertOk()->json();
        $this->assertSame('personal', $pers['alcance']);
        $this->assertSame(1, $pers['prestamos_activos']);
        $this->assertArrayNotHasKey('por_departamento', $pers);
    }

    public function test_consulta_de_documentos_responde_en_menos_de_tres_segundos_con_cinco_mil_registros(): void
    {
        $this->responsable();
        $doc = $this->registrarDocumento();
        $base = DB::table('documento')->where('id_documento', $doc['id_documento'])->first();

        $filas = [];
        for ($i = 0; $i < 5000; $i++) {
            $filas[] = [
                'id_tipo_documental' => $base->id_tipo_documental, 'creado_por' => $base->creado_por,
                'codigo_documental' => 'RND-'.Str::random(6).'-'.$i, 'titulo' => 'Documento de carga '.Str::random(12),
                'nivel_acceso' => 'interno', 'estado' => 'disponible', 'fecha_documento' => now()->subDays($i % 900)->toDateString(),
            ];
        }
        foreach (array_chunk($filas, 500) as $lote) {
            DB::table('documento')->insert($lote);
        }

        $inicio = microtime(true);
        $this->getJson('/api/documentos?buscar=carga&estado=disponible')->assertOk(); // RNF-02
        $this->assertLessThan(3.0, microtime(true) - $inicio, 'La consulta superó los 3 s (RNF-02).');
    }
}
