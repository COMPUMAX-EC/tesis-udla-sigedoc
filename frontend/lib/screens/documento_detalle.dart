import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'acciones_prestamo.dart';
import 'documento_form.dart';

/// Ficha de un documento: datos, ubicación (RF-05.3), QR (RF-03.x), archivos, historial (RF-05.2) y préstamos.
class DocumentoDetalleScreen extends StatefulWidget {
  const DocumentoDetalleScreen({super.key, required this.id});
  final int id;

  @override
  State<DocumentoDetalleScreen> createState() => _DocumentoDetalleScreenState();
}

class _DocumentoDetalleScreenState extends State<DocumentoDetalleScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _doc;
  List<dynamic> _historial = [];
  List<dynamic> _prestamos = [];
  String? _error;
  bool _cambio = false;
  late TabController _tabs;

  List<String> get _pestanas => ['Resumen', 'Archivos', if (Api.instance.esResponsable) ...['Historial', 'Préstamos']];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _pestanas.length, vsync: this)..addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      _doc = Map<String, dynamic>.from(await Api.instance.get('documentos/${widget.id}'));
      if (Api.instance.esResponsable) {
        _historial = await Api.instance.get('documentos/${widget.id}/historial');
        _prestamos = await Api.instance.get('documentos/${widget.id}/prestamos');
      }
      _error = null;
    } on ApiError catch (e) {
      _error = e.mensaje;
    }
    if (mounted) setState(() {});
  }

  Future<void> _accion(Future<bool> Function() f) async {
    if (await f()) {
      _cambio = true;
      _cargar();
    }
  }

  Future<void> _baja() async {
    if (!await confirmar(context, 'Dar de baja', 'El documento dejará de estar disponible, pero su historial se conserva. ¿Continuar?', accion: 'Dar de baja', peligro: true)) return;
    try {
      await Api.instance.delete('documentos/${widget.id}');
      _cambio = true;
      _cargar();
    } on ApiError catch (e) {
      if (mounted) avisar(context, e.mensaje);
    }
  }

  Future<void> _reactivar() async {
    try {
      await Api.instance.post('documentos/${widget.id}/reactivar', {});
      _cambio = true;
      _cargar();
    } on ApiError catch (e) {
      if (mounted) avisar(context, e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _doc;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (volvio, _) {
        if (!volvio) Navigator.pop(context, _cambio);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.pop(context, _cambio)),
          title: Text(d?['codigo_documental'] ?? 'Documento'),
        ),
        body: d == null
            ? EstadoCarga(cargando: _error == null, error: _error, vacio: false, reintentar: _cargar, child: const SizedBox())
            : Pagina(ancho: 1100, children: [_cabecera(d), const SizedBox(height: 16), _pestanasBar(), const SizedBox(height: 16), _contenido(d)]),
      ),
    );
  }

  // ------------------------------------------------------------------ cabecera

  Widget _cabecera(Map<String, dynamic> d) {
    final api = Api.instance;
    final estado = d['estado'] as String;
    final activo = d['prestamo_activo'] as Map?;
    final prestamoActivo = _prestamos.cast<Map>().where((p) => p['estado'] == 'activo').firstOrNull;
    final doc = {...d};

    final botones = <Widget>[
      if (api.esResponsable && estado != 'de_baja')
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => DocumentoFormScreen(documento: doc)));
            if (ok == true) {
              _cambio = true;
              _cargar();
            }
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
        ),
      if (api.esResponsable && estado == 'disponible') FilledButton.icon(onPressed: () => _accion(() => registrarPrestamo(context, doc)), icon: const Icon(Icons.handshake_outlined), label: const Text('Registrar préstamo')),
      if (api.esResponsable && estado == 'prestado' && prestamoActivo != null)
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Paleta.verde),
          onPressed: () => _accion(() => registrarDevolucion(context, {...prestamoActivo, 'documento': doc})),
          icon: const Icon(Icons.assignment_return_outlined),
          label: const Text('Registrar devolución'),
        ),
      if (api.esFuncionario && estado == 'disponible') FilledButton.icon(onPressed: () => _accion(() => solicitarPrestamo(context, doc)), icon: const Icon(Icons.handshake_outlined), label: const Text('Solicitar préstamo')),
      if (api.esResponsable && estado == 'disponible') OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Paleta.rojo, side: const BorderSide(color: Paleta.rojo)), onPressed: _baja, icon: const Icon(Icons.archive_outlined), label: const Text('Dar de baja')),
      if (api.esResponsable && estado == 'de_baja') OutlinedButton.icon(onPressed: _reactivar, icon: const Icon(Icons.unarchive_outlined), label: const Text('Reactivar')),
    ];

    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          EstadoChip(estado, mora: activo?['en_mora'] == true),
          if (activo?['en_mora'] == true) const Text('Devolución vencida', style: TextStyle(color: Paleta.rojo, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Text(d['titulo'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Paleta.texto)),
        const SizedBox(height: 4),
        Text('${d['tipo_documental']?['departamento']?['nombre'] ?? ''} · ${d['tipo_documental']?['nombre'] ?? ''}', style: const TextStyle(color: Paleta.textoSuave, fontSize: 15)),
        if (botones.isNotEmpty) ...[const SizedBox(height: 16), Wrap(spacing: 10, runSpacing: 10, children: botones)],
      ]),
    );
  }

  Widget _pestanasBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Paleta.borde)),
      child: TabBar(controller: _tabs, isScrollable: true, tabAlignment: TabAlignment.start, dividerColor: Colors.transparent, tabs: [for (final p in _pestanas) Tab(text: p)]),
    );
  }

  Widget _contenido(Map<String, dynamic> d) => switch (_pestanas[_tabs.index]) {
        'Resumen' => _resumen(d),
        'Archivos' => _Archivos(documento: d, alCambiar: () {
            _cambio = true;
            _cargar();
          }),
        'Historial' => _historialLista(),
        _ => _prestamosLista(),
      };

  // ------------------------------------------------------------------ resumen

  Widget _resumen(Map<String, dynamic> d) {
    final api = Api.instance;
    final qr = d['qr'] as Map?;
    final activo = d['prestamo_activo'] as Map?;
    final datos = Panel(
      titulo: 'Datos del documento',
      child: Column(children: [
        Dato('Código', d['codigo_documental']),
        Dato('Título', d['titulo']),
        Dato('Descripción', d['descripcion']),
        Dato('Departamento', d['tipo_documental']?['departamento']?['nombre']),
        Dato('Tipo documental', d['tipo_documental']?['nombre']),
        Dato('Categoría', d['categoria']?['nombre']),
        Dato('Fecha del documento', fmtFecha(d['fecha_documento'])),
        Dato('Nivel de acceso', '${d['nivel_acceso']}'.replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase())),
        if (d['creador'] != null) Dato('Registrado por', nombreCompleto(d['creador'] as Map)),
        Dato('Fecha de registro', fmtFechaHora(d['fecha_registro'])),
        Dato('Última actualización', fmtFechaHora(d['fecha_actualizacion'])),
      ]),
    );

    final ubicacion = Panel(
      titulo: 'Ubicación física actual',
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.place_rounded, color: Paleta.azul, size: 30),
        const SizedBox(width: 12),
        Expanded(child: Text(d['ubicacion']?['etiqueta'] ?? 'Sin ubicación asignada', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      ]),
    );

    final prestamo = activo == null
        ? null
        : Panel(
            titulo: 'Préstamo en curso',
            child: api.esResponsable
                ? Column(children: [
                    Dato('Recibe', nombreCompleto(activo['recibido_por'] as Map?)),
                    Dato('Entregado', fmtFechaHora(activo['fecha_entrega'])),
                    Dato('Devolución prevista', fmtFecha(activo['fecha_devolucion_prevista'])),
                    if (activo['observacion'] != null) Dato('Observación', activo['observacion']),
                  ])
                : const Text('Este documento se encuentra prestado actualmente.'),
          );

    final codigo = Panel(
      titulo: 'Código QR',
      child: qr == null
          ? const Text('Sin código QR.')
          : Column(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Paleta.borde)),
                child: QrImageView(data: 'SIGEDOC:${qr['identificador']}', size: 190, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 8),
              Text('${qr['identificador']}'.substring(0, 8).toUpperCase(), style: const TextStyle(color: Paleta.textoSuave, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              if (api.esResponsable) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => abrirEnlace(context, () => Api.instance.post('documentos/${widget.id}/qr/etiqueta', {})),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Imprimir etiqueta'),
                ),
              ],
            ]),
    );

    return LayoutBuilder(builder: (context, c) {
      final dos = c.maxWidth >= 860;
      final izquierda = Column(children: [datos, if (prestamo != null) ...[const SizedBox(height: 16), prestamo]]);
      final derecha = Column(children: [ubicacion, const SizedBox(height: 16), codigo]);
      return dos
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: izquierda), const SizedBox(width: 16), Expanded(flex: 2, child: derecha)])
          : Column(children: [derecha, const SizedBox(height: 16), izquierda]);
    });
  }

  // ------------------------------------------------------------------ historial y préstamos

  Widget _historialLista() {
    return Panel(
      titulo: 'Historial de movimientos',
      child: _historial.isEmpty
          ? const Text('Sin movimientos.')
          : Column(children: [
              for (var i = 0; i < _historial.length; i++) ...[
                if (i > 0) const Divider(),
                _Movimiento(_historial[i] as Map),
              ],
            ]),
    );
  }

  Widget _prestamosLista() {
    return Panel(
      titulo: 'Préstamos y devoluciones',
      child: _prestamos.isEmpty
          ? const Text('Este documento nunca ha sido prestado.')
          : Column(children: [
              for (var i = 0; i < _prestamos.length; i++) ...[
                if (i > 0) const Divider(),
                _PrestamoFila(_prestamos[i] as Map),
              ],
            ]),
    );
  }
}

class _Movimiento extends StatelessWidget {
  const _Movimiento(this.m);
  final Map m;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloMovimiento(m['tipo_movimiento']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 19, backgroundColor: estilo.fondo, child: Icon(estilo.icono, color: estilo.color, size: 20)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombreMovimiento(m['tipo_movimiento']), style: const TextStyle(fontWeight: FontWeight.w700)),
            if (m['descripcion'] != null) Text('${m['descripcion']}', style: const TextStyle(color: Paleta.texto)),
            if (m['estado_anterior'] != null || m['estado_nuevo'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  if (m['estado_anterior'] != null) EstadoChip('${m['estado_anterior']}'),
                  if (m['estado_anterior'] != null && m['estado_nuevo'] != null) const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 16, color: Paleta.textoSuave)),
                  if (m['estado_nuevo'] != null) EstadoChip('${m['estado_nuevo']}'),
                ]),
              ),
            Text('${nombreCompleto(m['usuario'] as Map?)} · ${fmtFechaHora(m['fecha_movimiento'])}${m['direccion_ip'] != null ? ' · ${m['direccion_ip']}' : ''}',
                style: const TextStyle(color: Paleta.textoSuave, fontSize: 12.5)),
          ]),
        ),
      ]),
    );
  }
}

class _PrestamoFila extends StatelessWidget {
  const _PrestamoFila(this.p);
  final Map p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombreCompleto(p['recibido_por'] as Map?), style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Entrega ${fmtFecha(p['fecha_entrega'])} · prevista ${fmtFecha(p['fecha_devolucion_prevista'])}${p['fecha_devolucion_real'] != null ? ' · devuelto ${fmtFecha(p['fecha_devolucion_real'])}' : ''}',
                style: const TextStyle(color: Paleta.textoSuave, fontSize: 13)),
            if (p['observacion'] != null) Text('${p['observacion']}', style: const TextStyle(fontSize: 13)),
          ]),
        ),
        EstadoChip('${p['estado']}', mora: p['en_mora'] == true),
      ]),
    );
  }
}

/// Copia digital (escaneo) del documento: listar, adjuntar (Responsable) y descargar.
class _Archivos extends StatefulWidget {
  const _Archivos({required this.documento, required this.alCambiar});
  final Map<String, dynamic> documento;
  final VoidCallback alCambiar;

  @override
  State<_Archivos> createState() => _ArchivosState();
}

class _ArchivosState extends State<_Archivos> {
  bool _subiendo = false;

  Future<void> _adjuntar() async {
    final r = await FilePicker.pickFiles(withData: true, type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp']);
    final f = r?.files.firstOrNull;
    if (f == null || f.bytes == null) return;
    setState(() => _subiendo = true);
    try {
      await Api.instance.subir('documentos/${widget.documento['id_documento']}/archivos', 'archivo', f.bytes!, f.name);
      widget.alCambiar();
    } on ApiError catch (e) {
      if (mounted) avisar(context, e.mensaje);
    }
    if (mounted) setState(() => _subiendo = false);
  }

  Future<void> _eliminar(Map a) async {
    if (!await confirmar(context, 'Eliminar archivo', '¿Eliminar «${a['nombre_archivo']}»? Quedará registrado en el historial.', accion: 'Eliminar', peligro: true)) return;
    try {
      await Api.instance.delete('archivos/${a['id_archivo']}');
      widget.alCambiar();
    } on ApiError catch (e) {
      if (mounted) avisar(context, e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final archivos = (widget.documento['archivos'] as List?) ?? [];
    final api = Api.instance;
    return Panel(
      titulo: 'Copia digital',
      accion: api.esResponsable
          ? FilledButton.icon(onPressed: _subiendo ? null : _adjuntar, icon: const Icon(Icons.upload_file), label: Text(_subiendo ? 'Subiendo…' : 'Adjuntar archivo'))
          : null,
      child: archivos.isEmpty
          ? const Text('Este documento no tiene copia digital adjunta.', style: TextStyle(color: Paleta.textoSuave))
          : Column(children: [
              for (final a in archivos.cast<Map>())
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: Paleta.azulClaro, child: Icon('${a['tipo_mime']}'.contains('pdf') ? Icons.picture_as_pdf_outlined : Icons.image_outlined, color: Paleta.azul)),
                  title: Text(a['nombre_archivo']),
                  subtitle: Text('${fmtTamano(a['tamano_bytes'])} · ${fmtFechaHora(a['fecha_carga'])} · ${nombreCompleto(a['subido_por'] as Map?)}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(tooltip: 'Abrir', icon: const Icon(Icons.open_in_new), onPressed: () => abrirEnlace(context, () => Api.instance.get('archivos/${a['id_archivo']}/enlace'))),
                    if (api.esResponsable) IconButton(tooltip: 'Eliminar', icon: const Icon(Icons.delete_outline, color: Paleta.rojo), onPressed: () => _eliminar(a)),
                  ]),
                ),
            ]),
    );
  }
}
