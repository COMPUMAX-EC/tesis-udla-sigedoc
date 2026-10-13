import 'package:flutter/material.dart';

import '../api.dart';
import 'catalogos.dart';
import 'panel.dart';
import 'usuarios.dart';

class Seccion {
  const Seccion(this.titulo, this.icono, this.roles, this.construir);
  final String titulo;
  final IconData icono;

  /// Roles que ven la sección; vacío = todos.
  final List<String> roles;
  final Widget Function() construir;
}

/// Secciones de navegación y roles que pueden verlas.
final secciones = <Seccion>[
  Seccion('Inicio', Icons.dashboard_outlined, const [], () => const PanelScreen()),
  Seccion('Usuarios', Icons.people_outline, const ['Administrador'], () => const UsuariosScreen()),
  Seccion('Roles', Icons.admin_panel_settings_outlined, const ['Administrador'], () => CatalogoScreen(Catalogo.roles)),
  Seccion('Departamentos', Icons.apartment_outlined, const ['Administrador'], () => CatalogoScreen(Catalogo.departamentos)),
  Seccion('Tipos documentales', Icons.description_outlined, const ['Administrador'],
      () => CatalogoScreen(Catalogo.tiposDocumentales)),
];

/// Panel principal con navegación según el rol (wireframe Figura 35).
class Shell extends StatefulWidget {
  const Shell({super.key, required this.alSalir});
  final VoidCallback alSalir;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _actual = 0;

  List<Seccion> get _visibles {
    final rol = Api.instance.rol;
    return secciones.where((s) => s.roles.isEmpty || s.roles.contains(rol)).toList();
  }

  Future<void> _salir() async {
    await Api.instance.logout();
    widget.alSalir();
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;
    final ancho = MediaQuery.sizeOf(context).width >= 800;
    final usuario = Api.instance.usuario ?? {};
    final seccion = visibles[_actual.clamp(0, visibles.length - 1)];

    final menuUsuario = PopupMenuButton<String>(
      tooltip: 'Cuenta',
      icon: CircleAvatar(child: Text((usuario['nombres'] ?? '?').toString().substring(0, 1))),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${usuario['nombres']} ${usuario['apellidos']}'),
            subtitle: Text(Api.instance.rol),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'salir', child: ListTile(leading: Icon(Icons.logout), title: Text('Cerrar sesión'))),
      ],
      onSelected: (v) => v == 'salir' ? _salir() : null,
    );

    final cuerpo = KeyedSubtree(key: ValueKey(seccion.titulo), child: seccion.construir());

    return Scaffold(
      appBar: AppBar(
        title: Text(ancho ? 'SIGEDOC · ${seccion.titulo}' : seccion.titulo),
        actions: [menuUsuario, const SizedBox(width: 8)],
      ),
      drawer: ancho || visibles.length < 2
          ? null
          : NavigationDrawer(
              selectedIndex: _actual,
              onDestinationSelected: (i) {
                setState(() => _actual = i);
                Navigator.pop(context);
              },
              children: [
                const Padding(padding: EdgeInsets.fromLTRB(28, 20, 16, 12), child: Text('SIGEDOC')),
                for (final s in visibles) NavigationDrawerDestination(icon: Icon(s.icono), label: Text(s.titulo)),
              ],
            ),
      body: ancho && visibles.length > 1
          ? Row(children: [
              NavigationRail(
                selectedIndex: _actual,
                onDestinationSelected: (i) => setState(() => _actual = i),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final s in visibles) NavigationRailDestination(icon: Icon(s.icono), label: Text(s.titulo)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: cuerpo),
            ])
          : cuerpo,
    );
  }
}
