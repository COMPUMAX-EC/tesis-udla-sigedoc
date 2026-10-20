<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Usuario;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * RF-01.2 Gestionar usuarios (crear, consultar, modificar, desactivar). Solo Administrador.
 */
class UsuarioController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $q = Usuario::with('rol', 'departamento')->orderBy('apellidos');
        if ($buscar = $request->query('buscar')) {
            $q->where(fn ($w) => $w->whereRaw('nombres ILIKE ?', ["%$buscar%"])
                ->orWhereRaw('apellidos ILIKE ?', ["%$buscar%"])
                ->orWhereRaw('nombre_usuario ILIKE ?', ["%$buscar%"])
                ->orWhereRaw('correo ILIKE ?', ["%$buscar%"]));
        }

        return response()->json($q->get());
    }

    /** Directorio de usuarios activos para elegir al receptor de un préstamo (Responsable del archivo). */
    public function directorio(Request $request): JsonResponse
    {
        $q = Usuario::with('departamento:id_departamento,nombre')
            ->where('estado', true)
            ->whereHas('rol', fn ($r) => $r->where('nombre', '!=', Usuario::ROL_ADMINISTRADOR))
            ->orderBy('apellidos')->orderBy('nombres');
        if ($buscar = $request->query('buscar')) {
            $q->whereRaw("(nombres || ' ' || apellidos) ILIKE ?", ["%$buscar%"]);
        }

        return response()->json($q->get(['id_usuario', 'nombres', 'apellidos', 'id_departamento']));
    }

    public function show(Usuario $usuario): JsonResponse
    {
        return response()->json($usuario->load('rol', 'departamento'));
    }

    public function store(Request $request): JsonResponse
    {
        $datos = $this->validar($request);
        $datos['clave_hash'] = $datos['clave'];
        unset($datos['clave']);

        return response()->json(Usuario::create($datos)->load('rol', 'departamento'), 201);
    }

    public function update(Request $request, Usuario $usuario): JsonResponse
    {
        $datos = $this->validar($request, $usuario);
        if (! empty($datos['clave'])) {
            $datos['clave_hash'] = $datos['clave'];
        }
        unset($datos['clave']);
        if ($usuario->is($request->user()) && array_key_exists('estado', $datos) && ! $datos['estado']) {
            return response()->json(['message' => 'No puede desactivar su propio usuario.'], 422);
        }
        $usuario->update($datos);
        if (! $usuario->estado) {
            $usuario->tokens()->delete();
        }

        return response()->json($usuario->load('rol', 'departamento'));
    }

    /** Desactivar (no se elimina para conservar la trazabilidad). */
    public function destroy(Request $request, Usuario $usuario): JsonResponse
    {
        if ($usuario->is($request->user())) {
            return response()->json(['message' => 'No puede desactivar su propio usuario.'], 422);
        }
        $usuario->update(['estado' => false]);
        $usuario->tokens()->delete();

        return response()->json($usuario->load('rol', 'departamento'));
    }

    private function validar(Request $request, ?Usuario $usuario = null): array
    {
        $id = $usuario?->id_usuario;

        return $request->validate([
            'id_rol' => [$usuario ? 'sometimes' : 'required', 'exists:rol,id_rol'],
            'id_departamento' => ['nullable', 'exists:departamento,id_departamento'],
            'nombres' => [$usuario ? 'sometimes' : 'required', 'string', 'max:100'],
            'apellidos' => [$usuario ? 'sometimes' : 'required', 'string', 'max:100'],
            'correo' => [$usuario ? 'sometimes' : 'required', 'email', 'max:150', Rule::unique('usuario', 'correo')->ignore($id, 'id_usuario')],
            'nombre_usuario' => [$usuario ? 'sometimes' : 'required', 'string', 'max:50', 'alpha_dash', Rule::unique('usuario', 'nombre_usuario')->ignore($id, 'id_usuario')],
            'clave' => [$usuario ? 'nullable' : 'required', 'string', 'min:8'],
            'estado' => ['sometimes', 'boolean'],
        ]);
    }
}
