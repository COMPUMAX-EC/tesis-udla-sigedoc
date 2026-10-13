import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../widgets.dart';

/// RF-01.2 Gestionar usuarios (crear, consultar, modificar, desactivar).
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<dynamic> _usuarios = [];
  List<dynamic> _roles = [];
  List<dynamic> _departamentos = [];
  String _buscar = '';
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

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      if (_roles.isEmpty) {
        _roles = await Api.instance.get('roles', {'solo_activos': '1'});
        _departamentos = await Api.instance.get('departamentos', {'solo_activos': '1'});
      }
      _usuarios = await Api.instance.get('usuarios', {if (_buscar.isNotEmpty) 'buscar': _buscar});
      _error = null;
    } on ApiError catch (e) {
      _error = e.mensaje;
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _editar([Map<String, dynamic>? u]) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioUsuario(usuario: u, roles: _roles, departamentos: _departamentos),
    );
    if (ok == true) _cargar();
  }

  Future<void> _cambiarEstado(Map<String, dynamic> u, bool activo) async {
    try {
      await Api.instance.put('usuarios/${u['id_usuario']}', {'estado': activo});
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
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Nuevo usuario'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            decoration: const InputDecoration(
                hintText: 'Buscar por nombre, usuario o correo', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onChanged: (v) {
              _espera?.cancel();
              _espera = Timer(const Duration(milliseconds: 350), () {
                _buscar = v.trim();
                _cargar();
              });
            },
          ),
        ),
        Expanded(
          child: EstadoCarga(
            cargando: _cargando,
            error: _error,
            vacio: _usuarios.isEmpty,
            reintentar: _cargar,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
              itemCount: _usuarios.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final u = _usuarios[i];
                final yo = u['id_usuario'] == Api.instance.usuario?['id_usuario'];
                return ListTile(
                  leading: CircleAvatar(child: Text('${u['nombres']}'.substring(0, 1))),
                  title: Text('${u['nombres']} ${u['apellidos']}'),
                  subtitle: Text([
                    u['nombre_usuario'],
                    u['rol']?['nombre'],
                    u['departamento']?['nombre'],
                  ].whereType<String>().join(' · ')),
                  onTap: () => _editar(u),
                  trailing: Tooltip(
                    message: yo ? 'No puede desactivar su propio usuario' : (u['estado'] == true ? 'Activo' : 'Inactivo'),
                    child: Switch(value: u['estado'] == true, onChanged: yo ? null : (v) => _cambiarEstado(u, v)),
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

class _FormularioUsuario extends StatefulWidget {
  const _FormularioUsuario({this.usuario, required this.roles, required this.departamentos});
  final Map<String, dynamic>? usuario;
  final List<dynamic> roles;
  final List<dynamic> departamentos;

  @override
  State<_FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<_FormularioUsuario> {
  late final _nombres = TextEditingController(text: widget.usuario?['nombres']);
  late final _apellidos = TextEditingController(text: widget.usuario?['apellidos']);
  late final _correo = TextEditingController(text: widget.usuario?['correo']);
  late final _usuario = TextEditingController(text: widget.usuario?['nombre_usuario']);
  final _clave = TextEditingController();
  late int? _rol = widget.usuario?['id_rol'];
  late int? _dep = widget.usuario?['id_departamento'];
  bool _guardando = false;
  String? _error;

  bool get _nuevo => widget.usuario == null;

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final datos = {
      'nombres': _nombres.text.trim(),
      'apellidos': _apellidos.text.trim(),
      'correo': _correo.text.trim(),
      'nombre_usuario': _usuario.text.trim(),
      'id_rol': _rol,
      'id_departamento': _dep,
      if (_clave.text.isNotEmpty) 'clave': _clave.text,
    };
    try {
      _nuevo
          ? await Api.instance.post('usuarios', datos)
          : await Api.instance.put('usuarios/${widget.usuario!['id_usuario']}', datos);
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      setState(() {
        _error = e.mensaje;
        _guardando = false;
      });
    }
  }

  Widget _campo(TextEditingController c, String etiqueta, {bool oculto = false, String? ayuda}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          obscureText: oculto,
          decoration: InputDecoration(labelText: etiqueta, helperText: ayuda, border: const OutlineInputBorder()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_nuevo ? 'Nuevo usuario' : 'Editar usuario'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _campo(_nombres, 'Nombres *'),
            _campo(_apellidos, 'Apellidos *'),
            _campo(_correo, 'Correo *'),
            _campo(_usuario, 'Nombre de usuario *'),
            _campo(_clave, _nuevo ? 'Contraseña *' : 'Nueva contraseña',
                oculto: true, ayuda: _nuevo ? 'Mínimo 8 caracteres' : 'Dejar vacío para no cambiarla'),
            DropdownButtonFormField<int>(
              initialValue: _rol,
              decoration: const InputDecoration(labelText: 'Rol *', border: OutlineInputBorder()),
              items: [for (final r in widget.roles) DropdownMenuItem(value: r['id_rol'], child: Text(r['nombre']))],
              onChanged: (v) => setState(() => _rol = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int?>(
              initialValue: _dep,
              decoration: const InputDecoration(labelText: 'Departamento', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                for (final d in widget.departamentos)
                  DropdownMenuItem(value: d['id_departamento'], child: Text(d['nombre'])),
              ],
              onChanged: (v) => setState(() => _dep = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
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
