import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

/// M06 Reportes: documentos (RF-06.1), préstamos y devoluciones (RF-06.2) y movimientos (RF-06.3),
/// con filtros por fechas y departamento y exportación a CSV.
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  static const _tipos = [('documentos', 'Documentos', Icons.description_outlined), ('prestamos', 'Préstamos y devoluciones', Icons.handshake_outlined), ('movimientos', 'Movimientos', Icons.timeline)];

  String _tipo = 'documentos';
  List<dynamic> _departamentos = [];
  int? _departamento;
  DateTime? _desde, _hasta;
  Map<String, dynamic>? _reporte;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Map<String, String> get _filtros => {
        if (_departamento != null) 'id_departamento': '$_departamento',
        if (_desde != null) 'desde': _desde!.toIso8601String().substring(0, 10),
        if (_hasta != null) 'hasta': _hasta!.toIso8601String().substring(0, 10),
      };

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      if (_departamentos.isEmpty) _departamentos = await Api.instance.get('departamentos');
      _reporte = Map<String, dynamic>.from(await Api.instance.get('reportes/$_tipo', _filtros));
      _error = null;
    } on ApiError catch (e) {
      _error = e.mensaje;
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _fecha(bool desde) async {
    final f = await showDatePicker(context: context, initialDate: (desde ? _desde : _hasta) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (f == null) return;
    setState(() => desde ? _desde = f : _hasta = f);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final r = _reporte;
    return Pagina(children: [
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final (clave, nombre, icono) in _tipos)
          ChoiceChip(
            selected: _tipo == clave,
            avatar: Icon(icono, size: 18, color: _tipo == clave ? Colors.white : Paleta.azul),
            label: Text(nombre),
            labelStyle: TextStyle(color: _tipo == clave ? Colors.white : Paleta.texto, fontWeight: FontWeight.w600),
            selectedColor: Paleta.azul,
            showCheckmark: false,
            onSelected: (_) {
              _tipo = clave;
              _cargar();
            },
          ),
      ]),
      const SizedBox(height: 14),
      Panel(
        child: Wrap(spacing: 14, runSpacing: 14, crossAxisAlignment: WrapCrossAlignment.end, children: [
          SizedBox(
            width: 240,
            child: Selector<int>(
              key: ValueKey('dep$_departamento'),
              etiqueta: 'Departamento',
              valor: _departamento,
              vacio: 'Todos',
              opciones: [for (final d in _departamentos) DropdownMenuItem(value: d['id_departamento'] as int, child: Text(d['nombre']))],
              alCambiar: (v) {
                _departamento = v;
                _cargar();
              },
            ),
          ),
          _CampoFecha('Desde', _desde, () => _fecha(true), () {
            setState(() => _desde = null);
            _cargar();
          }),
          _CampoFecha('Hasta', _hasta, () => _fecha(false), () {
            setState(() => _hasta = null);
            _cargar();
          }),
          OutlinedButton.icon(
            onPressed: r == null ? null : () => abrirEnlace(context, () => Api.instance.post('reportes/$_tipo/enlace-csv', {}..addAll(_filtros))),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Exportar CSV'),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      EstadoCarga(
        cargando: _cargando,
        error: _error,
        vacio: r != null && (r['filas'] as List).isEmpty,
        mensajeVacio: 'No hay datos para los filtros seleccionados.',
        reintentar: _cargar,
        child: r == null ? const SizedBox() : _contenido(r),
      ),
    ]);
  }

  Widget _contenido(Map<String, dynamic> r) {
    final resumen = (r['resumen'] as Map).entries.toList();
    final columnas = (r['columnas'] as List).cast<String>();
    final filas = (r['filas'] as List).cast<List>();
    final visibles = filas.take(200).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 10, runSpacing: 10, children: [
        _Dato('Total', '${r['total']}', Paleta.azul, Paleta.azulClaro),
        for (final e in resumen.take(5)) _Dato(_nombreResumen('${e.key}'), '${e.value}', Paleta.violeta, Paleta.violetaClaro),
      ]),
      const SizedBox(height: 14),
      Card(
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 46,
            dataRowMinHeight: 46,
            dataRowMaxHeight: 64,
            columnSpacing: 22,
            columns: [for (final c in columnas) DataColumn(label: Text(c))],
            rows: [
              for (final f in visibles)
                DataRow(cells: [
                  for (final v in f)
                    DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 320), child: Text('$v', maxLines: 2, overflow: TextOverflow.ellipsis))),
                ]),
            ],
          ),
        ),
      ),
      if (filas.length > visibles.length)
        Padding(padding: const EdgeInsets.only(top: 10), child: Text('Se muestran ${visibles.length} de ${filas.length} filas. Exporte el CSV para ver todas.', style: const TextStyle(color: Paleta.textoSuave))),
    ]);
  }

  static String _nombreResumen(String clave) => clave.isEmpty ? '—' : clave.replaceAll('_', ' ').replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase());
}

class _CampoFecha extends StatelessWidget {
  const _CampoFecha(this.etiqueta, this.valor, this.alTocar, this.alLimpiar);
  final String etiqueta;
  final DateTime? valor;
  final VoidCallback alTocar;
  final VoidCallback alLimpiar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: alTocar,
        child: InputDecorator(
          decoration: InputDecoration(labelText: etiqueta, suffixIcon: valor == null ? const Icon(Icons.calendar_month_outlined) : IconButton(icon: const Icon(Icons.clear), onPressed: alLimpiar)),
          child: Text(valor == null ? 'Cualquiera' : fmtFecha(valor)),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor, this.color, this.fondo);
  final String etiqueta, valor;
  final Color color, fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(etiqueta, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12.5)),
        Text(valor, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 22)),
      ]),
    );
  }
}
