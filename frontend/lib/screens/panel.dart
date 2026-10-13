import 'package:flutter/material.dart';

import '../api.dart';

/// Pantalla de inicio: datos de la sesión y accesos según el rol.
class PanelScreen extends StatelessWidget {
  const PanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = Api.instance.usuario ?? {};
    final texto = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final departamento = u['departamento']?['nombre'];
    final ultimo = DateTime.tryParse(u['ultimo_acceso']?.toString() ?? '')?.toLocal();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Bienvenido, ${u['nombres'] ?? ''}', style: texto.headlineSmall),
        const SizedBox(height: 4),
        Text([Api.instance.rol, ?departamento].join(' · '),
            style: texto.bodyLarge?.copyWith(color: colores.onSurfaceVariant)),
        if (ultimo != null)
          Text('Último acceso: ${_fecha(ultimo)}', style: texto.bodySmall?.copyWith(color: colores.onSurfaceVariant)),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Su perfil', style: texto.titleMedium),
              const SizedBox(height: 12),
              _fila('Usuario', u['nombre_usuario']),
              _fila('Correo', u['correo']),
              _fila('Rol', Api.instance.rol),
              _fila('Departamento', departamento ?? '—'),
            ]),
          ),
        ),
      ],
    );
  }

  static String _fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _fila(String etiqueta, Object? valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 120, child: Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text('${valor ?? '—'}')),
        ]),
      );
}
