<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TipoDocumental;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * RF-01.5 Gestionar tipos documentales. Lectura para cualquier usuario autenticado; escritura solo Administrador.
 */
class TipoDocumentalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $q = TipoDocumental::with('departamento')->orderBy('nombre');
        if ($dep = $request->query('id_departamento')) {
            $q->where('id_departamento', $dep);
        }
        if ($request->boolean('solo_activos')) {
            $q->where('estado', true);
        }

        return response()->json($q->get());
    }

    public function show(TipoDocumental $registro): JsonResponse
    {
        return response()->json($registro->load('departamento'));
    }

    public function store(Request $request): JsonResponse
    {
        return response()->json(TipoDocumental::create($this->validar($request))->load('departamento'), 201);
    }

    public function update(Request $request, TipoDocumental $registro): JsonResponse
    {
        $registro->update($this->validar($request, $registro));

        return response()->json($registro->load('departamento'));
    }

    /** Desactivar: los catálogos no se eliminan porque otros registros los referencian. */
    public function destroy(TipoDocumental $registro): JsonResponse
    {
        $registro->update(['estado' => false]);

        return response()->json($registro->load('departamento'));
    }

    private function validar(Request $request, ?TipoDocumental $m = null): array
    {
        $id = $m?->id_tipo_documental;

        return $request->validate([
            'id_departamento' => [$m ? 'sometimes' : 'required', 'exists:departamento,id_departamento'],
            'nombre' => [$m ? 'sometimes' : 'required', 'string', 'max:100',
                Rule::unique('tipo_documental', 'nombre')
                    ->where('id_departamento', $request->input('id_departamento', $m?->id_departamento))
                    ->ignore($id, 'id_tipo_documental')],
            'descripcion' => ['nullable', 'string', 'max:200'],
            'estado' => ['sometimes', 'boolean'],
        ]);
    }
}
