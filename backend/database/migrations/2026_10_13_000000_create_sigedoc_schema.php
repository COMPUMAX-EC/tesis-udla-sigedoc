<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Modelo físico de SIGEDOC — docs/diccionario-datos.md (Tesis VHQP V1.8, Tablas 33–46).
 * Las restricciones CHECK refuerzan en la base de datos las reglas de estado (RNF-04).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rol', function (Blueprint $t) {
            $t->id('id_rol');
            $t->string('nombre', 50)->unique();
            $t->string('descripcion', 200)->nullable();
            $t->boolean('estado')->default(true);
        });

        Schema::create('departamento', function (Blueprint $t) {
            $t->id('id_departamento');
            $t->string('nombre', 100)->unique();
            $t->string('descripcion', 200)->nullable();
            $t->boolean('estado')->default(true);
        });

        Schema::create('usuario', function (Blueprint $t) {
            $t->id('id_usuario');
            $t->foreignId('id_rol')->constrained('rol', 'id_rol');
            $t->foreignId('id_departamento')->nullable()->constrained('departamento', 'id_departamento');
            $t->string('nombres', 100);
            $t->string('apellidos', 100);
            $t->string('correo', 150)->unique();
            $t->string('nombre_usuario', 50)->unique();
            $t->string('clave_hash', 255);
            $t->boolean('estado')->default(true);
            $t->timestamp('fecha_creacion')->useCurrent();
            $t->timestamp('ultimo_acceso')->nullable();
        });

        Schema::create('tipo_documental', function (Blueprint $t) {
            $t->id('id_tipo_documental');
            $t->foreignId('id_departamento')->constrained('departamento', 'id_departamento');
            $t->string('nombre', 100);
            $t->string('descripcion', 200)->nullable();
            $t->boolean('estado')->default(true);
            $t->unique(['id_departamento', 'nombre']);
        });

        Schema::create('categoria', function (Blueprint $t) {
            $t->id('id_categoria');
            $t->string('nombre', 100)->unique();
            $t->string('descripcion', 250)->nullable();
            $t->boolean('estado')->default(true);
        });

        Schema::create('ubicacion', function (Blueprint $t) {
            $t->id('id_ubicacion');
            $t->string('area', 100);
            $t->string('archivador', 50)->nullable();
            $t->string('estante', 50)->nullable();
            $t->string('seccion', 50)->nullable();
            $t->string('caja', 50)->nullable();
            $t->string('descripcion', 250)->nullable();
            $t->boolean('estado')->default(true);
        });

        Schema::create('documento', function (Blueprint $t) {
            $t->id('id_documento');
            $t->foreignId('id_categoria')->nullable()->constrained('categoria', 'id_categoria');
            $t->foreignId('id_tipo_documental')->constrained('tipo_documental', 'id_tipo_documental');
            $t->foreignId('id_ubicacion')->nullable()->constrained('ubicacion', 'id_ubicacion');
            $t->foreignId('creado_por')->constrained('usuario', 'id_usuario');
            $t->string('codigo_documental', 50)->unique(); // RN-01
            $t->string('titulo', 200);
            $t->text('descripcion')->nullable();
            $t->date('fecha_documento')->nullable();
            $t->string('nivel_acceso', 30)->default('interno');
            $t->string('estado', 30)->default('disponible');
            $t->timestamp('fecha_registro')->useCurrent();
            $t->timestamp('fecha_actualizacion')->useCurrent();
        });

        Schema::create('codigo_qr', function (Blueprint $t) {
            $t->id('id_qr');
            $t->foreignId('id_documento')->unique()->constrained('documento', 'id_documento'); // RN-02
            $t->uuid('identificador')->unique();
            $t->string('contenido', 500);
            $t->string('ruta_imagen', 500)->nullable();
            $t->timestamp('fecha_generacion')->useCurrent();
            $t->boolean('estado')->default(true);
        });

        Schema::create('archivo_digital', function (Blueprint $t) {
            $t->id('id_archivo');
            $t->foreignId('id_documento')->constrained('documento', 'id_documento');
            $t->string('nombre_archivo', 200);
            $t->string('ruta_archivo', 500);
            $t->string('tipo_mime', 100)->nullable();
            $t->bigInteger('tamano_bytes')->nullable();
            $t->foreignId('subido_por')->constrained('usuario', 'id_usuario');
            $t->timestamp('fecha_carga')->useCurrent();
        });

        Schema::create('solicitud_prestamo', function (Blueprint $t) {
            $t->id('id_solicitud');
            $t->foreignId('id_documento')->constrained('documento', 'id_documento');
            $t->foreignId('id_solicitante')->constrained('usuario', 'id_usuario');
            $t->timestamp('fecha_solicitud')->useCurrent();
            $t->string('motivo', 250)->nullable();
            $t->string('estado', 20)->default('pendiente');
            $t->string('observacion', 250)->nullable();
        });

        Schema::create('prestamo', function (Blueprint $t) {
            $t->id('id_prestamo');
            $t->foreignId('id_documento')->constrained('documento', 'id_documento');
            $t->foreignId('id_solicitud')->nullable()->constrained('solicitud_prestamo', 'id_solicitud');
            $t->foreignId('entregado_por')->constrained('usuario', 'id_usuario');
            $t->foreignId('recibido_por')->constrained('usuario', 'id_usuario');
            $t->timestamp('fecha_entrega')->useCurrent();
            $t->timestamp('fecha_devolucion_prevista');
            $t->timestamp('fecha_devolucion_real')->nullable();
            $t->string('observacion', 250)->nullable();
            $t->string('estado', 20)->default('activo');
        });

        Schema::create('movimiento', function (Blueprint $t) {
            $t->id('id_movimiento');
            $t->foreignId('id_documento')->constrained('documento', 'id_documento');
            $t->foreignId('id_usuario')->constrained('usuario', 'id_usuario');
            $t->foreignId('id_prestamo')->nullable()->constrained('prestamo', 'id_prestamo');
            $t->string('tipo_movimiento', 50);
            $t->string('descripcion', 250)->nullable();
            $t->string('estado_anterior', 20)->nullable();
            $t->string('estado_nuevo', 20)->nullable();
            $t->timestamp('fecha_movimiento')->useCurrent();
            $t->string('direccion_ip', 45)->nullable();
        });

        DB::statement("ALTER TABLE documento ADD CONSTRAINT documento_estado_chk CHECK (estado IN ('disponible','prestado','de_baja'))");
        DB::statement("ALTER TABLE solicitud_prestamo ADD CONSTRAINT solicitud_estado_chk CHECK (estado IN ('pendiente','aprobada','rechazada'))");
        DB::statement("ALTER TABLE prestamo ADD CONSTRAINT prestamo_estado_chk CHECK (estado IN ('activo','devuelto','vencido'))");
        // RN-04: un documento no puede tener más de un préstamo activo a la vez.
        DB::statement("CREATE UNIQUE INDEX prestamo_activo_unico ON prestamo (id_documento) WHERE estado = 'activo'");
    }

    public function down(): void
    {
        foreach (['movimiento', 'prestamo', 'solicitud_prestamo', 'archivo_digital', 'codigo_qr', 'documento',
            'ubicacion', 'categoria', 'tipo_documental', 'usuario', 'departamento', 'rol'] as $tabla) {
            Schema::dropIfExists($tabla);
        }
    }
};
