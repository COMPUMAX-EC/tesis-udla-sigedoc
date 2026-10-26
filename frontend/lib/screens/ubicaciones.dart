import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

/// RF-02.3 Ubicaciones físicas del archivo: área, archivador, estante, sección y caja.
class UbicacionesScreen extends StatefulWidget {
  const UbicacionesScreen({super.key});

  @override
  State<UbicacionesScreen> createState() => _UbicacionesScreenState();
}

class _UbicacionesScreenState extends State<UbicacionesScreen> {
  List<dynamic> _items = [];
  String _buscar = '';
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      _items = await Api.instance.get('ubicaciones', {if (_buscar.isNotEmpty) 'buscar': _buscar});
      _error = null;
    } on ApiError catch (e) {
      _error = e.mensaje;
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _editar([Map? u]) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => _Formulario(ubicacion: u));
    if (ok == true) _cargar();
  }

  Future<void> _estado(Map u, bool activo) async {
    try {
      await Api.instance.put('ubicaciones/${u['id_ubicacion']}', {'estado': activo});
      _cargar();
    } on ApiError catch (e) {
      if (mounted) avisar(context, e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Pagina(ancho: 900, children: [
      Row(children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(hintText: 'Buscar por área, archivador o caja…', prefixIcon: Icon(Icons.search)),
            onSubmitted: (v) {
              _buscar = v.trim();
              _cargar();
            },
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(onPressed: () => _editar(), icon: const Icon(Icons.add), label: const Text('Nueva ubicación')),
      ]),
      const SizedBox(height: 16),
      EstadoCarga(
        cargando: _cargando,
        error: _error,
        vacio: _items.isEmpty,
        reintentar: _cargar,
        child: Card(
          child: Column(children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const Divider(),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Paleta.azulClaro, child: Icon(Icons.place_outlined, color: Paleta.azul)),
                title: Text(_items[i]['etiqueta'], style: TextStyle(fontWeight: FontWeight.w600, color: _items[i]['estado'] == true ? Paleta.texto : Paleta.textoSuave)),
                subtitle: _items[i]['descripcion'] == null ? null : Text(_items[i]['descripcion']),
                onTap: () => _editar(_items[i] as Map),
                trailing: Switch(value: _items[i]['estado'] == true, onChanged: (v) => _estado(_items[i] as Map, v)),
              ),
            ],
          ]),
        ),
      ),
    ]);
  }
}

class _Formulario extends StatefulWidget {
  const _Formulario({this.ubicacion});
  final Map? ubicacion;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  late final Map<String, TextEditingController> _c = {
    for (final k in ['area', 'archivador', 'estante', 'seccion', 'caja', 'descripcion']) k: TextEditingController(text: widget.ubicacion?[k]),
  };
  bool _guardando = false;
  String? _error;

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final datos = {for (final e in _c.entries) e.key: e.value.text.trim().isEmpty ? null : e.value.text.trim()};
    try {
      widget.ubicacion == null ? await Api.instance.post('ubicaciones', datos) : await Api.instance.put('ubicaciones/${widget.ubicacion!['id_ubicacion']}', datos);
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      setState(() {
        _error = e.mensaje;
        _guardando = false;
      });
    }
  }

  Widget _campo(String clave, String etiqueta) => TextField(controller: _c[clave], decoration: InputDecoration(labelText: etiqueta));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ubicacion == null ? 'Nueva ubicación' : 'Editar ubicación'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _campo('area', 'Área *'),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _campo('archivador', 'Archivador')), const SizedBox(width: 12), Expanded(child: _campo('estante', 'Estante'))]),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _campo('seccion', 'Sección')), const SizedBox(width: 12), Expanded(child: _campo('caja', 'Caja'))]),
            const SizedBox(height: 12),
            _campo('descripcion', 'Descripción'),
            if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: const TextStyle(color: Paleta.rojo))],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
