import 'package:flutter/material.dart';

import '../api.dart';
import '../widgets.dart';

/// Configuración de un catálogo simple (nombre, descripción, estado y, opcionalmente, departamento).
class Catalogo {
  const Catalogo(this.ruta, this.singular, this.idCampo, {this.conDepartamento = false});
  final String ruta;
  final String singular;
  final String idCampo;
  final bool conDepartamento;

  static const roles = Catalogo('roles', 'rol', 'id_rol'); // RF-01.3
  static const departamentos = Catalogo('departamentos', 'departamento', 'id_departamento'); // RF-01.4
  static const tiposDocumentales =
      Catalogo('tipos-documentales', 'tipo documental', 'id_tipo_documental', conDepartamento: true); // RF-01.5
}

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen(this.catalogo, {super.key});
  final Catalogo catalogo;

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  List<dynamic> _items = [];
  List<dynamic> _departamentos = [];
  int? _filtroDep;
  bool _cargando = true;
  String? _error;

  Catalogo get c => widget.catalogo;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      if (c.conDepartamento && _departamentos.isEmpty) _departamentos = await Api.instance.get('departamentos');
      _items = await Api.instance.get(c.ruta, {if (_filtroDep != null) 'id_departamento': '$_filtroDep'});
      _error = null;
    } on ApiError catch (e) {
      _error = e.mensaje;
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _editar([Map<String, dynamic>? item]) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioCatalogo(catalogo: c, item: item, departamentos: _departamentos, depInicial: _filtroDep),
    );
    if (guardado == true) _cargar();
  }

  Future<void> _cambiarEstado(Map<String, dynamic> item, bool activo) async {
    try {
      await Api.instance.put('${c.ruta}/${item[c.idCampo]}', {'estado': activo});
      _cargar();
    } on ApiError catch (e) {
      if (mounted) avisar(context, e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(),
        icon: const Icon(Icons.add),
        label: Text('Nuevo ${c.singular}'),
      ),
      body: Column(children: [
        if (c.conDepartamento)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DropdownButtonFormField<int?>(
              initialValue: _filtroDep,
              decoration: const InputDecoration(labelText: 'Departamento', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                for (final d in _departamentos) DropdownMenuItem(value: d['id_departamento'], child: Text(d['nombre'])),
              ],
              onChanged: (v) {
                _filtroDep = v;
                _cargar();
              },
            ),
          ),
        Expanded(
          child: EstadoCarga(
            cargando: _cargando,
            error: _error,
            vacio: _items.isEmpty,
            reintentar: _cargar,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final it = _items[i];
                final sub = [
                  if (c.conDepartamento && _filtroDep == null) it['departamento']?['nombre'],
                  it['descripcion'],
                ].whereType<String>().join(' · ');
                return ListTile(
                  title: Text(it['nombre']),
                  subtitle: sub.isEmpty ? null : Text(sub),
                  onTap: () => _editar(it),
                  trailing: Switch(
                    value: it['estado'] == true,
                    onChanged: (v) => _cambiarEstado(it, v),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class _FormularioCatalogo extends StatefulWidget {
  const _FormularioCatalogo({required this.catalogo, this.item, required this.departamentos, this.depInicial});
  final Catalogo catalogo;
  final Map<String, dynamic>? item;
  final List<dynamic> departamentos;
  final int? depInicial;

  @override
  State<_FormularioCatalogo> createState() => _FormularioCatalogoState();
}

class _FormularioCatalogoState extends State<_FormularioCatalogo> {
  late final _nombre = TextEditingController(text: widget.item?['nombre']);
  late final _descripcion = TextEditingController(text: widget.item?['descripcion']);
  late int? _dep = widget.item?['id_departamento'] ?? widget.depInicial;
  bool _guardando = false;
  String? _error;

  Future<void> _guardar() async {
    final c = widget.catalogo;
    setState(() => _guardando = true);
    final datos = {
      'nombre': _nombre.text.trim(),
      'descripcion': _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
      if (c.conDepartamento) 'id_departamento': _dep,
    };
    try {
      widget.item == null
          ? await Api.instance.post(c.ruta, datos)
          : await Api.instance.put('${c.ruta}/${widget.item![c.idCampo]}', datos);
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      setState(() {
        _error = e.mensaje;
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.catalogo;
    return AlertDialog(
      title: Text(widget.item == null ? 'Nuevo ${c.singular}' : 'Editar ${c.singular}'),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (c.conDepartamento) ...[
            DropdownButtonFormField<int>(
              initialValue: _dep,
              decoration: const InputDecoration(labelText: 'Departamento *', border: OutlineInputBorder()),
              items: [
                for (final d in widget.departamentos)
                  DropdownMenuItem(value: d['id_departamento'], child: Text(d['nombre'])),
              ],
              onChanged: (v) => setState(() => _dep = v),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _nombre,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descripcion,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
