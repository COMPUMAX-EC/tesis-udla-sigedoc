<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\URL;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * M06 Reportes: documentos (RF-06.1), préstamos y devoluciones (RF-06.2), movimientos (RF-06.3).
 * Cada reporte se consulta como JSON y se exporta a CSV mediante un enlace temporal firmado.
 */
class ReporteController extends Controller
{
    private const TIPOS = ['documentos', 'prestamos', 'movimientos'];

    public function ver(Request $request, string $tipo): JsonResponse
    {
        return response()->json($this->construir($tipo, $this->filtros($request)));
    }

    public function enlaceCsv(Request $request, string $tipo): JsonResponse
    {
        $filtros = $this->filtros($request);
        $this->construir($tipo, $filtros); // valida el tipo

        return response()->json([
            'url' => URL::temporarySignedRoute('reportes.csv', now()->addMinutes(5), ['tipo' => $tipo, ...array_filter($filtros)]),
        ]);
    }

    public function csv(Request $request, string $tipo): StreamedResponse
    {
        $reporte = $this->construir($tipo, $this->filtros($request));
        $nombre = "sigedoc-$tipo-".now()->format('Ymd-His').'.csv';

        return response()->streamDownload(function () use ($reporte) {
            $f = fopen('php://output', 'w');
            fwrite($f, "\xEF\xBB\xBF"); // BOM para que Excel respete los acentos
            fputcsv($f, $reporte['columnas'], ';');
            foreach ($reporte['filas'] as $fila) {
                fputcsv($f, $fila, ';');
            }
            fclose($f);
        }, $nombre, ['Content-Type' => 'text/csv; charset=UTF-8']);
    }

    private function filtros(Request $request): array
    {
        return $request->validate([
            'desde' => ['nullable', 'date'],
            'hasta' => ['nullable', 'date', 'after_or_equal:desde'],
            'id_departamento' => ['nullable', 'integer'],
            'estado' => ['nullable', 'string', 'max:30'],
            'tipo_movimiento' => ['nullable', 'string', 'max:50'],
        ]);
    }

    /** @return array{titulo:string,columnas:string[],filas:array,total:int,resumen:array} */
    private function construir(string $tipo, array $f): array
    {
        abort_unless(in_array($tipo, self::TIPOS, true), 404, 'Reporte no existente.');

        return match ($tipo) {
            'documentos' => $this->documentos($f),
            'prestamos' => $this->prestamos($f),
            'movimientos' => $this->movimientos($f),
        };
    }

    private function documentos(array $f): array
    {
        $q = DB::table('documento as d')
            ->join('tipo_documental as t', 't.id_tipo_documental', '=', 'd.id_tipo_documental')
            ->join('departamento as p', 'p.id_departamento', '=', 't.id_departamento')
            ->leftJoin('categoria as c', 'c.id_categoria', '=', 'd.id_categoria')
            ->leftJoin('ubicacion as u', 'u.id_ubicacion', '=', 'd.id_ubicacion')
            ->select('d.codigo_documental', 'd.titulo', 'p.nombre as departamento', 't.nombre as tipo', 'c.nombre as categoria',
                'u.area', 'u.archivador', 'u.estante', 'u.caja', 'd.nivel_acceso', 'd.estado', 'd.fecha_documento', 'd.fecha_registro')
            ->orderBy('d.codigo_documental');
        $this->fechas($q, 'd.fecha_documento', $f);
        isset($f['id_departamento']) && $q->where('p.id_departamento', $f['id_departamento']);
        isset($f['estado']) && $q->where('d.estado', $f['estado']);

        $filas = $q->get()->map(fn ($r) => [
            $r->codigo_documental, $r->titulo, $r->departamento, $r->tipo, $r->categoria ?? '—',
            collect([$r->area, $r->archivador ? "Archivador $r->archivador" : null, $r->estante ? "Estante $r->estante" : null, $r->caja ? "Caja $r->caja" : null])->filter()->implode(' · ') ?: '—',
            $r->nivel_acceso, $r->estado, $r->fecha_documento ?? '—', substr((string) $r->fecha_registro, 0, 10),
        ])->all();

        return [
            'titulo' => 'Documentos registrados',
            'columnas' => ['Código', 'Título', 'Departamento', 'Tipo documental', 'Categoría', 'Ubicación', 'Acceso', 'Estado', 'Fecha del documento', 'Registrado'],
            'filas' => $filas,
            'total' => count($filas),
            'resumen' => $this->contar($filas, 7),
        ];
    }

    private function prestamos(array $f): array
    {
        $q = DB::table('prestamo as pr')
            ->join('documento as d', 'd.id_documento', '=', 'pr.id_documento')
            ->join('usuario as r', 'r.id_usuario', '=', 'pr.recibido_por')
            ->join('usuario as e', 'e.id_usuario', '=', 'pr.entregado_por')
            ->leftJoin('departamento as p', 'p.id_departamento', '=', 'r.id_departamento')
            ->select('d.codigo_documental', 'd.titulo', DB::raw("r.nombres || ' ' || r.apellidos as receptor"), 'p.nombre as departamento',
                DB::raw("e.nombres || ' ' || e.apellidos as entregado_por"), 'pr.fecha_entrega', 'pr.fecha_devolucion_prevista',
                'pr.fecha_devolucion_real', 'pr.estado', 'pr.observacion')
            ->orderByDesc('pr.fecha_entrega');
        $this->fechas($q, 'pr.fecha_entrega', $f);
        isset($f['id_departamento']) && $q->where('r.id_departamento', $f['id_departamento']);
        isset($f['estado']) && $q->where('pr.estado', $f['estado']);

        $ahora = now();
        $filas = $q->get()->map(fn ($r) => [
            $r->codigo_documental, $r->titulo, $r->receptor, $r->departamento ?? '—', $r->entregado_por,
            substr($r->fecha_entrega, 0, 10), substr($r->fecha_devolucion_prevista, 0, 10),
            $r->fecha_devolucion_real ? substr($r->fecha_devolucion_real, 0, 10) : '—',
            $r->estado === 'activo' && $r->fecha_devolucion_prevista < $ahora->toDateTimeString() ? 'en mora' : $r->estado,
            $r->observacion ?? '',
        ])->all();

        return [
            'titulo' => 'Préstamos y devoluciones',
            'columnas' => ['Código', 'Documento', 'Receptor', 'Departamento', 'Entregado por', 'Entrega', 'Devolución prevista', 'Devolución real', 'Estado', 'Observación'],
            'filas' => $filas,
            'total' => count($filas),
            'resumen' => $this->contar($filas, 8),
        ];
    }

    private function movimientos(array $f): array
    {
        $q = DB::table('movimiento as m')
            ->join('documento as d', 'd.id_documento', '=', 'm.id_documento')
            ->join('usuario as u', 'u.id_usuario', '=', 'm.id_usuario')
            ->join('tipo_documental as t', 't.id_tipo_documental', '=', 'd.id_tipo_documental')
            ->select('m.fecha_movimiento', 'd.codigo_documental', 'd.titulo', 'm.tipo_movimiento', 'm.descripcion',
                'm.estado_anterior', 'm.estado_nuevo', DB::raw("u.nombres || ' ' || u.apellidos as usuario"), 'm.direccion_ip')
            ->orderByDesc('m.fecha_movimiento')->orderByDesc('m.id_movimiento')->limit(5000);
        $this->fechas($q, 'm.fecha_movimiento', $f);
        isset($f['id_departamento']) && $q->where('t.id_departamento', $f['id_departamento']);
        isset($f['tipo_movimiento']) && $q->where('m.tipo_movimiento', $f['tipo_movimiento']);

        $filas = $q->get()->map(fn ($r) => [
            substr($r->fecha_movimiento, 0, 16), $r->codigo_documental, $r->titulo, $r->tipo_movimiento, $r->descripcion ?? '',
            $r->estado_anterior ?? '—', $r->estado_nuevo ?? '—', $r->usuario, $r->direccion_ip ?? '—',
        ])->all();

        return [
            'titulo' => 'Movimientos documentales',
            'columnas' => ['Fecha', 'Código', 'Documento', 'Movimiento', 'Detalle', 'Estado anterior', 'Estado nuevo', 'Usuario', 'IP'],
            'filas' => $filas,
            'total' => count($filas),
            'resumen' => $this->contar($filas, 3),
        ];
    }

    private function fechas($q, string $columna, array $f): void
    {
        isset($f['desde']) && $q->whereDate($columna, '>=', $f['desde']);
        isset($f['hasta']) && $q->whereDate($columna, '<=', $f['hasta']);
    }

    /** Conteo por el valor de una columna (para el resumen del reporte). */
    private function contar(array $filas, int $columna): array
    {
        return collect($filas)->countBy(fn ($f) => $f[$columna])->sortDesc()->all();
    }
}
