<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Documento;
use App\Models\SolicitudPrestamo;
use App\Models\Usuario;
use App\Services\PrestamoService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** RF-04.1 Solicitar préstamo · RF-04.2 Autorizar o rechazar solicitud. */
class SolicitudController extends Controller
{
    public function __construct(private PrestamoService $prestamos) {}

    private const RELACIONES = ['documento.tipoDocumental.departamento', 'documento.ubicacion', 'solicitante:id_usuario,nombres,apellidos,id_departamento', 'solicitante.departamento', 'prestamo:id_prestamo,id_solicitud,estado'];

    public function index(Request $request): JsonResponse
    {
        $f = $request->validate([
            'estado' => ['nullable', Rule::in([SolicitudPrestamo::PENDIENTE, SolicitudPrestamo::APROBADA, SolicitudPrestamo::RECHAZADA])],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $q = SolicitudPrestamo::with(self::RELACIONES)->orderByRaw("CASE estado WHEN 'pendiente' THEN 0 ELSE 1 END")->orderByDesc('fecha_solicitud');
        if (! $request->user()->tieneRol(Usuario::ROL_RESPONSABLE, Usuario::ROL_ADMINISTRADOR)) {
            $q->where('id_solicitante', $request->user()->id_usuario); // el funcionario solo ve las suyas
        }
        if (isset($f['estado'])) {
            $q->where('estado', $f['estado']);
        }

        return response()->json($q->paginate($f['per_page'] ?? 20));
    }

    public function store(Request $request): JsonResponse
    {
        $d = $request->validate([
            'id_documento' => ['required', 'exists:documento,id_documento'],
            'motivo' => ['nullable', 'string', 'max:250'],
        ]);
        $documento = Documento::findOrFail($d['id_documento']);
        abort_unless($documento->esVisiblePara($request->user()), 403, 'No tiene acceso a este documento.');

        $solicitud = $this->prestamos->solicitar($documento, $request->user(), $d['motivo'] ?? null);

        return response()->json($solicitud->load(self::RELACIONES), 201);
    }

    public function resolver(Request $request, SolicitudPrestamo $solicitud): JsonResponse
    {
        $d = $request->validate([
            'decision' => ['required', Rule::in(['aprobar', 'rechazar'])],
            'observacion' => ['nullable', 'string', 'max:250'],
        ]);
        $resuelta = $this->prestamos->resolver($solicitud, $request->user(), $d['decision'] === 'aprobar', $d['observacion'] ?? null);

        return response()->json($resuelta->load(self::RELACIONES));
    }
}
