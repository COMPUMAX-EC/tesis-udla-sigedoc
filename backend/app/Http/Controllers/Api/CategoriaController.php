<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Categoria;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** Categorías documentales (RF-02.2). Lectura para todos; escritura Administrador y Responsable del archivo. */
class CategoriaController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $q = Categoria::query()->orderBy('nombre');
        if ($request->boolean('solo_activos')) {
            $q->where('estado', true);
        }

        return response()->json($q->get());
    }

    public function show(Categoria $registro): JsonResponse
    {
        return response()->json($registro);
    }

    public function store(Request $request): JsonResponse
    {
        return response()->json(Categoria::create($this->validar($request)), 201);
    }

    public function update(Request $request, Categoria $registro): JsonResponse
    {
        $registro->update($this->validar($request, $registro));

        return response()->json($registro);
    }

    public function destroy(Categoria $registro): JsonResponse
    {
        $registro->update(['estado' => false]);

        return response()->json($registro);
    }

    private function validar(Request $request, ?Categoria $m = null): array
    {
        return $request->validate([
            'nombre' => [$m ? 'sometimes' : 'required', 'string', 'max:100', Rule::unique('categoria', 'nombre')->ignore($m?->id_categoria, 'id_categoria')],
            'descripcion' => ['nullable', 'string', 'max:250'],
            'estado' => ['sometimes', 'boolean'],
        ]);
    }
}
