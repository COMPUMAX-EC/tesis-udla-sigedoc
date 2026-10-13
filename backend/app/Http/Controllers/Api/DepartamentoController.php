<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Departamento;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * RF-01.4 Gestionar departamentos. Lectura para cualquier usuario autenticado; escritura solo Administrador.
 */
class DepartamentoController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $q = Departamento::query()->orderBy('nombre');
        if ($request->boolean('solo_activos')) {
            $q->where('estado', true);
        }

        return response()->json($q->get());
    }

    public function show(Departamento $registro): JsonResponse
    {
        return response()->json($registro);
    }

    public function store(Request $request): JsonResponse
    {
        return response()->json(Departamento::create($this->validar($request)), 201);
    }

    public function update(Request $request, Departamento $registro): JsonResponse
    {
        $registro->update($this->validar($request, $registro));

        return response()->json($registro);
    }

    /** Desactivar: los catálogos no se eliminan porque otros registros los referencian. */
    public function destroy(Departamento $registro): JsonResponse
    {
        $registro->update(['estado' => false]);

        return response()->json($registro);
    }

    private function validar(Request $request, ?Departamento $m = null): array
    {
        $id = $m?->id_departamento;

        return $request->validate([
            'nombre' => [$m ? 'sometimes' : 'required', 'string', 'max:100', Rule::unique('departamento', 'nombre')->ignore($id, 'id_departamento')],
            'descripcion' => ['nullable', 'string', 'max:200'],
            'estado' => ['sometimes', 'boolean'],
        ]);
    }
}
