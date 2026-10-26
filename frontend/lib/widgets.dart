import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'theme.dart';

void avisar(BuildContext context, String mensaje) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));

/// Pide una URL temporal firmada a la API (`ruta` con POST o GET) y la abre en el navegador.
/// Se usa para etiquetas imprimibles, descargas de archivos y exportaciones CSV.
Future<void> abrirEnlace(BuildContext context, Future<dynamic> Function() pedir) async {
  try {
    final r = await pedir();
    final ok = await launchUrl(Uri.parse(r['url']), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) avisar(context, 'No se pudo abrir el enlace.');
  } on ApiError catch (e) {
    if (context.mounted) avisar(context, e.mensaje);
  }
}

Future<bool> confirmar(BuildContext context, String titulo, String mensaje, {String accion = 'Confirmar', bool peligro = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: peligro ? FilledButton.styleFrom(backgroundColor: Paleta.rojo) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(accion),
        ),
      ],
    ),
  );
  return r == true;
}

/// Página desplazable con ancho máximo centrado y relleno uniforme.
class Pagina extends StatelessWidget {
  const Pagina({super.key, required this.children, this.ancho = 1280, this.controlador});
  final List<Widget> children;
  final double ancho;
  final ScrollController? controlador;

  @override
  Widget build(BuildContext context) {
    final compacto = !esEscritorio(context);
    return SingleChildScrollView(
      controller: controlador,
      padding: EdgeInsets.all(compacto ? 12 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ancho),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

/// Muestra carga, error con reintento o lista vacía antes del contenido.
class EstadoCarga extends StatelessWidget {
  const EstadoCarga({
    super.key,
    required this.cargando,
    required this.error,
    required this.vacio,
    required this.reintentar,
    required this.child,
    this.mensajeVacio = 'No hay registros.',
  });
  final bool cargando;
  final String? error;
  final bool vacio;
  final VoidCallback reintentar;
  final Widget child;
  final String mensajeVacio;

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: Paleta.textoSuave),
            const SizedBox(height: 8),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: reintentar, child: const Text('Reintentar')),
          ]),
        ),
      );
    }
    if (vacio) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.inbox_outlined, size: 44, color: Paleta.textoSuave),
            const SizedBox(height: 8),
            Text(mensajeVacio, style: const TextStyle(color: Paleta.textoSuave)),
          ]),
        ),
      );
    }
    return child;
  }
}

/// Paginación basada en la respuesta paginada de Laravel (`current_page`, `last_page`, `total`).
class Paginador extends StatelessWidget {
  const Paginador({super.key, required this.pagina, required this.ultima, required this.total, required this.cambiar});
  final int pagina;
  final int ultima;
  final int total;
  final ValueChanged<int> cambiar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          Text('$total registros', style: const TextStyle(color: Paleta.textoSuave)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(onPressed: pagina > 1 ? () => cambiar(pagina - 1) : null, icon: const Icon(Icons.chevron_left), tooltip: 'Anterior'),
            Text('Página $pagina de $ultima'),
            IconButton(onPressed: pagina < ultima ? () => cambiar(pagina + 1) : null, icon: const Icon(Icons.chevron_right), tooltip: 'Siguiente'),
          ]),
        ],
      ),
    );
  }
}

/// Fila "etiqueta: valor" para fichas de detalle.
class Dato extends StatelessWidget {
  const Dato(this.etiqueta, this.valor, {super.key});
  final String etiqueta;
  final Object? valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 140, child: Text(etiqueta, style: const TextStyle(color: Paleta.textoSuave, fontWeight: FontWeight.w600))),
        Expanded(child: SelectableText('${valor ?? '—'}'.isEmpty ? '—' : '${valor ?? '—'}')),
      ]),
    );
  }
}

/// Campo de selección de un catálogo (`[{id, nombre}]`) con opción "Todos/Ninguno" opcional.
class Selector<T> extends StatelessWidget {
  const Selector({super.key, required this.etiqueta, required this.valor, required this.opciones, required this.alCambiar, this.vacio, this.validar});
  final String etiqueta;
  final T? valor;
  final List<DropdownMenuItem<T>> opciones;
  final ValueChanged<T?> alCambiar;
  final String? vacio;
  final String? Function(T?)? validar;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: valor,
      isExpanded: true,
      decoration: InputDecoration(labelText: etiqueta),
      validator: validar,
      items: [
        if (vacio != null) DropdownMenuItem<T>(value: null, child: Text(vacio!)),
        ...opciones,
      ],
      onChanged: alCambiar,
    );
  }
}
