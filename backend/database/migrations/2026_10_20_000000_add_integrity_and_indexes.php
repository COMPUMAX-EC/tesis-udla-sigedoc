<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Refuerzos de integridad (RNF-04, RN-06) e índices de consulta (RNF-02).
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement("ALTER TABLE documento ADD CONSTRAINT documento_nivel_acceso_chk CHECK (nivel_acceso IN ('publico','interno','confidencial'))");

        // RN-06: el historial no puede modificarse ni eliminarse, ni siquiera desde la base de datos.
        DB::unprepared(<<<'SQL'
CREATE FUNCTION movimiento_inmutable() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'El historial de movimientos no puede modificarse ni eliminarse (RN-06)';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER movimiento_sin_cambios
    BEFORE UPDATE OR DELETE ON movimiento
    FOR EACH ROW EXECUTE FUNCTION movimiento_inmutable();

CREATE FUNCTION prestamo_no_eliminable() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'El historial de préstamos y solicitudes no puede eliminarse (RN-06)';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prestamo_sin_eliminar BEFORE DELETE ON prestamo
    FOR EACH ROW EXECUTE FUNCTION prestamo_no_eliminable();
CREATE TRIGGER solicitud_sin_eliminar BEFORE DELETE ON solicitud_prestamo
    FOR EACH ROW EXECUTE FUNCTION prestamo_no_eliminable();
SQL);

        DB::statement('CREATE INDEX documento_estado_idx ON documento (estado)');
        DB::statement('CREATE INDEX documento_tipo_idx ON documento (id_tipo_documental)');
        DB::statement('CREATE INDEX documento_fecha_idx ON documento (fecha_documento)');
        DB::statement('CREATE INDEX movimiento_documento_fecha_idx ON movimiento (id_documento, fecha_movimiento DESC)');
        DB::statement('CREATE INDEX movimiento_fecha_idx ON movimiento (fecha_movimiento DESC)');
        DB::statement('CREATE INDEX prestamo_estado_idx ON prestamo (estado, fecha_devolucion_prevista)');
        DB::statement('CREATE INDEX solicitud_estado_idx ON solicitud_prestamo (estado)');
    }

    public function down(): void
    {
        DB::unprepared(<<<'SQL'
DROP TRIGGER IF EXISTS solicitud_sin_eliminar ON solicitud_prestamo;
DROP TRIGGER IF EXISTS prestamo_sin_eliminar ON prestamo;
DROP TRIGGER IF EXISTS movimiento_sin_cambios ON movimiento;
DROP FUNCTION IF EXISTS prestamo_no_eliminable();
DROP FUNCTION IF EXISTS movimiento_inmutable();
DROP INDEX IF EXISTS solicitud_estado_idx, prestamo_estado_idx, movimiento_fecha_idx,
    movimiento_documento_fecha_idx, documento_fecha_idx, documento_tipo_idx, documento_estado_idx;
ALTER TABLE documento DROP CONSTRAINT IF EXISTS documento_nivel_acceso_chk;
SQL);
    }
};
