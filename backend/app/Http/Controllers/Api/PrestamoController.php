<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Documento;
use App\Models\Prestamo;
use App\Models\SolicitudPrestamo;
use App\Models\Usuario;
use App\Services\PrestamoService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

/** RF-04.3 Registrar préstamo · RF-04.4 Registrar devolución · RF-04.5 Registrar observación. */
class PrestamoController extends Controller
{
    public function __construct(private PrestamoService $servicio) {}

    private const RELACIONES = ['documento.tipoDocumental.departamento', 'documento.ubicacion', 'recibidoPor:id_usuario,nombres,apellidos,id_departamento', 'recibidoPor.departamento', 'entregadoPor:id_usuario,nombres,apellidos'];

    public function index(Request $request): JsonResponse
    {
        $f = $request->validate([
            'estado' => ['nullable', Rule::in([Prestamo::ACTIVO, Prestamo::DEVUELTO])],
            'en_mora' => ['nullable', 'boolean'],
            'id_documento' => ['nullable', 'integer'],
            'buscar' => ['nullable', 'string', 'max:100'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $q = Prestamo::with(self::RELACIONES)->orderByDesc('fecha_entrega');
        if (! $request->user()->tieneRol(Usuario::ROL_RESPONSABLE, Usuario::ROL_ADMINISTRADOR)) {
            $q->where('recibido_por', $request->user()->id_usuario);
        }
        if (isset($f['estado'])) {
            $q->where('estado', $f['estado']);
        }
        if ($request->boolean('en_mora')) {
            $q->where('estado', Prestamo::ACTIVO)->where('fecha_devolucion_prevista', '<', now());
        }
        if (isset($f['id_documento'])) {
            $q->where('id_documento', $f['id_documento']);
        }
        if ($b = $f['buscar'] ?? null) {
            $q->where(fn ($w) => $w->whereHas('documento', fn ($d) => $d->whereRaw('titulo ILIKE ?', ["%$b%"])->orWhereRaw('codigo_documental ILIKE ?', ["%$b%"]))
                ->orWhereHas('recibidoPor', fn ($u) => $u->whereRaw("(nombres || ' ' || apellidos) ILIKE ?", ["%$b%"])));
        }

        return response()->json($q->paginate($f['per_page'] ?? 20));
    }

    public function show(Request $request, Prestamo $prestamo): JsonResponse
    {
        abort_unless(
            $request->user()->tieneRol(Usuario::ROL_RESPONSABLE, Usuario::ROL_ADMINISTRADOR) || $prestamo->recibido_por === $request->user()->id_usuario,
            403,
            'No tiene permisos para esta acción.'
        );

        return response()->json($prestamo->load(self::RELACIONES));
    }

    public function store(Request $request): JsonResponse
    {
        $d = $request->validate([
            'id_documento' => ['required', 'exists:documento,id_documento'],
            'id_receptor' => ['required', 'exists:usuario,id_usuario'],
            'id_solicitud' => ['nullable', 'exists:solicitud_prestamo,id_solicitud'],
            'fecha_devolucion_prevista' => ['required', 'date', 'after_or_equal:today'],
            'observacion' => ['nullable', 'string', 'max:250'],
        ]);

        $prestamo = $this->servicio->entregar(
            Documento::findOrFail($d['id_documento']),
            $request->user(),
            Usuario::findOrFail($d['id_receptor']),
            Carbon::parse($d['fecha_devolucion_prevista'])->endOfDay(),
            $d['observacion'] ?? null,
            isset($d['id_solicitud']) ? SolicitudPrestamo::findOrFail($d['id_solicitud']) : null,
        );

        return response()->json($prestamo->load(self::RELACIONES), 201);
    }

    public function devolver(Request $request, Prestamo $prestamo): JsonResponse
    {
        $d = $request->validate(['observacion' => ['nullable', 'string', 'max:250']]);

        return response()->json(
            $this->servicio->devolver($prestamo, $request->user(), $d['observacion'] ?? null)->load(self::RELACIONES)
        );
    }
}
