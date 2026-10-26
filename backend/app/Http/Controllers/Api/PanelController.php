<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Documento;
use App\Models\Movimiento;
use App\Models\Prestamo;
use App\Models\SolicitudPrestamo;
use App\Models\Usuario;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/** Resumen del panel principal (wireframe Figura 35): indicadores, gráficos y actividad reciente. */
class PanelController extends Controller
{
    public function resumen(Request $request): JsonResponse
    {
        $u = $request->user();
        $personal = ! $u->tieneRol(Usuario::ROL_RESPONSABLE, Usuario::ROL_ADMINISTRADOR);

        $documentos = Documento::query()->visiblePara($u);
        $prestamos = Prestamo::query()->where('estado', Prestamo::ACTIVO);
        $solicitudes = SolicitudPrestamo::query()->where('estado', SolicitudPrestamo::PENDIENTE);
        if ($personal) {
            $prestamos->where('recibido_por', $u->id_usuario);
            $solicitudes->where('id_solicitante', $u->id_usuario);
        }

        $porEstado = (clone $documentos)->select('estado', DB::raw('count(*) as total'))->groupBy('estado')->pluck('total', 'estado');

        $datos = [
            'alcance' => $personal ? 'personal' : 'institucional',
            'documentos' => [
                'total' => (int) $porEstado->except(Documento::DE_BAJA)->sum(),
                'disponibles' => (int) ($porEstado[Documento::DISPONIBLE] ?? 0),
                'prestados' => (int) ($porEstado[Documento::PRESTADO] ?? 0),
                'de_baja' => (int) ($porEstado[Documento::DE_BAJA] ?? 0),
            ],
            'prestamos_activos' => (clone $prestamos)->count(),
            'prestamos_en_mora' => (clone $prestamos)->where('fecha_devolucion_prevista', '<', now())->count(),
            'solicitudes_pendientes' => (clone $solicitudes)->count(),
            'actividad_reciente' => $this->actividad($u, $personal),
        ];

        if (! $personal) {
            $datos['por_departamento'] = DB::table('documento as d')
                ->join('tipo_documental as t', 't.id_tipo_documental', '=', 'd.id_tipo_documental')
                ->join('departamento as p', 'p.id_departamento', '=', 't.id_departamento')
                ->where('d.estado', '!=', Documento::DE_BAJA)
                ->groupBy('p.nombre')->orderByDesc(DB::raw('count(*)'))
                ->select('p.nombre as departamento', DB::raw('count(*) as total'))->get();

            $porMes = DB::table('prestamo')
                ->where('fecha_entrega', '>=', now()->startOfMonth()->subMonths(5))
                ->groupBy(DB::raw("to_char(fecha_entrega, 'YYYY-MM')"))
                ->select(DB::raw("to_char(fecha_entrega, 'YYYY-MM') as mes"), DB::raw('count(*) as total'))
                ->pluck('total', 'mes');
            $datos['prestamos_por_mes'] = collect(range(5, 0))->map(function ($atras) use ($porMes) {
                $mes = now()->startOfMonth()->subMonths($atras);

                return ['mes' => $mes->format('Y-m'), 'total' => (int) ($porMes[$mes->format('Y-m')] ?? 0)];
            })->values();
        }

        return response()->json($datos);
    }

    private function actividad(Usuario $u, bool $personal): array
    {
        $q = Movimiento::with(['documento:id_documento,codigo_documental,titulo', 'usuario:id_usuario,nombres,apellidos'])
            ->orderByDesc('fecha_movimiento')->orderByDesc('id_movimiento')->limit(8);
        if ($personal) {
            $q->where('id_usuario', $u->id_usuario);
        }

        return $q->get()->all();
    }
}
