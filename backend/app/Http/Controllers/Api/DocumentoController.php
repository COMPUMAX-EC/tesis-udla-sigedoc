<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Documento;
use App\Models\TipoDocumental;
use App\Models\Ubicacion;
use App\Services\CodigoDocumental;
use App\Services\GestorQr;
use App\Services\Trazabilidad;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

/**
 * M02 Gestión documental (RF-02.1 a RF-02.5) y consultas de trazabilidad (RF-05.2, RF-05.3).
 */
class DocumentoController extends Controller
{
    private const RELACIONES = ['tipoDocumental.departamento', 'categoria', 'ubicacion', 'qr:id_qr,id_documento,identificador,estado'];

    /** RF-02.5 Consultar documentos con filtros y paginación. */
    public function index(Request $request): JsonResponse
    {
        $f = $request->validate([
            'buscar' => ['nullable', 'string', 'max:100'],
            'id_departamento' => ['nullable', 'integer'],
            'id_tipo_documental' => ['nullable', 'integer'],
            'id_categoria' => ['nullable', 'integer'],
            'id_ubicacion' => ['nullable', 'integer'],
            'estado' => ['nullable', Rule::in([Documento::DISPONIBLE, Documento::PRESTADO, Documento::DE_BAJA])],
            'nivel_acceso' => ['nullable', Rule::in(Documento::NIVELES_ACCESO)],
            'desde' => ['nullable', 'date'],
            'hasta' => ['nullable', 'date'],
            'orden' => ['nullable', Rule::in(['recientes', 'codigo', 'titulo', 'fecha'])],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $q = Documento::query()->visiblePara($request->user())->with(self::RELACIONES);

        if ($b = $f['buscar'] ?? null) {
            $q->where(fn ($w) => $w->whereRaw('titulo ILIKE ?', ["%$b%"])
                ->orWhereRaw('codigo_documental ILIKE ?', ["%$b%"])
                ->orWhereRaw('descripcion ILIKE ?', ["%$b%"]));
        }
        if ($id = $f['id_departamento'] ?? null) {
            $q->whereHas('tipoDocumental', fn ($t) => $t->where('id_departamento', $id));
        }
        foreach (['id_tipo_documental', 'id_categoria', 'id_ubicacion', 'estado', 'nivel_acceso'] as $campo) {
            if (isset($f[$campo])) {
                $q->where($campo, $f[$campo]);
            }
        }
        if (isset($f['desde'])) {
            $q->whereDate('fecha_documento', '>=', $f['desde']);
        }
        if (isset($f['hasta'])) {
            $q->whereDate('fecha_documento', '<=', $f['hasta']);
        }

        match ($f['orden'] ?? 'recientes') {
            'codigo' => $q->orderBy('codigo_documental'),
            'titulo' => $q->orderBy('titulo'),
            'fecha' => $q->orderByDesc('fecha_documento')->orderByDesc('id_documento'),
            default => $q->orderByDesc('fecha_registro')->orderByDesc('id_documento'),
        };

        return response()->json($q->paginate($f['per_page'] ?? 15));
    }

    public function show(Request $request, Documento $documento): JsonResponse
    {
        $this->autorizarVisibilidad($request, $documento);
        $documento->load([...self::RELACIONES, 'creador:id_usuario,nombres,apellidos', 'archivos.subidoPor:id_usuario,nombres,apellidos']);

        $esFuncionario = $request->user()->tieneRol('Funcionario departamental');
        $activo = $documento->prestamoActivo()->with('recibidoPor:id_usuario,nombres,apellidos,id_departamento')->first();
        // El funcionario solo sabe si el documento está prestado, no quién lo tiene.
        $datos = $documento->toArray();
        $datos['prestamo_activo'] = $esFuncionario ? ($activo ? ['en_mora' => $activo->en_mora] : null) : $activo;

        return response()->json($datos);
    }

    /** RF-02.1 Registrar · RF-02.2 Clasificar · RF-02.3 Ubicar · RF-03.1/03.2 genera identificador y QR. */
    public function store(Request $request): JsonResponse
    {
        $d = $this->validar($request);

        $documento = DB::transaction(function () use ($request, $d) {
            $tipo = TipoDocumental::with('departamento')->findOrFail($d['id_tipo_documental']);
            $this->exigirActivos($d);

            $documento = Documento::create([
                ...$d,
                'creado_por' => $request->user()->id_usuario,
                'codigo_documental' => CodigoDocumental::siguiente($tipo, isset($d['fecha_documento']) ? Carbon::parse($d['fecha_documento']) : null),
                'nivel_acceso' => $d['nivel_acceso'] ?? 'interno',
                'estado' => Documento::DISPONIBLE,
                'fecha_registro' => now(),
                'fecha_actualizacion' => now(),
            ]);
            Trazabilidad::registrar($documento, $request->user(), Trazabilidad::REGISTRO, "Registrado como {$documento->codigo_documental}", null, Documento::DISPONIBLE);
            GestorQr::generar($documento);
            Trazabilidad::registrar($documento, $request->user(), Trazabilidad::QR_GENERADO, 'Código QR generado');

            return $documento;
        });

        return response()->json($documento->load(self::RELACIONES), 201);
    }

    /** RF-02.4 Actualizar documento. El estado solo cambia por préstamo/devolución o baja. */
    public function update(Request $request, Documento $documento): JsonResponse
    {
        $d = $this->validar($request, $documento);
        $this->exigirActivos($d, $documento);

        DB::transaction(function () use ($request, $documento, $d) {
            $documento = Documento::lockForUpdate()->findOrFail($documento->id_documento);
            $ubicacionAnterior = $documento->id_ubicacion;
            $documento->fill($d)->fill(['fecha_actualizacion' => now()])->save();

            if (array_key_exists('id_ubicacion', $d) && (int) $d['id_ubicacion'] !== (int) $ubicacionAnterior) {
                $antes = $ubicacionAnterior ? Ubicacion::find($ubicacionAnterior)?->etiqueta : 'sin ubicación';
                $ahora = $d['id_ubicacion'] ? Ubicacion::find($d['id_ubicacion'])?->etiqueta : 'sin ubicación';
                Trazabilidad::registrar($documento, $request->user(), Trazabilidad::CAMBIO_UBICACION, "De «{$antes}» a «{$ahora}»");
            } else {
                Trazabilidad::registrar($documento, $request->user(), Trazabilidad::ACTUALIZACION, 'Datos del documento actualizados');
            }
        });

        return response()->json($documento->fresh()->load(self::RELACIONES));
    }

    /** Dar de baja: el documento no se elimina para conservar el historial (RN-06). */
    public function destroy(Request $request, Documento $documento): JsonResponse
    {
        if ($documento->estado === Documento::PRESTADO) {
            throw ValidationException::withMessages(['estado' => 'No se puede dar de baja un documento prestado.']);
        }
        $anterior = $documento->estado;
        $documento->update(['estado' => Documento::DE_BAJA, 'fecha_actualizacion' => now()]);
        Trazabilidad::registrar($documento, $request->user(), Trazabilidad::BAJA, 'Documento dado de baja', $anterior, Documento::DE_BAJA);

        return response()->json($documento->load(self::RELACIONES));
    }

    public function reactivar(Request $request, Documento $documento): JsonResponse
    {
        if ($documento->estado !== Documento::DE_BAJA) {
            throw ValidationException::withMessages(['estado' => 'El documento no está dado de baja.']);
        }
        $documento->update(['estado' => Documento::DISPONIBLE, 'fecha_actualizacion' => now()]);
        Trazabilidad::registrar($documento, $request->user(), Trazabilidad::REACTIVACION, 'Documento reactivado', Documento::DE_BAJA, Documento::DISPONIBLE);

        return response()->json($documento->load(self::RELACIONES));
    }

    /** RF-05.3 Consultar ubicación física actual. */
    public function ubicacion(Request $request, Documento $documento): JsonResponse
    {
        $this->autorizarVisibilidad($request, $documento);
        $documento->load('ubicacion');

        return response()->json([
            'id_documento' => $documento->id_documento,
            'codigo_documental' => $documento->codigo_documental,
            'titulo' => $documento->titulo,
            'estado' => $documento->estado,
            'ubicacion' => $documento->ubicacion,
        ]);
    }

    /** RF-05.2 Historial de movimientos del documento (más reciente primero). */
    public function historial(Documento $documento): JsonResponse
    {
        return response()->json(
            $documento->movimientos()->with('usuario:id_usuario,nombres,apellidos')
                ->orderByDesc('fecha_movimiento')->orderByDesc('id_movimiento')->get()
        );
    }

    /** RF-05.2 Historial de préstamos y devoluciones del documento. */
    public function prestamos(Documento $documento): JsonResponse
    {
        return response()->json(
            $documento->prestamos()->with(['recibidoPor:id_usuario,nombres,apellidos,id_departamento', 'entregadoPor:id_usuario,nombres,apellidos'])
                ->orderByDesc('fecha_entrega')->get()
        );
    }

    private function autorizarVisibilidad(Request $request, Documento $documento): void
    {
        if (! $documento->esVisiblePara($request->user())) {
            abort(403, 'No tiene acceso a este documento.');
        }
    }

    private function validar(Request $request, ?Documento $m = null): array
    {
        $r = $m ? 'sometimes' : 'required';

        return $request->validate([
            'id_tipo_documental' => [$r, 'exists:tipo_documental,id_tipo_documental'],
            'id_categoria' => ['nullable', 'exists:categoria,id_categoria'],
            'id_ubicacion' => ['nullable', 'exists:ubicacion,id_ubicacion'],
            'titulo' => [$r, 'string', 'max:200'],
            'descripcion' => ['nullable', 'string', 'max:5000'],
            'fecha_documento' => ['nullable', 'date', 'before_or_equal:today'],
            'nivel_acceso' => ['sometimes', Rule::in(Documento::NIVELES_ACCESO)],
        ]);
    }

    /** No se pueden asignar catálogos desactivados a un documento (salvo que ya los tuviera). */
    private function exigirActivos(array $d, ?Documento $actual = null): void
    {
        $revisiones = [
            'id_tipo_documental' => [TipoDocumental::class, 'tipo documental'],
            'id_categoria' => [\App\Models\Categoria::class, 'categoría'],
            'id_ubicacion' => [Ubicacion::class, 'ubicación'],
        ];
        foreach ($revisiones as $campo => [$modelo, $nombre]) {
            $id = $d[$campo] ?? null;
            if ($id && (int) $id !== (int) ($actual?->{$campo}) && ! $modelo::whereKey($id)->where('estado', true)->exists()) {
                throw ValidationException::withMessages([$campo => "La $nombre seleccionada está desactivada."]);
            }
        }
    }
}
