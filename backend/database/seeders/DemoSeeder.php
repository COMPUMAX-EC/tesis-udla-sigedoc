<?php

namespace Database\Seeders;

use App\Models\Categoria;
use App\Models\CodigoQr;
use App\Models\Departamento;
use App\Models\Documento;
use App\Models\Movimiento;
use App\Models\Prestamo;
use App\Models\Rol;
use App\Models\SolicitudPrestamo;
use App\Models\TipoDocumental;
use App\Models\Ubicacion;
use App\Models\Usuario;
use App\Services\CodigoDocumental;
use App\Services\GestorQr;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * DATOS SINTÉTICOS DE DEMOSTRACIÓN. Ningún registro, persona, contrato ni cifra corresponde a la
 * empresa real: son datos generados (deterministas, semilla fija) para mostrar el sistema con un
 * volumen y una historia verosímiles — 250 documentos, 12 préstamos activos y 3 solicitudes pendientes,
 * como en el wireframe del panel principal. Nunca deben presentarse como resultados de medición.
 *
 *   php artisan db:seed --class=DemoSeeder
 */
class DemoSeeder extends Seeder
{
    private const TOTAL_DOCUMENTOS = 250;

    private const PERSONAS = [
        'Gerencia' => [['Marco', 'Aguirre Jaramillo'], ['Lucía', 'Romero Cabrera']],
        'Financiero' => [['Andrés', 'Valarezo Ordóñez'], ['Patricia', 'Soto Armijos']],
        'Secretaría' => [['Diana', 'Maldonado Solano'], ['Kleber', 'Tapia Encalada']],
        'Coordinación Administrativa' => [['Gabriela', 'Yaguana Ríos'], ['Fernando', 'Loaiza Cueva']],
        'Jurídico' => [['Verónica', 'Salinas Pineda'], ['Esteban', 'Granda Tinoco']],
        'Tesorería' => [['Cristian', 'Bermeo Macas'], ['Jessica', 'Pogo Chamba']],
        'Talento Humano' => [['Carolina', 'Espinosa León'], ['Wilson', 'Jiménez Quizhpe']],
    ];

    private const CATEGORIAS = [
        'Correspondencia' => 'Oficios y memorandos enviados y recibidos',
        'Actas y resoluciones' => 'Actas de reunión, convocatorias y resoluciones administrativas',
        'Financiero y contable' => 'Informes financieros, facturas y comprobantes',
        'Contratos y convenios' => 'Contratación, convenios y procesos legales',
        'Talento humano' => 'Expedientes y registros del personal',
        'Gestión técnica y vial' => 'Informes y requerimientos de obras y mantenimiento vial',
    ];

    private const VIAS = ['Zamora–Yantzaza', 'Yantzaza–El Pangui', 'Zamora–Cumbaratza', 'Paquisha–Nuevo Quito', 'Guadalupe–Los Encuentros', 'Centinela del Cóndor–Zumbi', 'Palanda–Valladolid', 'Chicaña–Yantzaza', 'El Pangui–Tundayme', 'Zamora–Timbara'];

    private const CONTRATISTAS = ['Consorcio Vial Nangaritza', 'Constructora Cóndor Mirador S.A.', 'Ingeniería y Obras Chinchipe Cía. Ltda.', 'Maquinarias del Sur Cía. Ltda.', 'Servicios Viales Bombuscaro S.A.'];

    /** Asuntos de oficios y memorandos por departamento. */
    private const ASUNTOS = [
        'Gerencia' => ['Disposición de mantenimiento rutinario en la vía {via}', 'Solicitud de informe sobre el estado de la maquinaria pesada', 'Convocatoria a reunión de coordinación con los GAD parroquiales', 'Remisión del plan operativo anual {anio}', 'Autorización de comisión de servicios', 'Respuesta a la solicitud de intervención en la vía {via}'],
        'Financiero' => ['Solicitud de certificación presupuestaria para mantenimiento de {via}', 'Remisión de la ejecución presupuestaria del mes de {mes}', 'Reforma al presupuesto de inversión', 'Solicitud de reposición de caja chica', 'Conciliación de cuentas por pagar a proveedores', 'Informe de saldos disponibles por partida'],
        'Secretaría' => ['Remisión de documentación para firma de Gerencia', 'Convocatoria a sesión de directorio', 'Solicitud de actualización del archivo institucional', 'Traslado de expedientes al archivo pasivo', 'Registro de correspondencia recibida en el mes de {mes}', 'Certificación de documentos del archivo'],
        'Coordinación Administrativa' => ['Requerimiento de materiales de oficina del trimestre', 'Solicitud de mantenimiento de vehículos livianos', 'Programación de uso de la flota vehicular', 'Informe de inventario de bienes de larga duración', 'Solicitud de combustible para maquinaria de la vía {via}', 'Contratación de servicio de limpieza y seguridad'],
        'Jurídico' => ['Criterio jurídico sobre la liquidación del contrato con {contratista}', 'Solicitud de documentación habilitante del proceso contractual', 'Notificación de requerimiento a {contratista}', 'Remisión de borrador de convenio interinstitucional', 'Pronunciamiento sobre recurso de reclamo administrativo', 'Revisión de pliegos del proceso de contratación'],
        'Tesorería' => ['Solicitud de pago de planilla de avance de obra a {contratista}', 'Remisión de comprobantes de pago del mes de {mes}', 'Reporte de transferencias interbancarias realizadas', 'Solicitud de devolución de garantía a {contratista}', 'Arqueo de caja chica', 'Confirmación de pagos al IESS y SRI'],
        'Talento Humano' => ['Solicitud de permiso por calamidad doméstica', 'Planificación de vacaciones del personal {anio}', 'Remisión del reporte de asistencia del mes de {mes}', 'Contratación de personal bajo código de trabajo', 'Capacitación en seguridad y salud ocupacional', 'Actualización de distributivo de remuneraciones'],
    ];

    /** Títulos de tipos documentales específicos. */
    private const TITULOS = [
        'Resolución' => ['Resolución Administrativa Nro. {num} — Adjudicación del contrato de mantenimiento de la vía {via}', 'Resolución Nro. {num} — Aprobación del plan anual de contratación {anio}', 'Resolución Nro. {num} — Declaratoria de emergencia vial en {via}', 'Resolución Nro. {num} — Delegación de atribuciones'],
        'Informe de gestión' => ['Informe de gestión del trimestre {trim} de {anio}', 'Informe de gestión de mantenimiento vial — {mes} de {anio}', 'Informe de rendición de cuentas {anio}'],
        'Informe financiero' => ['Informe financiero del mes de {mes} de {anio}', 'Estado de situación financiera al cierre de {anio}', 'Informe de ejecución presupuestaria — trimestre {trim} de {anio}'],
        'Convocatoria y acta de reunión' => ['Acta de sesión ordinaria de directorio Nro. {num}', 'Convocatoria a sesión extraordinaria Nro. {num}', 'Acta de reunión de coordinación técnica Nro. {num}'],
        'Informe administrativo' => ['Informe administrativo del trimestre {trim} de {anio}', 'Informe de inventario de bienes — {anio}', 'Informe de uso de la flota vehicular — {mes} de {anio}'],
        'Solicitud y requerimiento interno' => ['Requerimiento de repuestos para maquinaria de la vía {via}', 'Solicitud de adquisición de equipos de cómputo', 'Requerimiento de señalética vial para {via}'],
        'Informe y criterio jurídico' => ['Criterio jurídico Nro. {num} sobre prórroga de plazo contractual', 'Informe jurídico Nro. {num} sobre liquidación de contrato', 'Criterio jurídico Nro. {num} sobre convenio con GAD parroquial'],
        'Contrato y convenio' => ['Contrato de mantenimiento vial de {via} con {contratista}', 'Convenio de cooperación interinstitucional Nro. {num}', 'Contrato de arrendamiento de maquinaria con {contratista}', 'Addendum modificatorio al contrato de la vía {via}'],
        'Documento de proceso legal o administrativo' => ['Expediente de proceso de contratación Nro. {num}', 'Expediente de reclamo administrativo Nro. {num}', 'Expediente de sumario administrativo Nro. {num}'],
        'Factura y comprobante de pago' => ['Factura Nro. 001-001-{fac} — {contratista}', 'Comprobante de pago Nro. {num} — planilla de avance de obra', 'Factura Nro. 001-002-{fac} — suministros y repuestos'],
        'Comprobante y reporte de transferencia o pago' => ['Reporte de transferencias del mes de {mes} de {anio}', 'Comprobante de transferencia Nro. {num} — pago a {contratista}', 'Comprobante de pago de aportes al IESS — {mes} de {anio}'],
        'Expediente y registro del personal' => ['Expediente personal — {persona}', 'Registro de contratación — {persona}', 'Hoja de vida y respaldos — {persona}'],
        'Permiso, vacaciones y asistencia' => ['Solicitud de vacaciones — {persona}', 'Registro de permisos del mes de {mes} de {anio}', 'Reporte de asistencia — {mes} de {anio}'],
    ];

    private const CATEGORIA_POR_TIPO = [
        'Oficio' => 'Correspondencia', 'Oficio interno' => 'Correspondencia', 'Oficio externo' => 'Correspondencia', 'Memorándum' => 'Correspondencia',
        'Resolución' => 'Actas y resoluciones', 'Convocatoria y acta de reunión' => 'Actas y resoluciones',
        'Informe de gestión' => 'Gestión técnica y vial', 'Informe administrativo' => 'Gestión técnica y vial', 'Solicitud y requerimiento interno' => 'Gestión técnica y vial',
        'Informe financiero' => 'Financiero y contable', 'Factura y comprobante de pago' => 'Financiero y contable', 'Comprobante y reporte de transferencia o pago' => 'Financiero y contable',
        'Informe y criterio jurídico' => 'Contratos y convenios', 'Contrato y convenio' => 'Contratos y convenios', 'Documento de proceso legal o administrativo' => 'Contratos y convenios',
        'Expediente y registro del personal' => 'Talento humano', 'Permiso, vacaciones y asistencia' => 'Talento humano',
    ];

    private const MESES = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

    private const OBS_DEVOLUCION = [null, null, null, 'Devuelto sin novedades.', 'Devuelto sin novedades.', 'Se reorganizaron las fojas al reingresar al archivo.', 'Devuelto con una foja suelta; se volvió a foliar.', 'Devuelto con retraso por comisión de servicios.'];

    private const MOTIVOS = ['Revisión para elaboración de informe', 'Sustento de proceso de contratación', 'Consulta para respuesta a oficio', 'Verificación previa a auditoría interna', 'Revisión de antecedentes del contrato', 'Respaldo para trámite de pago', 'Actualización de expediente', 'Consulta de criterio previo'];

    /** @var array<string, Ubicacion[]> */
    private array $ubicaciones = [];

    public function run(): void
    {
        if (Documento::exists()) {
            $this->command?->warn('Ya existen documentos: DemoSeeder no se ejecuta para no duplicar datos.');

            return;
        }
        mt_srand(2026);

        $clave = config('app.demo_clave') ?: Str::password(12, symbols: false);
        $personas = $this->usuarios($clave);
        $responsable = Usuario::where('nombre_usuario', 'secretaria')->firstOrFail();
        $this->catalogos();

        DB::transaction(function () use ($personas, $responsable) {
            $documentos = $this->documentos($responsable);
            $this->historial($documentos, $personas, $responsable);
        });

        $this->command?->info('Datos de demostración creados: '.Documento::count().' documentos, '.Prestamo::count().' préstamos, '.Movimiento::count().' movimientos.');
        $this->command?->info("Usuarios de demostración creados con la clave: $clave");
    }

    /** @return Usuario[] funcionarios (sin el responsable ni el administrador) */
    private function usuarios(string $clave): array
    {
        $rol = Rol::where('nombre', Usuario::ROL_FUNCIONARIO)->firstOrFail();
        $personas = [];
        foreach (self::PERSONAS as $departamento => $gente) {
            $dep = Departamento::where('nombre', $departamento)->firstOrFail();
            foreach ($gente as [$nombres, $apellidos]) {
                $usuario = Str::lower(Str::ascii(mb_substr($nombres, 0, 1).explode(' ', $apellidos)[0]));
                $personas[] = Usuario::firstOrCreate(['nombre_usuario' => $usuario], [
                    'id_rol' => $rol->id_rol,
                    'id_departamento' => $dep->id_departamento,
                    'nombres' => $nombres,
                    'apellidos' => $apellidos,
                    'correo' => "$usuario@vialzachin.demo",
                    'clave_hash' => $clave,
                    'estado' => true,
                    'ultimo_acceso' => now()->subDays(mt_rand(0, 12))->subMinutes(mt_rand(0, 900)),
                ]);
            }
        }
        // Los usuarios iniciales del seeder base también reciben nombres verosímiles.
        Usuario::where('nombre_usuario', 'secretaria')->update(['nombres' => 'Mónica', 'apellidos' => 'Carrión Sarango']);
        Usuario::where('nombre_usuario', 'admin')->update(['nombres' => 'Administrador', 'apellidos' => 'SIGEDOC']);
        Usuario::where('nombre_usuario', 'funcionario')->update(['nombres' => 'Rafael', 'apellidos' => 'Ontaneda Vivanco']);

        return array_merge($personas, [Usuario::where('nombre_usuario', 'funcionario')->first()]);
    }

    private function catalogos(): void
    {
        foreach (self::CATEGORIAS as $nombre => $descripcion) {
            Categoria::updateOrCreate(['nombre' => $nombre], ['descripcion' => $descripcion, 'estado' => true]);
        }

        $archivadores = ['Gerencia' => 'A', 'Financiero' => 'B', 'Secretaría' => 'C', 'Coordinación Administrativa' => 'D', 'Jurídico' => 'E', 'Tesorería' => 'F', 'Talento Humano' => 'G'];
        foreach ($archivadores as $departamento => $letra) {
            foreach ([1, 2, 3] as $estante) {
                foreach ([1, 2] as $k) {
                    $caja = ($estante - 1) * 2 + $k;
                    $this->ubicaciones[$departamento][] = Ubicacion::firstOrCreate(
                        ['area' => 'Archivo general · Secretaría', 'archivador' => "$letra-01", 'estante' => (string) $estante, 'caja' => (string) $caja],
                        ['descripcion' => "Documentación de $departamento", 'estado' => true],
                    );
                }
            }
        }
        Ubicacion::firstOrCreate(['area' => 'Archivo pasivo · Bodega', 'archivador' => 'P-01', 'estante' => '1', 'caja' => '1'], ['descripcion' => 'Documentación de años anteriores', 'estado' => true]);
    }

    /** @return Documento[] */
    private function documentos(Usuario $responsable): array
    {
        // Peso por departamento: reparte los 250 documentos de forma desigual, como en un archivo real.
        $pesos = ['Gerencia' => 14, 'Financiero' => 16, 'Secretaría' => 18, 'Coordinación Administrativa' => 14, 'Jurídico' => 14, 'Tesorería' => 14, 'Talento Humano' => 10];
        $tipos = TipoDocumental::with('departamento')->get()->groupBy(fn ($t) => $t->departamento->nombre)->map->values();
        $categorias = Categoria::pluck('id_categoria', 'nombre');
        $nombresPersonas = collect(self::PERSONAS)->flatten(1)->map(fn ($p) => "$p[0] $p[1]")->all();

        $plan = [];
        foreach ($pesos as $departamento => $peso) {
            for ($i = 0; $i < (int) round(self::TOTAL_DOCUMENTOS * $peso / array_sum($pesos)); $i++) {
                $plan[] = $departamento;
            }
        }
        while (count($plan) < self::TOTAL_DOCUMENTOS) {
            $plan[] = 'Secretaría';
        }
        $plan = array_slice($plan, 0, self::TOTAL_DOCUMENTOS);

        // Fechas de emisión repartidas entre enero de 2023 y hoy, procesadas en orden cronológico.
        $inicio = Carbon::create(2023, 1, 9)->timestamp;
        $fin = now()->subDays(3)->timestamp;
        $fechas = collect($plan)->map(fn () => Carbon::createFromTimestamp(mt_rand($inicio, $fin))->startOfDay()->addHours(mt_rand(8, 16)))->sort()->values();

        $documentos = [];
        foreach ($plan as $i => $departamento) {
            $fecha = $fechas[$i];
            $tipo = $tipos[$departamento][mt_rand(0, $tipos[$departamento]->count() - 1)];
            $titulo = $this->titulo($tipo, $departamento, $fecha, $nombresPersonas);
            $categoria = $categorias[self::CATEGORIA_POR_TIPO[$tipo->nombre] ?? 'Correspondencia'];
            $confidencial = in_array($tipo->nombre, ['Expediente y registro del personal', 'Contrato y convenio', 'Documento de proceso legal o administrativo'], true);
            $ubicacion = $this->ubicaciones[$departamento][mt_rand(0, count($this->ubicaciones[$departamento]) - 1)];

            $documento = Documento::create([
                'id_categoria' => $categoria,
                'id_tipo_documental' => $tipo->id_tipo_documental,
                'id_ubicacion' => $ubicacion->id_ubicacion,
                'creado_por' => $responsable->id_usuario,
                'codigo_documental' => CodigoDocumental::siguiente($tipo, $fecha),
                'titulo' => $titulo,
                'descripcion' => sprintf('Original en soporte físico, %d fojas útiles. Archivado en %s.', mt_rand(1, 38), $ubicacion->etiqueta),
                'fecha_documento' => $fecha->toDateString(),
                'nivel_acceso' => $confidencial ? 'confidencial' : (mt_rand(0, 3) === 0 ? 'publico' : 'interno'),
                'estado' => Documento::DISPONIBLE,
                'fecha_registro' => $fecha->copy()->addDays(mt_rand(0, 3))->addMinutes(mt_rand(10, 300)),
                'fecha_actualizacion' => $fecha->copy()->addDays(mt_rand(0, 3))->addMinutes(mt_rand(10, 300)),
            ]);
            $qr = GestorQr::generar($documento);
            $qr->update(['fecha_generacion' => $documento->fecha_registro]);
            $this->movimiento($documento, $responsable, 'registro', "Registrado como $documento->codigo_documental", $documento->fecha_registro, null, 'disponible');
            $this->movimiento($documento, $responsable, 'qr_generado', 'Código QR generado', $documento->fecha_registro->copy()->addMinutes(1));
            $documentos[] = $documento;
        }

        return $documentos;
    }

    private function titulo(TipoDocumental $tipo, string $departamento, Carbon $fecha, array $personas): string
    {
        $plantilla = null;
        if (isset(self::TITULOS[$tipo->nombre])) {
            $opciones = self::TITULOS[$tipo->nombre];
            $plantilla = $opciones[mt_rand(0, count($opciones) - 1)];
        } else {
            $asuntos = self::ASUNTOS[$departamento];
            $plantilla = "{$tipo->nombre} Nro. {num} — ".$asuntos[mt_rand(0, count($asuntos) - 1)];
        }
        $sigla = CodigoDocumental::sigla($departamento);

        return strtr($plantilla, [
            '{num}' => sprintf('VZ-%s-%d-%04d', $sigla, $fecha->year, mt_rand(1, 480)),
            '{via}' => self::VIAS[mt_rand(0, count(self::VIAS) - 1)],
            '{contratista}' => self::CONTRATISTAS[mt_rand(0, count(self::CONTRATISTAS) - 1)],
            '{anio}' => (string) $fecha->year,
            '{mes}' => self::MESES[$fecha->month - 1],
            '{trim}' => ['primer', 'segundo', 'tercer', 'cuarto'][intdiv($fecha->month - 1, 3)],
            '{fac}' => (string) mt_rand(1000, 9800),
            '{persona}' => $personas[mt_rand(0, count($personas) - 1)],
        ]);
    }

    /** Préstamos devueltos, 12 activos (3 en mora), solicitudes pendientes y rechazadas, con su bitácora. */
    private function historial(array $documentos, array $personas, Usuario $responsable): void
    {
        $libres = collect($documentos)->shuffle(mt_rand())->values();
        // Documentos reservados para préstamos activos (12), solicitudes (3 + 5) y bajas (3).
        $reservados = $libres->splice(0, 23)->values();
        $siguiente = fn () => $reservados->pop();
        $usuario = fn () => $personas[mt_rand(0, count($personas) - 1)];

        // 72 préstamos ya devueltos (uno por documento, para que nunca se solapen) en los últimos meses.
        $antiguos = $libres->filter(fn ($d) => $d->fecha_registro->lt(now()->subDays(60)))->take(72);
        foreach ($antiguos as $doc) {
            $desde = $doc->fecha_registro->copy()->addDays(5)->timestamp;
            $hasta = now()->subDays(25)->timestamp;
            $entrega = Carbon::createFromTimestamp(mt_rand($desde, $hasta))->setTime(mt_rand(8, 15), mt_rand(0, 59));
            $this->ciclo($doc, $usuario(), $responsable, $entrega, $entrega->copy()->addDays(mt_rand(7, 15)), $entrega->copy()->addDays(mt_rand(1, 12))->addHours(mt_rand(1, 6)));
        }

        // 12 préstamos activos; los 3 primeros vencidos (en mora).
        for ($i = 0; $i < 12; $i++) {
            $doc = $siguiente();
            $enMora = $i < 3;
            $entrega = now()->subDays($enMora ? mt_rand(18, 30) : mt_rand(1, 9))->subHours(mt_rand(1, 6));
            $prevista = $enMora ? $entrega->copy()->addDays(mt_rand(7, 10)) : now()->addDays(mt_rand(2, 12));
            $this->ciclo($doc, $usuario(), $responsable, $entrega, $prevista, null);
        }

        // 3 solicitudes pendientes de documentos disponibles.
        for ($i = 0; $i < 3; $i++) {
            $doc = $siguiente();
            $quien = $usuario();
            $cuando = now()->subDays($i)->subHours(mt_rand(1, 7));
            SolicitudPrestamo::create(['id_documento' => $doc->id_documento, 'id_solicitante' => $quien->id_usuario, 'fecha_solicitud' => $cuando, 'motivo' => self::MOTIVOS[mt_rand(0, count(self::MOTIVOS) - 1)], 'estado' => 'pendiente']);
            $this->movimiento($doc, $quien, 'solicitud', 'Solicitud de préstamo', $cuando);
        }

        // 5 solicitudes rechazadas.
        for ($i = 0; $i < 5; $i++) {
            $doc = $siguiente();
            $quien = $usuario();
            $cuando = now()->subDays(mt_rand(10, 160));
            SolicitudPrestamo::create(['id_documento' => $doc->id_documento, 'id_solicitante' => $quien->id_usuario, 'fecha_solicitud' => $cuando, 'motivo' => self::MOTIVOS[mt_rand(0, count(self::MOTIVOS) - 1)], 'estado' => 'rechazada', 'observacion' => 'Se atenderá la consulta en el archivo; el original no sale de Secretaría.']);
            $this->movimiento($doc, $quien, 'solicitud', 'Solicitud de préstamo', $cuando);
            $this->movimiento($doc, $responsable, 'solicitud_rechazada', 'Solicitud rechazada: el original no sale de Secretaría.', $cuando->copy()->addHours(3));
        }

        // Algunas consultas por QR recientes y 3 documentos dados de baja.
        for ($i = 0; $i < 25; $i++) {
            $this->movimiento($documentos[mt_rand(0, count($documentos) - 1)], $usuario(), 'consulta_qr', 'Consulta por lectura de código QR', now()->subDays(mt_rand(0, 20))->subMinutes(mt_rand(5, 900)));
        }
        for ($i = 0; $i < 3; $i++) {
            $doc = $siguiente();
            $doc->update(['estado' => Documento::DE_BAJA, 'fecha_actualizacion' => now()->subDays(mt_rand(5, 90))]);
            $this->movimiento($doc, $responsable, 'baja', 'Documento dado de baja por deterioro', $doc->fecha_actualizacion, 'disponible', 'de_baja');
        }
    }

    /** Un ciclo completo solicitud → aprobación → entrega (→ devolución) con su bitácora. */
    private function ciclo(Documento $doc, Usuario $quien, Usuario $responsable, Carbon $entrega, Carbon $prevista, ?Carbon $devolucion): void
    {
        $solicitud = SolicitudPrestamo::create([
            'id_documento' => $doc->id_documento,
            'id_solicitante' => $quien->id_usuario,
            'fecha_solicitud' => $entrega->copy()->subHours(mt_rand(2, 30)),
            'motivo' => self::MOTIVOS[mt_rand(0, count(self::MOTIVOS) - 1)],
            'estado' => 'aprobada',
        ]);
        $this->movimiento($doc, $quien, 'solicitud', 'Solicitud de préstamo', $solicitud->fecha_solicitud);
        $this->movimiento($doc, $responsable, 'solicitud_aprobada', 'Solicitud aprobada', $solicitud->fecha_solicitud->copy()->addHour());

        $obs = self::OBS_DEVOLUCION[mt_rand(0, count(self::OBS_DEVOLUCION) - 1)];
        $prestamo = Prestamo::create([
            'id_documento' => $doc->id_documento,
            'id_solicitud' => $solicitud->id_solicitud,
            'entregado_por' => $responsable->id_usuario,
            'recibido_por' => $quien->id_usuario,
            'fecha_entrega' => $entrega,
            'fecha_devolucion_prevista' => $prevista->copy()->endOfDay(),
            'fecha_devolucion_real' => $devolucion,
            'observacion' => $devolucion ? $obs : null,
            'estado' => $devolucion ? 'devuelto' : 'activo',
        ]);
        $this->movimiento($doc, $responsable, 'prestamo', "Entregado a $quien->nombres $quien->apellidos; devolución prevista {$prevista->format('d/m/Y')}", $entrega, 'disponible', 'prestado', $prestamo->id_prestamo);

        if ($devolucion) {
            $this->movimiento($doc, $responsable, 'devolucion', 'Documento devuelto'.($obs ? ": $obs" : ''), $devolucion, 'prestado', 'disponible', $prestamo->id_prestamo);
        } else {
            $doc->update(['estado' => Documento::PRESTADO, 'fecha_actualizacion' => $entrega]);
        }
    }

    private function movimiento(Documento $doc, Usuario $usuario, string $tipo, ?string $descripcion, Carbon|string $fecha, ?string $antes = null, ?string $despues = null, ?int $prestamo = null): void
    {
        Movimiento::create([
            'id_documento' => $doc->id_documento,
            'id_usuario' => $usuario->id_usuario,
            'id_prestamo' => $prestamo,
            'tipo_movimiento' => $tipo,
            'descripcion' => $descripcion,
            'estado_anterior' => $antes,
            'estado_nuevo' => $despues,
            'fecha_movimiento' => $fecha,
            'direccion_ip' => '10.10.'.mt_rand(1, 4).'.'.mt_rand(10, 80),
        ]);
    }
}
