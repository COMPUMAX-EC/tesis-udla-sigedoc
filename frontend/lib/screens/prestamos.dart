import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'acciones_prestamo.dart';
import 'documento_detalle.dart';

/// M04 Préstamos. Responsable: solicitudes, préstamos activos e historial. Funcionario: lo suyo.
class PrestamosScreen extends StatefulWidget {
  const PrestamosScreen({super.key});

  @override
  State<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends State<PrestamosScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _version = 0; // fuerza la recarga de las listas tras una operación

  static const _pestanas = ['Solicitudes', 'Préstamos activos', 'Historial'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _pestanas.length, vsync: this)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _recargar() => setState(() => _version++);

  Future<void> _prestamoDirecto() async {
    final doc = await showDialog<Map>(context: context, builder: (_) => const _ElegirDocumento());
    if (doc == null || !mounted) return;
    if (await registrarPrestamo(context, doc)) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final api = Api.instance;
    final i = _tabs.index;
    final lista = switch (i) {
      0 => _Lista(key: ValueKey('s$_version'), ruta: 'solicitudes', fila: (m, r) => _FilaSolicitud(m, recargar: r), vacio: api.esResponsable ? 'No hay solicitudes.' : 'No ha realizado solicitudes.'),
      1 => _Lista(key: ValueKey('a$_version'), ruta: 'prestamos', params: const {'estado': 'activo'}, fila: (m, r) => _FilaPrestamo(m, recargar: r), vacio: 'No hay préstamos activos.'),
      _ => _Lista(key: ValueKey('h$_version'), ruta: 'prestamos', params: const {'estado': 'devuelto'}, fila: (m, r) => _FilaPrestamo(m, recargar: r), vacio: 'Aún no hay devoluciones registradas.'),
    };

    return Pagina(children: [
      Row(children: [
        Expanded(child: Text(api.esResponsable ? 'Gestión de préstamos' : 'Mis solicitudes y préstamos', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Paleta.textoSuave))),
        if (api.esResponsable) FilledButton.icon(onPressed: _prestamoDirecto, icon: const Icon(Icons.add), label: const Text('Nuevo préstamo')),
      ]),
      const SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Paleta.borde)),
        child: TabBar(controller: _tabs, dividerColor: Colors.transparent, tabs: [for (final p in _pestanas) Tab(text: p)]),
      ),
      const SizedBox(height: 16),
      lista,
    ]);
  }
}

typedef _Constructor = Widget Function(Map<String, dynamic> m, VoidCallback recargar);

class _Lista extends StatefulWidget {
  const _Lista({super.key, required this.ruta, required this.fila, required this.vacio, this.params = const {}});
  final String ruta;
  final Map<String, String> params;
  final _Constructor fila;
  final String vacio;

  @override
  State<_Lista> createState() => _ListaState();
}

class _ListaState extends State<_Lista> {
  List<dynamic> _items = [];
  int _pagina = 1, _ultima = 1, _total = 0;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar([int? pagina]) async {
    setState(() => _cargando = true);
    try {
      final r = await Api.instance.get(widget.ruta, {...widget.params, 'page': '${pagina ?? _pagina}', 'per_page': '15'});
      _items = r['data'];
      _pagina = r['current_page'];
      _ultima = r['last_page'];
      _total = r['total'];
      _error = null;
    } on ApiError catch (e) {
      _error = e.mensaje;
    }
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return EstadoCarga(
      cargando: _cargando,
      error: _error,
      vacio: _items.isEmpty,
      mensajeVacio: widget.vacio,
      reintentar: _cargar,
      child: Column(children: [
        for (final m in _items)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: widget.fila(Map<String, dynamic>.from(m as Map), () => _cargar())),
        Paginador(pagina: _pagina, ultima: _ultima, total: _total, cambiar: _cargar),
      ]),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.documento, required this.lineas, required this.chip, required this.acciones});
  final Map? documento;
  final List<String> lineas;
  final Widget chip;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: documento == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentoDetalleScreen(id: documento!['id_documento']))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('${documento?['codigo_documental'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800, color: Paleta.azul))),
              chip,
            ]),
            const SizedBox(height: 4),
            Text('${documento?['titulo'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5)),
            const SizedBox(height: 6),
            for (final l in lineas) Padding(padding: const EdgeInsets.only(top: 2), child: Text(l, style: const TextStyle(color: Paleta.textoSuave, fontSize: 13.5))),
            if (acciones.isNotEmpty) ...[const SizedBox(height: 12), Wrap(spacing: 10, runSpacing: 8, children: acciones)],
          ]),
        ),
      ),
    );
  }
}

class _FilaSolicitud extends StatelessWidget {
  const _FilaSolicitud(this.s, {required this.recargar});
  final Map<String, dynamic> s;
  final VoidCallback recargar;

  @override
  Widget build(BuildContext context) {
    final api = Api.instance;
    final estado = s['estado'] as String;
    final doc = s['documento'] as Map?;
    final sinEntrega = s['prestamo'] == null;
    final acciones = <Widget>[];
    if (api.esResponsable && estado == 'pendiente') {
      acciones.add(FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Paleta.verde, minimumSize: const Size(0, 38)),
        onPressed: () async {
          if (await resolverSolicitud(context, s, aprobar: true)) recargar();
        },
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Aprobar'),
      ));
      acciones.add(OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: Paleta.rojo, side: const BorderSide(color: Paleta.rojo), minimumSize: const Size(0, 38)),
        onPressed: () async {
          if (await resolverSolicitud(context, s, aprobar: false)) recargar();
        },
        icon: const Icon(Icons.close, size: 18),
        label: const Text('Rechazar'),
      ));
    }
    if (api.esResponsable && estado == 'aprobada' && sinEntrega && doc?['estado'] == 'disponible') {
      acciones.add(FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
        onPressed: () async {
          if (await registrarPrestamo(context, doc!, solicitud: s)) recargar();
        },
        icon: const Icon(Icons.handshake_outlined, size: 18),
        label: const Text('Registrar entrega'),
      ));
    }
    return _Tarjeta(
      documento: doc,
      chip: EstadoChip(estado),
      lineas: [
        if (api.esResponsable) 'Solicita: ${nombreCompleto(s['solicitante'] as Map?)} · ${s['solicitante']?['departamento']?['nombre'] ?? ''}',
        'Fecha: ${fmtFechaHora(s['fecha_solicitud'])}',
        if (s['motivo'] != null) 'Motivo: ${s['motivo']}',
        if (s['observacion'] != null) 'Respuesta: ${s['observacion']}',
        if (estado == 'aprobada' && !sinEntrega) 'Entrega registrada.',
      ],
      acciones: acciones,
    );
  }
}

class _FilaPrestamo extends StatelessWidget {
  const _FilaPrestamo(this.p, {required this.recargar});
  final Map<String, dynamic> p;
  final VoidCallback recargar;

  @override
  Widget build(BuildContext context) {
    final api = Api.instance;
    final activo = p['estado'] == 'activo';
    final mora = p['en_mora'] == true;
    return _Tarjeta(
      documento: p['documento'] as Map?,
      chip: EstadoChip('${p['estado']}', mora: mora),
      lineas: [
        if (api.esResponsable) 'Recibe: ${nombreCompleto(p['recibido_por'] as Map?)} · ${p['recibido_por']?['departamento']?['nombre'] ?? ''}',
        'Entrega: ${fmtFechaHora(p['fecha_entrega'])} · Devolución prevista: ${fmtFecha(p['fecha_devolucion_prevista'])}',
        if (p['fecha_devolucion_real'] != null) 'Devuelto: ${fmtFechaHora(p['fecha_devolucion_real'])}',
        if (p['observacion'] != null) 'Observación: ${p['observacion']}',
      ],
      acciones: [
        if (api.esResponsable && activo)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Paleta.verde, minimumSize: const Size(0, 38)),
            onPressed: () async {
              if (await registrarDevolucion(context, p)) recargar();
            },
            icon: const Icon(Icons.assignment_return_outlined, size: 18),
            label: const Text('Registrar devolución'),
          ),
      ],
    );
  }
}

/// Búsqueda de un documento disponible para registrar un préstamo directo.
class _ElegirDocumento extends StatefulWidget {
  const _ElegirDocumento();

  @override
  State<_ElegirDocumento> createState() => _ElegirDocumentoState();
}

class _ElegirDocumentoState extends State<_ElegirDocumento> {
  List<dynamic> _docs = [];
  Timer? _espera;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _buscar('');
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  Future<void> _buscar(String q) async {
    setState(() => _cargando = true);
    try {
      final r = await Api.instance.get('documentos', {'estado': 'disponible', 'per_page': '8', if (q.isNotEmpty) 'buscar': q});
      _docs = r['data'];
    } on ApiError catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Elegir documento'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Buscar por código o título…', prefixIcon: Icon(Icons.search)),
            onChanged: (v) {
              _espera?.cancel();
              _espera = Timer(const Duration(milliseconds: 300), () => _buscar(v.trim()));
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _docs.isEmpty
                    ? const Center(child: Text('Sin documentos disponibles con ese criterio.'))
                    : ListView.separated(
                        itemCount: _docs.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (_, i) {
                          final d = _docs[i] as Map;
                          return ListTile(
                            title: Text(d['titulo'], maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${d['codigo_documental']} · ${d['ubicacion']?['etiqueta'] ?? 'Sin ubicación'}'),
                            onTap: () => Navigator.pop(context, d),
                          );
                        },
                      ),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))],
    );
  }
}
