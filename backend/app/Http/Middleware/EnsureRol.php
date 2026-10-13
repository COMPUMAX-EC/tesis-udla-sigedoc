<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Autorización por rol (RNF-01). Uso en rutas: ->middleware('rol:Administrador').
 */
class EnsureRol
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        if (! $request->user()?->tieneRol(...$roles)) {
            return response()->json(['message' => 'No tiene permisos para esta acción.'], 403);
        }

        return $next($request);
    }
}
