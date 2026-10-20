import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'acciones_prestamo.dart';
import 'documento_detalle.dart';
import 'documento_form.dart';

/// RF-02.5 Consultar documentos (wireframe Figura 36): búsqueda, filtros, tabla y acciones por fila.
class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  List<dynamic> _docs = [];
  List<dynamic> _departamentos = [];
  List<dynamic> _categorias = [];
  int _pagina = 1, _ultima = 1, _total = 0;
  String _buscar = '';
  int? _departamento, _categoria;
  String? _estado;
  Timer? _espera;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  Future<void> _cargar({int? pagina}) async {
    setState(() => _cargando = true);
    try {
      if (_departamentos.isEmpty) {
        _departamentos = await Api.instance.get('departamentos', {'solo_activos': '1'});
        _categorias = await Api.instance.get('categorias', {'solo_activos': '1'});
      }
      final r = await Api.instance.get('documentos', {
        'page': '${pagina ?? _pagina}',
        'per_page': '15',
        if (_buscar.isNotEmpty) 'buscar': _buscar,
        if (_departamento != null) 'id_departamento': '$_departamento',
        if (_categoria != null) 'id_categoria': '$_categoria',
        if (_estado != null) 'estado': _estado!,
      });
      _docs = r['data'];
      _pagina = r['current_page'];
      _ultima = r['last_page'];
      _total = r['total'];
      _error = null;
    } on ApiError catch (e) {
      _error = e.mensaje;
    }
    if (mounted) setState(() => _cargando = false);
  }

  void _filtrar() {
    _pagina = 1;
    _cargar(pagina: 1);
  }

  Future<void> _abrir(Map d) async {
    final cambio = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => DocumentoDetalleScreen(id: d['id_documento'])));
    if (cambio == true) _cargar();
  }

  Future<void> _nuevo([Map? d]) async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => DocumentoFormScreen(documento: d == null ? null : Map<String, dynamic>.from(d))));
    if (ok == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final api = Api.instance;
    final escritorio = esEscritorio(context);

    final filtros = Panel(
      child: Wrap(spacing: 14, runSpacing: 14, crossAxisAlignment: WrapCrossAlignment.end, children: [
        SizedBox(
          width: escritorio ? 320 : double.infinity,
          child: TextField(
            decoration: const InputDecoration(labelText: 'Buscar', hintText: 'Código, título o descripción…', prefixIcon: Icon(Icons.search)),
            onChanged: (v) {
              _buscar = v.trim();
              _espera?.cancel();
              _espera = Timer(const Duration(milliseconds: 350), _filtrar);
            },
          ),
        ),
        SizedBox(
          width: escritorio ? 220 : double.infinity,
          child: Selector<int>(
            etiqueta: 'Departamento',
            valor: _departamento,
            vacio: 'Todos',
            opciones: [for (final d in _departamentos) DropdownMenuItem(value: d['id_departamento'] as int, child: Text(d['nombre']))],
            alCambiar: (v) {
              _departamento = v;
              _filtrar();
            },
          ),
        ),
        SizedBox(
          width: escritorio ? 200 : double.infinity,
          child: Selector<int>(
            etiqueta: 'Categoría',
            valor: _categoria,
            vacio: 'Todas',
            opciones: [for (final c in _categorias) DropdownMenuItem(value: c['id_categoria'] as int, child: Text(c['nombre']))],
            alCambiar: (v) {
              _categoria = v;
              _filtrar();
            },
          ),
        ),
        SizedBox(
          width: escritorio ? 170 : double.infinity,
          child: Selector<String>(
            etiqueta: 'Estado',
            valor: _estado,
            vacio: 'Todos',
            opciones: const [
              DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
              DropdownMenuItem(value: 'prestado', child: Text('Prestado')),
              DropdownMenuItem(value: 'de_baja', child: Text('De baja')),
            ],
            alCambiar: (v) {
              _estado = v;
              _filtrar();
            },
          ),
        ),
      ]),
    );

    return Pagina(children: [
      Row(children: [
        const Expanded(child: SizedBox()),
        if (api.esResponsable)
          FilledButton.icon(onPressed: () => _nuevo(), icon: const Icon(Icons.add), label: const Text('Nuevo documento')),
      ]),
      const SizedBox(height: 14),
      filtros,
      const SizedBox(height: 16),
      EstadoCarga(
        cargando: _cargando,
        error: _error,
        vacio: _docs.isEmpty,
        mensajeVacio: 'No se encontraron documentos con esos criterios.',
        reintentar: _cargar,
        child: Column(children: [
          escritorio ? _tabla() : _tarjetas(),
          Paginador(pagina: _pagina, ultima: _ultima, total: _total, cambiar: (p) => _cargar(pagina: p)),
        ]),
      ),
    ]);
  }

  // ----------------------------------------------------------- tabla (escritorio)

  Widget _tabla() {
    const cabecera = TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto);
    Widget celda(String t) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), child: Text(t, style: cabecera));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {0: FixedColumnWidth(128), 1: FlexColumnWidth(3), 2: FlexColumnWidth(2.2), 3: FixedColumnWidth(130), 4: FixedColumnWidth(250)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(decoration: const BoxDecoration(color: Paleta.azulClaro), children: [celda('Código'), celda('Documento'), celda('Ubicación'), celda('Estado'), celda('Acciones')]),
          for (final d in _docs) _fila(d as Map),
        ],
      ),
    );
  }

  TableRow _fila(Map d) {
    Widget c(Widget w) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: w);
    return TableRow(decoration: const BoxDecoration(border: Border(top: BorderSide(color: Paleta.borde))), children: [
      c(Text(d['codigo_documental'], style: const TextStyle(fontWeight: FontWeight.w700, color: Paleta.azul))),
      c(InkWell(
        onTap: () => _abrir(d),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d['titulo'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('${d['tipo_documental']?['departamento']?['nombre'] ?? ''} · ${d['tipo_documental']?['nombre'] ?? ''}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Paleta.textoSuave, fontSize: 12.5)),
        ]),
      )),
      c(Text(d['ubicacion']?['etiqueta'] ?? 'Sin ubicación', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Paleta.textoSuave))),
      c(Align(alignment: Alignment.centerLeft, child: EstadoChip(d['estado']))),
      c(_acciones(d)),
    ]);
  }

  Widget _acciones(Map d) {
    final api = Api.instance;
    return Wrap(spacing: 8, runSpacing: 6, children: [
      _Mini('Ver', Icons.visibility_outlined, () => _abrir(d)),
      if (api.esResponsable) _Mini('Editar', Icons.edit_outlined, () => _nuevo(d)),
      if (api.esResponsable)
        _Mini('QR', Icons.qr_code_2, () => abrirEnlace(context, () => Api.instance.post('documentos/${d['id_documento']}/qr/etiqueta', {})), color: Paleta.violeta),
      if (api.esFuncionario && d['estado'] == 'disponible')
        _Mini('Solicitar', Icons.handshake_outlined, () async {
          if (await solicitarPrestamo(context, d)) _cargar();
        }, color: Paleta.verde),
    ]);
  }

  // ----------------------------------------------------------- tarjetas (móvil)

  Widget _tarjetas() {
    return Column(children: [
      for (final d in _docs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _abrir(d as Map),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(d['codigo_documental'], style: const TextStyle(fontWeight: FontWeight.w800, color: Paleta.azul))),
                    EstadoChip(d['estado']),
                  ]),
                  const SizedBox(height: 6),
                  Text(d['titulo'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${d['tipo_documental']?['departamento']?['nombre'] ?? ''} · ${d['tipo_documental']?['nombre'] ?? ''}', style: const TextStyle(color: Paleta.textoSuave, fontSize: 13)),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 15, color: Paleta.textoSuave),
                    const SizedBox(width: 4),
                    Expanded(child: Text(d['ubicacion']?['etiqueta'] ?? 'Sin ubicación', style: const TextStyle(color: Paleta.textoSuave, fontSize: 13))),
                  ]),
                  const SizedBox(height: 8),
                  _acciones(d),
                ]),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.texto, this.icono, this.alTocar, {this.color = Paleta.azul});
  final String texto;
  final IconData icono;
  final VoidCallback alTocar;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: alTocar,
      icon: Icon(icono, size: 17),
      label: Text(texto),
      style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color.withValues(alpha: .6)), minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 10)),
    );
  }
}
