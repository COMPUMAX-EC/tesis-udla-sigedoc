<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rol;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * RF-01.3 Gestionar roles. Lectura para cualquier usuario autenticado; escritura solo Administrador.
 */
class RolController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $q = Rol::query()->orderBy('nombre');
        if ($request->boolean('solo_activos')) {
            $q->where('estado', true);
        }

        return response()->json($q->get());
    }

    public function show(Rol $registro): JsonResponse
    {
        return response()->json($registro);
    }

    public function store(Request $request): JsonResponse
    {
        return response()->json(Rol::create($this->validar($request)), 201);
    }

    public function update(Request $request, Rol $registro): JsonResponse
    {
        $registro->update($this->validar($request, $registro));

        return response()->json($registro);
    }

    /** Desactivar: los catálogos no se eliminan porque otros registros los referencian. */
    public function destroy(Rol $registro): JsonResponse
    {
        if ($registro->nombre === \App\Models\Usuario::ROL_ADMINISTRADOR) {
            return response()->json(['message' => 'El rol Administrador no puede desactivarse.'], 422);
        }
        $registro->update(['estado' => false]);

        return response()->json($registro);
    }

    private function validar(Request $request, ?Rol $m = null): array
    {
        $id = $m?->id_rol;

        return $request->validate([
            'nombre' => [$m ? 'sometimes' : 'required', 'string', 'max:50', Rule::unique('rol', 'nombre')->ignore($id, 'id_rol')],
            'descripcion' => ['nullable', 'string', 'max:200'],
            'estado' => ['sometimes', 'boolean'],
        ]);
    }
}
