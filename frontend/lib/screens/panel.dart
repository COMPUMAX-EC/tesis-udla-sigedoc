import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'documento_form.dart';
import 'shell.dart';

/// Panel principal (wireframe Figura 35): indicadores, acciones rápidas, gráficos y actividad reciente.
class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key});

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  Map<String, dynamic>? _datos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      _datos = Map<String, dynamic>.from(await Api.instance.get('panel/resumen'));
    } on ApiError catch (e) {
      _error = e.mensaje;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final api = Api.instance;
    final u = api.usuario ?? {};
    final d = _datos;
    final ir = ShellScope.of(context).ir;
    final personal = d?['alcance'] == 'personal';

    return Pagina(children: [
      Text('Bienvenido, ${u['nombres'] ?? ''}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Paleta.texto)),
      Text([api.rol, ?u['departamento']?['nombre']].join(' · '), style: const TextStyle(color: Paleta.textoSuave, fontSize: 15)),
      const SizedBox(height: 20),
      if (d == null)
        EstadoCarga(cargando: _error == null, error: _error, vacio: false, reintentar: _cargar, child: const SizedBox())
      else ...[
        _indicadores(d, personal, ir),
        const SizedBox(height: 16),
        _acciones(ir),
        const SizedBox(height: 16),
        if (!personal) _graficos(d),
        if (!personal) const SizedBox(height: 16),
        _actividad(d, personal),
      ],
    ]);
  }

  Widget _indicadores(Map<String, dynamic> d, bool personal, void Function(String) ir) {
    final docs = d['documentos'] as Map;
    final tarjetas = [
      Indicador(
        titulo: personal ? 'Documentos consultables' : 'Documentos',
        valor: docs['total'],
        icono: Icons.description_rounded,
        color: Paleta.azul,
        fondo: Paleta.azulClaro,
        detalle: '${docs['disponibles']} disponibles · ${docs['prestados']} prestados',
        alTocar: () => ir('Documentos'),
      ),
      Indicador(
        titulo: personal ? 'Mis préstamos' : 'Préstamos activos',
        valor: d['prestamos_activos'],
        icono: Icons.handshake_rounded,
        color: Paleta.verde,
        fondo: Paleta.verdeClaro,
        detalle: (d['prestamos_en_mora'] as int) > 0 ? '${d['prestamos_en_mora']} en mora' : 'Sin préstamos en mora',
        alTocar: () => ir('Préstamos'),
      ),
      Indicador(
        titulo: personal ? 'Mis solicitudes' : 'Pendientes',
        valor: d['solicitudes_pendientes'],
        icono: Icons.notifications_active_rounded,
        color: Paleta.naranja,
        fondo: Paleta.naranjaClaro,
        detalle: personal ? 'En espera de aprobación' : 'Solicitudes por resolver',
        alTocar: () => ir('Préstamos'),
      ),
    ];
    return LayoutBuilder(builder: (context, c) {
      final columnas = c.maxWidth >= 860 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
      final ancho = (c.maxWidth - 16 * (columnas - 1)) / columnas;
      return Wrap(spacing: 16, runSpacing: 16, children: [for (final t in tarjetas) SizedBox(width: ancho, child: t)]);
    });
  }

  Widget _acciones(void Function(String) ir) {
    final api = Api.instance;
    final botones = <Widget>[
      if (api.esResponsable)
        _Accion('Nuevo documento', Icons.note_add_outlined, Paleta.azul, Paleta.azulClaro, () async {
          final creado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const DocumentoFormScreen()));
          if (creado == true) _cargar();
        }),
      if (api.esResponsable || api.esFuncionario) _Accion('Préstamo', Icons.handshake_outlined, Paleta.verde, Paleta.verdeClaro, () => ir('Préstamos')),
      if (api.esResponsable || api.esFuncionario) _Accion('Escanear QR', Icons.qr_code_2_rounded, Paleta.violeta, Paleta.violetaClaro, () => ir('Escanear QR')),
      if (api.esAdmin) _Accion('Usuarios', Icons.people_alt_outlined, Paleta.azul, Paleta.azulClaro, () => ir('Usuarios')),
      if (api.esAdmin || api.esResponsable) _Accion('Reportes', Icons.bar_chart_rounded, Paleta.violeta, Paleta.violetaClaro, () => ir('Reportes')),
    ];
    return Panel(
      titulo: 'Acciones rápidas',
      child: Wrap(spacing: 14, runSpacing: 14, children: botones),
    );
  }

  Widget _graficos(Map<String, dynamic> d) {
    final porDep = (d['por_departamento'] as List).cast<Map>();
    final porMes = (d['prestamos_por_mes'] as List).cast<Map>();
    return LayoutBuilder(builder: (context, c) {
      final dosColumnas = c.maxWidth >= 860;
      final a = Panel(titulo: 'Documentos por departamento', child: _Barras(porDep.map((e) => (e['departamento'] as String, (e['total'] as num).toInt())).toList(), Paleta.azul, horizontal: true));
      final b = Panel(titulo: 'Préstamos por mes', child: _Barras(porMes.map((e) => (_mes(e['mes'] as String), (e['total'] as num).toInt())).toList(), Paleta.verde));
      return dosColumnas
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)])
          : Column(children: [a, const SizedBox(height: 16), b]);
    });
  }

  static String _mes(String ym) {
    const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return m[int.parse(ym.substring(5)) - 1];
  }

  Widget _actividad(Map<String, dynamic> d, bool personal) {
    final items = (d['actividad_reciente'] as List).cast<Map>();
    return Panel(
      titulo: personal ? 'Mi actividad reciente' : 'Actividad reciente',
      child: items.isEmpty
          ? const Padding(padding: EdgeInsets.all(12), child: Text('Aún no hay actividad.', style: TextStyle(color: Paleta.textoSuave)))
          : Column(children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(),
                _FilaActividad(items[i]),
              ],
            ]),
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion(this.texto, this.icono, this.color, this.fondo, this.alTocar);
  final String texto;
  final IconData icono;
  final Color color;
  final Color fondo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: alTocar,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: fondo.withValues(alpha: .6), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: .6))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icono, color: color, size: 26),
          const SizedBox(width: 10),
          Flexible(child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15.5))),
        ]),
      ),
    );
  }
}

class _FilaActividad extends StatelessWidget {
  const _FilaActividad(this.m);
  final Map m;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloMovimiento(m['tipo_movimiento']);
    final doc = m['documento'] as Map?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        CircleAvatar(radius: 20, backgroundColor: estilo.fondo, child: Icon(estilo.icono, color: estilo.color, size: 21)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombreMovimiento(m['tipo_movimiento']), style: const TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto)),
            Text('${doc?['codigo_documental'] ?? ''} · ${doc?['titulo'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Paleta.textoSuave)),
          ]),
        ),
        const SizedBox(width: 12),
        Row(children: [
          const Icon(Icons.schedule, size: 16, color: Paleta.textoSuave),
          const SizedBox(width: 4),
          Text(fmtRelativa(m['fecha_movimiento']), style: const TextStyle(color: Paleta.textoSuave, fontSize: 13)),
        ]),
      ]),
    );
  }
}

/// Gráfico de barras sencillo (sin dependencias externas), horizontal o vertical.
class _Barras extends StatelessWidget {
  const _Barras(this.datos, this.color, {this.horizontal = false});
  final List<(String, int)> datos;
  final Color color;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final maximo = datos.fold<int>(1, (m, e) => e.$2 > m ? e.$2 : m);
    if (horizontal) {
      return Column(children: [
        for (final (nombre, valor) in datos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(width: 118, child: Text(nombre, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Paleta.texto))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: valor / maximo, minHeight: 14, color: color, backgroundColor: Paleta.azulClaro),
                ),
              ),
              SizedBox(width: 38, child: Text('$valor', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
          ),
      ]);
    }
    return SizedBox(
      height: 190,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final (nombre, valor) in datos)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('$valor', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Container(height: 4 + 120 * valor / maximo, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))),
                const SizedBox(height: 6),
                Text(nombre, style: const TextStyle(fontSize: 12.5, color: Paleta.textoSuave)),
              ]),
            ),
          ),
      ]),
    );
  }
}
