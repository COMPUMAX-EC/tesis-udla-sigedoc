import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

/// RF-02.1 Registrar · RF-02.2 Clasificar · RF-02.3 Asignar ubicación · RF-02.4 Actualizar documento.
/// Al registrar, el sistema genera el código institucional, el identificador único y el código QR.
class DocumentoFormScreen extends StatefulWidget {
  const DocumentoFormScreen({super.key, this.documento});
  final Map<String, dynamic>? documento;

  @override
  State<DocumentoFormScreen> createState() => _DocumentoFormScreenState();
}

class _DocumentoFormScreenState extends State<DocumentoFormScreen> {
  final _clave = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.documento?['titulo']);
  late final _descripcion = TextEditingController(text: widget.documento?['descripcion']);
  List<dynamic> _departamentos = [], _tipos = [], _categorias = [], _ubicaciones = [];
  int? _departamento, _tipo, _categoria, _ubicacion;
  late String _acceso = widget.documento?['nivel_acceso'] ?? 'interno';
  DateTime? _fecha;
  bool _cargando = true, _guardando = false;
  String? _error;

  bool get _edita => widget.documento != null;

  @override
  void initState() {
    super.initState();
    final d = widget.documento;
    _tipo = d?['id_tipo_documental'];
    _departamento = d?['tipo_documental']?['id_departamento'];
    _categoria = d?['id_categoria'];
    _ubicacion = d?['id_ubicacion'];
    _fecha = DateTime.tryParse('${d?['fecha_documento'] ?? ''}');
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final api = Api.instance;
      _departamentos = await api.get('departamentos', {'solo_activos': '1'});
      _tipos = await api.get('tipos-documentales');
      _categorias = await api.get('categorias', {'solo_activos': '1'});
      _ubicaciones = await api.get('ubicaciones', {'solo_activos': '1'});
      _error = null;
    } on ApiError catch (e) {
      _error = e.mensaje;
    }
    if (mounted) setState(() => _cargando = false);
  }

  List<dynamic> get _tiposDelDepartamento => _tipos.where((t) => t['estado'] == true && t['id_departamento'] == _departamento).toList();

  Future<void> _guardar() async {
    if (!_clave.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final datos = {
      'id_tipo_documental': _tipo,
      'id_categoria': _categoria,
      'id_ubicacion': _ubicacion,
      'titulo': _titulo.text.trim(),
      'descripcion': _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
      'fecha_documento': _fecha?.toIso8601String().substring(0, 10),
      'nivel_acceso': _acceso,
    };
    try {
      final r = _edita
          ? await Api.instance.put('documentos/${widget.documento!['id_documento']}', datos)
          : await Api.instance.post('documentos', datos);
      if (!mounted) return;
      avisar(context, _edita ? 'Documento actualizado.' : 'Documento registrado como ${r['codigo_documental']}. Código QR generado.');
      Navigator.pop(context, true);
    } on ApiError catch (e) {
      setState(() {
        _error = e.mensaje;
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_edita ? 'Editar ${widget.documento!['codigo_documental']}' : 'Nuevo documento')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Pagina(ancho: 820, children: [
              Panel(
                child: Form(
                  key: _clave,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Clasificación', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    LayoutBuilder(builder: (context, c) {
                      final dep = Selector<int>(
                        key: ValueKey('dep$_departamento'),
                        etiqueta: 'Departamento de origen *',
                        valor: _departamento,
                        validar: (v) => v == null ? 'Seleccione el departamento' : null,
                        opciones: [for (final d in _departamentos) DropdownMenuItem(value: d['id_departamento'] as int, child: Text(d['nombre']))],
                        alCambiar: (v) => setState(() {
                          _departamento = v;
                          _tipo = null;
                        }),
                      );
                      final tipo = Selector<int>(
                        key: ValueKey('tipo$_departamento$_tipo'),
                        etiqueta: 'Tipo documental *',
                        valor: _tipo,
                        validar: (v) => v == null ? 'Seleccione el tipo documental' : null,
                        opciones: [for (final t in _tiposDelDepartamento) DropdownMenuItem(value: t['id_tipo_documental'] as int, child: Text(t['nombre']))],
                        alCambiar: (v) => setState(() => _tipo = v),
                      );
                      return c.maxWidth >= 600
                          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: dep), const SizedBox(width: 14), Expanded(child: tipo)])
                          : Column(children: [dep, const SizedBox(height: 14), tipo]);
                    }),
                    const SizedBox(height: 14),
                    Selector<int>(
                      etiqueta: 'Categoría',
                      valor: _categoria,
                      vacio: 'Sin categoría',
                      opciones: [for (final c in _categorias) DropdownMenuItem(value: c['id_categoria'] as int, child: Text(c['nombre']))],
                      alCambiar: (v) => _categoria = v,
                    ),
                    const SizedBox(height: 26),
                    const Text('Datos del documento', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titulo,
                      maxLength: 200,
                      decoration: const InputDecoration(labelText: 'Título o asunto *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese el título' : null,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(controller: _descripcion, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción')),
                    const SizedBox(height: 14),
                    LayoutBuilder(builder: (context, c) {
                      final fecha = InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final f = await showDatePicker(context: context, initialDate: _fecha ?? DateTime.now(), firstDate: DateTime(1990), lastDate: DateTime.now());
                          if (f != null) setState(() => _fecha = f);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(labelText: 'Fecha del documento', suffixIcon: _fecha == null ? const Icon(Icons.calendar_month_outlined) : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _fecha = null))),
                          child: Text(_fecha == null ? 'Sin fecha' : fmtFecha(_fecha)),
                        ),
                      );
                      final acceso = Selector<String>(
                        etiqueta: 'Nivel de acceso',
                        valor: _acceso,
                        opciones: const [
                          DropdownMenuItem(value: 'publico', child: Text('Público')),
                          DropdownMenuItem(value: 'interno', child: Text('Interno')),
                          DropdownMenuItem(value: 'confidencial', child: Text('Confidencial (solo su departamento)')),
                        ],
                        alCambiar: (v) => _acceso = v ?? 'interno',
                      );
                      return c.maxWidth >= 600
                          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: fecha), const SizedBox(width: 14), Expanded(child: acceso)])
                          : Column(children: [fecha, const SizedBox(height: 14), acceso]);
                    }),
                    const SizedBox(height: 26),
                    const Text('Ubicación física', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    Selector<int>(
                      etiqueta: 'Dónde se archiva',
                      valor: _ubicacion,
                      vacio: 'Sin ubicación asignada',
                      opciones: [for (final u in _ubicaciones) DropdownMenuItem(value: u['id_ubicacion'] as int, child: Text(u['etiqueta'], overflow: TextOverflow.ellipsis))],
                      alCambiar: (v) => _ubicacion = v,
                    ),
                    if (!_edita)
                      const Padding(
                        padding: EdgeInsets.only(top: 18),
                        child: Row(children: [
                          Icon(Icons.qr_code_2, color: Paleta.violeta),
                          SizedBox(width: 10),
                          Expanded(child: Text('Al guardar se generará el código institucional y el código QR para imprimir la etiqueta.', style: TextStyle(color: Paleta.textoSuave))),
                        ]),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!, style: const TextStyle(color: Paleta.rojo, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 22),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(onPressed: _guardando ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      const SizedBox(width: 10),
                      FilledButton.icon(onPressed: _guardando ? null : _guardar, icon: const Icon(Icons.save_outlined), label: Text(_guardando ? 'Guardando…' : (_edita ? 'Guardar cambios' : 'Registrar documento'))),
                    ]),
                  ]),
                ),
              ),
            ]),
    );
  }
}
