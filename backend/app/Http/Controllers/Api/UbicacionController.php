<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ubicacion;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** RF-02.3 Ubicaciones físicas del archivo. Lectura para todos; escritura Responsable del archivo y Administrador. */
class UbicacionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $q = Ubicacion::query()->orderBy('area')->orderBy('archivador')->orderBy('estante')->orderBy('caja');
        if ($request->boolean('solo_activos')) {
            $q->where('estado', true);
        }
        if ($buscar = $request->query('buscar')) {
            $q->where(fn ($w) => $w->whereRaw('area ILIKE ?', ["%$buscar%"])
                ->orWhereRaw('archivador ILIKE ?', ["%$buscar%"])
                ->orWhereRaw('caja ILIKE ?', ["%$buscar%"]));
        }

        return response()->json($q->get());
    }

    public function show(Ubicacion $registro): JsonResponse
    {
        return response()->json($registro);
    }

    public function store(Request $request): JsonResponse
    {
        return response()->json(Ubicacion::create($this->validar($request)), 201);
    }

    public function update(Request $request, Ubicacion $registro): JsonResponse
    {
        $registro->update($this->validar($request, $registro));

        return response()->json($registro);
    }

    public function destroy(Ubicacion $registro): JsonResponse
    {
        $registro->update(['estado' => false]);

        return response()->json($registro);
    }

    private function validar(Request $request, ?Ubicacion $m = null): array
    {
        $r = $m ? 'sometimes' : 'required';

        return $request->validate([
            'area' => [$r, 'string', 'max:100'],
            'archivador' => ['nullable', 'string', 'max:50'],
            'estante' => ['nullable', 'string', 'max:50'],
            'seccion' => ['nullable', 'string', 'max:50'],
            'caja' => ['nullable', 'string', 'max:50'],
            'descripcion' => ['nullable', 'string', 'max:250'],
            'estado' => ['sometimes', 'boolean'],
        ]);
    }
}
