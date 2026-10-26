<?php

namespace App\Services;

use App\Models\Documento;
use App\Models\TipoDocumental;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

/** RN-01: código institucional único por documento, con el formato SIGLA-AÑO-0001. */
class CodigoDocumental
{
    /** Siglas de departamento: "Gerencia" → GER, "Coordinación Administrativa" → CA. */
    public static function sigla(string $departamento): string
    {
        $palabras = collect(preg_split('/\s+/', Str::upper(Str::ascii($departamento))))
            ->reject(fn ($p) => in_array($p, ['DE', 'DEL', 'Y', 'LA', 'EL'], true))
            ->values();

        return $palabras->count() > 1
            ? $palabras->map(fn ($p) => $p[0])->implode('')
            : mb_substr($palabras->first() ?? 'DOC', 0, 3);
    }

    /** Debe invocarse dentro de la transacción que crea el documento. */
    public static function siguiente(TipoDocumental $tipo, ?Carbon $fecha = null): string
    {
        $prefijo = sprintf('%s-%d-', self::sigla($tipo->departamento->nombre), ($fecha ?? now())->year);

        $ultimo = Documento::where('codigo_documental', 'like', $prefijo.'%')
            ->lockForUpdate()
            ->pluck('codigo_documental')
            ->map(fn ($c) => (int) substr($c, strlen($prefijo)))
            ->max() ?? 0;

        return $prefijo.str_pad((string) ($ultimo + 1), 4, '0', STR_PAD_LEFT);
    }
}
