import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import 'catalogos.dart';
import 'documentos.dart';
import 'escaner.dart';
import 'panel.dart';
import 'prestamos.dart';
import 'reportes.dart';
import 'ubicaciones.dart';
import 'usuarios.dart';

class Seccion {
  const Seccion(this.titulo, this.icono, this.roles, this.construir);
  final String titulo;
  final IconData icono;

  /// Roles que ven la sección; vacío = todos.
  final List<String> roles;
  final Widget Function() construir;
}

const _admin = 'Administrador';
const _resp = 'Responsable del archivo';
const _func = 'Funcionario departamental';

/// Secciones de navegación y roles que pueden verlas (docs/usuarios-y-roles.md).
final secciones = <Seccion>[
  Seccion('Inicio', Icons.home_rounded, const [], () => const PanelScreen()),
  Seccion('Documentos', Icons.description_rounded, const [_resp, _func], () => const DocumentosScreen()),
  Seccion('Préstamos', Icons.handshake_rounded, const [_resp, _func], () => const PrestamosScreen()),
  Seccion('Escanear QR', Icons.qr_code_scanner_rounded, const [_resp, _func], () => const EscanerScreen()),
  Seccion('Reportes', Icons.bar_chart_rounded, const [_admin, _resp], () => const ReportesScreen()),
  Seccion('Usuarios', Icons.people_alt_rounded, const [_admin], () => const UsuariosScreen()),
  Seccion('Roles', Icons.admin_panel_settings_rounded, const [_admin], () => CatalogoScreen(Catalogo.roles)),
  Seccion('Departamentos', Icons.apartment_rounded, const [_admin], () => CatalogoScreen(Catalogo.departamentos)),
  Seccion('Tipos documentales', Icons.category_rounded, const [_admin], () => CatalogoScreen(Catalogo.tiposDocumentales)),
  Seccion('Categorías', Icons.label_rounded, const [_admin, _resp], () => CatalogoScreen(Catalogo.categorias)),
  Seccion('Ubicaciones', Icons.place_rounded, const [_admin, _resp], () => const UbicacionesScreen()),
];

/// Permite a cualquier pantalla pedir un cambio de sección (acciones rápidas del panel).
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.ir, required super.child});
  final void Function(String titulo) ir;

  static ShellScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellScope>()!;

  @override
  bool updateShouldNotify(ShellScope old) => false;
}

/// Panel principal con barra lateral azul marino y navegación según el rol (wireframes Figuras 35 y 36).
class Shell extends StatefulWidget {
  const Shell({super.key, required this.alSalir, this.demo = false});
  final VoidCallback alSalir;
  final bool demo;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  String _actual = 'Inicio';
  bool _contraido = false;

  List<Seccion> get _visibles {
    final rol = Api.instance.rol;
    return secciones.where((s) => s.roles.isEmpty || s.roles.contains(rol)).toList();
  }

  void _ir(String titulo) {
    if (_visibles.any((s) => s.titulo == titulo)) setState(() => _actual = titulo);
  }

  Future<void> _salir() async {
    await Api.instance.logout();
    widget.alSalir();
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;
    final seccion = visibles.firstWhere((s) => s.titulo == _actual, orElse: () => visibles.first);
    final escritorio = esEscritorio(context);
    final cuerpo = KeyedSubtree(key: ValueKey(seccion.titulo), child: seccion.construir());

    return ShellScope(
      ir: _ir,
      child: Scaffold(
        drawer: escritorio
            ? null
            : Drawer(
                backgroundColor: Paleta.marino,
                child: SafeArea(
                  child: _Menu(
                    visibles: visibles,
                    actual: seccion.titulo,
                    contraido: false,
                    alElegir: (t) {
                      Navigator.pop(context);
                      _ir(t);
                    },
                  ),
                ),
              ),
        body: Row(children: [
          if (escritorio)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _contraido ? 78 : 264,
              color: Paleta.marino,
              child: _Menu(visibles: visibles, actual: seccion.titulo, contraido: _contraido, alElegir: _ir, alContraer: () => setState(() => _contraido = !_contraido)),
            ),
          Expanded(
            child: Column(children: [
              if (widget.demo) const SafeArea(bottom: false, child: AvisoDemo()),
              _BarraSuperior(titulo: seccion.titulo, escritorio: escritorio, alContraer: () => setState(() => _contraido = !_contraido), alSalir: _salir),
              const Divider(),
              Expanded(child: cuerpo),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.visibles, required this.actual, required this.contraido, required this.alElegir, this.alContraer});
  final List<Seccion> visibles;
  final String actual;
  final bool contraido;
  final void Function(String) alElegir;
  final VoidCallback? alContraer;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(contraido ? 0 : 20, 24, contraido ? 0 : 12, 20),
        child: Row(mainAxisAlignment: contraido ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
          const Icon(Icons.folder_copy_rounded, color: Colors.white, size: 32),
          if (!contraido) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Text('SISTEMA\nDOCUMENTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, height: 1.15, letterSpacing: .4)),
            ),
          ],
        ]),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.symmetric(horizontal: 10), children: [
          for (final s in visibles) _Elemento(seccion: s, activo: s.titulo == actual, contraido: contraido, alTocar: () => alElegir(s.titulo)),
        ]),
      ),
      if (alContraer != null)
        Container(
          alignment: contraido ? Alignment.center : Alignment.centerRight,
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x22FFFFFF)))),
          child: IconButton.filledTonal(
            style: IconButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white),
            tooltip: contraido ? 'Expandir menú' : 'Contraer menú',
            onPressed: alContraer,
            icon: Icon(contraido ? Icons.chevron_right : Icons.chevron_left),
          ),
        ),
    ]);
  }
}

class _Elemento extends StatelessWidget {
  const _Elemento({required this.seccion, required this.activo, required this.contraido, required this.alTocar});
  final Seccion seccion;
  final bool activo;
  final bool contraido;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final contenido = Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: contraido ? 0 : 14),
      decoration: BoxDecoration(color: activo ? Paleta.azul : Colors.transparent, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: contraido ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
        Icon(seccion.icono, color: Colors.white.withValues(alpha: activo ? 1 : .8), size: 24),
        if (!contraido) ...[
          const SizedBox(width: 14),
          Expanded(
            child: Text(seccion.titulo,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withValues(alpha: activo ? 1 : .85), fontWeight: activo ? FontWeight.w700 : FontWeight.w500, fontSize: 15.5)),
          ),
        ],
      ]),
    );
    return Tooltip(
      message: contraido ? seccion.titulo : '',
      child: InkWell(borderRadius: BorderRadius.circular(10), onTap: alTocar, child: contenido),
    );
  }
}

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({required this.titulo, required this.escritorio, required this.alContraer, required this.alSalir});
  final String titulo;
  final bool escritorio;
  final VoidCallback alContraer;
  final VoidCallback alSalir;

  @override
  Widget build(BuildContext context) {
    final u = Api.instance.usuario ?? {};
    final inicial = '${u['nombres'] ?? '?'}'.isEmpty ? '?' : '${u['nombres']}'.substring(0, 1).toUpperCase();
    return Container(
      color: Colors.white,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        escritorio
            ? IconButton(onPressed: alContraer, icon: const Icon(Icons.menu), tooltip: 'Menú')
            : Builder(builder: (c) => IconButton(onPressed: () => Scaffold.of(c).openDrawer(), icon: const Icon(Icons.menu), tooltip: 'Menú')),
        const SizedBox(width: 6),
        Expanded(child: Text(titulo, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Paleta.texto))),
        PopupMenuButton<String>(
          tooltip: 'Cuenta',
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nombreCompleto(u), style: const TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto)),
                Text(Api.instance.rol, style: const TextStyle(color: Paleta.textoSuave, fontSize: 13)),
                if (u['departamento']?['nombre'] != null) Text('${u['departamento']['nombre']}', style: const TextStyle(color: Paleta.textoSuave, fontSize: 13)),
              ]),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'salir', child: ListTile(dense: true, leading: Icon(Icons.logout), title: Text('Cerrar sesión'))),
          ],
          onSelected: (v) => v == 'salir' ? alSalir() : null,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 19, backgroundColor: Paleta.azul, child: Text(inicial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            if (escritorio) ...[
              const SizedBox(width: 10),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${u['nombres'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto, fontSize: 14)),
                Text(Api.instance.rol, style: const TextStyle(color: Paleta.textoSuave, fontSize: 12)),
              ]),
              const Icon(Icons.keyboard_arrow_down, color: Paleta.textoSuave),
            ],
          ]),
        ),
        const SizedBox(width: 4),
      ]),
    );
  }
}
