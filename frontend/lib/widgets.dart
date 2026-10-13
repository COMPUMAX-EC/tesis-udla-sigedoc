import 'package:flutter/material.dart';

void avisar(BuildContext context, String mensaje) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));

/// Muestra carga, error con reintento o lista vacía antes del contenido.
class EstadoCarga extends StatelessWidget {
  const EstadoCarga({
    super.key,
    required this.cargando,
    required this.error,
    required this.vacio,
    required this.reintentar,
    required this.child,
  });
  final bool cargando;
  final String? error;
  final bool vacio;
  final VoidCallback reintentar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: reintentar, child: const Text('Reintentar')),
        ]),
      );
    }
    if (vacio) return const Center(child: Text('No hay registros.'));
    return child;
  }
}
