<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Usuario;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * RF-01.1 Iniciar sesión. Tokens Sanctum por dispositivo.
 */
class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $datos = $request->validate([
            'usuario' => ['required', 'string'],
            'clave' => ['required', 'string'],
            'dispositivo' => ['nullable', 'string', 'max:100'],
        ]);

        $usuario = Usuario::with('rol', 'departamento')
            ->where('nombre_usuario', $datos['usuario'])
            ->orWhere('correo', $datos['usuario'])
            ->first();

        if (! $usuario || ! Hash::check($datos['clave'], $usuario->clave_hash)) {
            throw ValidationException::withMessages(['usuario' => 'Usuario o contraseña incorrectos.']);
        }
        if (! $usuario->estado || ! $usuario->rol?->estado) {
            throw ValidationException::withMessages(['usuario' => 'El usuario está desactivado.']);
        }

        $usuario->forceFill(['ultimo_acceso' => now()])->save();
        $token = $usuario->createToken($datos['dispositivo'] ?? 'web')->plainTextToken;

        return response()->json(['token' => $token, 'usuario' => $usuario]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json($request->user()->load('rol', 'departamento'));
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Sesión cerrada.']);
    }
}
