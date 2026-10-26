import 'package:flutter/material.dart';

/// Sistema de diseño de SIGEDOC, tomado de los wireframes del Capítulo 3 de la tesis
/// (Figuras 34–37): barra lateral azul marino, azul de acción, tarjetas claras y estados con color.
class Paleta {
  static const marino = Color(0xFF0A2A5E);
  static const marinoOscuro = Color(0xFF071E45);
  static const azul = Color(0xFF0B57C9);
  static const azulClaro = Color(0xFFE6EEFB);
  static const fondo = Color(0xFFF3F6FB);
  static const borde = Color(0xFFD9E1EF);
  static const texto = Color(0xFF0F1F3D);
  static const textoSuave = Color(0xFF5A6B8C);
  static const verde = Color(0xFF1E8E4E);
  static const verdeClaro = Color(0xFFE8F5EC);
  static const naranja = Color(0xFFE08A0B);
  static const naranjaClaro = Color(0xFFFFF4DD);
  static const rojo = Color(0xFFC62828);
  static const rojoClaro = Color(0xFFFDECEC);
  static const violeta = Color(0xFF5B3FC4);
  static const violetaClaro = Color(0xFFEFEBFB);
}

ThemeData temaSigedoc() {
  final esquema = ColorScheme.fromSeed(seedColor: Paleta.azul, brightness: Brightness.light).copyWith(
    primary: Paleta.azul,
    onPrimary: Colors.white,
    secondary: Paleta.marino,
    surface: Colors.white,
    onSurface: Paleta.texto,
    surfaceContainerLow: Paleta.fondo,
    outline: Paleta.borde,
    error: Paleta.rojo,
  );
  final campo = OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Paleta.borde));
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Paleta.fondo,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Paleta.texto,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: Paleta.texto, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Paleta.borde)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: campo,
      enabledBorder: campo,
      focusedBorder: campo.copyWith(borderSide: const BorderSide(color: Paleta.azul, width: 1.6)),
      errorBorder: campo.copyWith(borderSide: const BorderSide(color: Paleta.rojo)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Paleta.azul,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Paleta.azul,
        minimumSize: const Size(0, 42),
        side: const BorderSide(color: Paleta.azul),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Paleta.borde, space: 1, thickness: 1),
    dataTableTheme: const DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(Paleta.azulClaro),
      headingTextStyle: TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Paleta.azul,
      unselectedLabelColor: Paleta.textoSuave,
      indicatorColor: Paleta.azul,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Paleta.marino,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

/// Punto de corte entre diseño de escritorio (barra lateral) y móvil (menú desplegable).
const anchoEscritorio = 900.0;

bool esEscritorio(BuildContext context) => MediaQuery.sizeOf(context).width >= anchoEscritorio;

// ---------------------------------------------------------------- formato

String _dos(int n) => n.toString().padLeft(2, '0');

String fmtFecha(Object? valor) {
  final d = DateTime.tryParse('${valor ?? ''}')?.toLocal();
  return d == null ? '—' : '${_dos(d.day)}/${_dos(d.month)}/${d.year}';
}

String fmtFechaHora(Object? valor) {
  final d = DateTime.tryParse('${valor ?? ''}')?.toLocal();
  return d == null ? '—' : '${_dos(d.day)}/${_dos(d.month)}/${d.year} ${_dos(d.hour)}:${_dos(d.minute)}';
}

/// "Hoy, 10:32", "Ayer, 16:45" o la fecha completa.
String fmtRelativa(Object? valor) {
  final d = DateTime.tryParse('${valor ?? ''}')?.toLocal();
  if (d == null) return '—';
  final hoy = DateTime.now();
  final dias = DateTime(hoy.year, hoy.month, hoy.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  final hora = '${_dos(d.hour)}:${_dos(d.minute)}';
  if (dias == 0) return 'Hoy, $hora';
  if (dias == 1) return 'Ayer, $hora';
  return fmtFechaHora(d);
}

String fmtTamano(Object? bytes) {
  final b = (bytes is num) ? bytes.toDouble() : double.tryParse('$bytes') ?? 0;
  if (b < 1024) return '${b.toInt()} B';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
}

String nombreCompleto(Map? u) => u == null ? '—' : '${u['nombres'] ?? ''} ${u['apellidos'] ?? ''}'.trim();

const _nombresMovimiento = {
  'registro': 'Documento registrado',
  'actualizacion': 'Documento actualizado',
  'cambio_ubicacion': 'Cambio de ubicación',
  'qr_generado': 'Código QR generado',
  'consulta_qr': 'Consulta por código QR',
  'archivo_adjunto': 'Archivo adjuntado',
  'archivo_eliminado': 'Archivo eliminado',
  'solicitud': 'Solicitud de préstamo',
  'solicitud_aprobada': 'Solicitud aprobada',
  'solicitud_rechazada': 'Solicitud rechazada',
  'prestamo': 'Préstamo realizado',
  'devolucion': 'Devolución registrada',
  'baja': 'Documento dado de baja',
  'reactivacion': 'Documento reactivado',
};

String nombreMovimiento(Object? tipo) => _nombresMovimiento['$tipo'] ?? '$tipo';

({IconData icono, Color color, Color fondo}) estiloMovimiento(Object? tipo) => switch ('$tipo') {
      'prestamo' => (icono: Icons.handshake_outlined, color: Paleta.verde, fondo: Paleta.verdeClaro),
      'devolucion' => (icono: Icons.assignment_return_outlined, color: Paleta.verde, fondo: Paleta.verdeClaro),
      'solicitud' => (icono: Icons.notifications_active_outlined, color: Paleta.naranja, fondo: Paleta.naranjaClaro),
      'solicitud_aprobada' => (icono: Icons.check_circle_outline, color: Paleta.verde, fondo: Paleta.verdeClaro),
      'solicitud_rechazada' => (icono: Icons.cancel_outlined, color: Paleta.rojo, fondo: Paleta.rojoClaro),
      'qr_generado' || 'consulta_qr' => (icono: Icons.qr_code_2, color: Paleta.violeta, fondo: Paleta.violetaClaro),
      'baja' => (icono: Icons.archive_outlined, color: Paleta.rojo, fondo: Paleta.rojoClaro),
      'cambio_ubicacion' => (icono: Icons.place_outlined, color: Paleta.azul, fondo: Paleta.azulClaro),
      _ => (icono: Icons.description_outlined, color: Paleta.azul, fondo: Paleta.azulClaro),
    };

// ---------------------------------------------------------------- componentes

/// Etiqueta de estado con punto de color (Disponible, Prestado, Pendiente…).
class EstadoChip extends StatelessWidget {
  const EstadoChip(this.estado, {super.key, this.mora = false});
  final String estado;
  final bool mora;

  @override
  Widget build(BuildContext context) {
    final (texto, color, fondo) = mora
        ? ('En mora', Paleta.rojo, Paleta.rojoClaro)
        : switch (estado) {
            'disponible' => ('Disponible', Paleta.verde, Paleta.verdeClaro),
            'prestado' => ('Prestado', Paleta.naranja, Paleta.naranjaClaro),
            'de_baja' => ('De baja', Paleta.textoSuave, const Color(0xFFEAEEF5)),
            'pendiente' => ('Pendiente', Paleta.naranja, Paleta.naranjaClaro),
            'aprobada' => ('Aprobada', Paleta.verde, Paleta.verdeClaro),
            'rechazada' => ('Rechazada', Paleta.rojo, Paleta.rojoClaro),
            'activo' => ('Activo', Paleta.azul, Paleta.azulClaro),
            'devuelto' => ('Devuelto', Paleta.verde, Paleta.verdeClaro),
            _ => (estado, Paleta.textoSuave, const Color(0xFFEAEEF5)),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .35))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ]),
    );
  }
}

/// Indicador del panel principal (Documentos / Préstamos / Pendientes).
class Indicador extends StatelessWidget {
  const Indicador({super.key, required this.titulo, required this.valor, required this.icono, required this.color, required this.fondo, this.detalle, this.alTocar});
  final String titulo;
  final Object valor;
  final IconData icono;
  final Color color;
  final Color fondo;
  final String? detalle;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: alTocar,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: fondo.withValues(alpha: .55), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: .22))),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: const TextStyle(color: Paleta.texto, fontWeight: FontWeight.w600)),
              Text('$valor', style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
              if (detalle != null) Text(detalle!, style: const TextStyle(color: Paleta.textoSuave, fontSize: 12.5)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Tarjeta con título, para agrupar contenido.
class Panel extends StatelessWidget {
  const Panel({super.key, this.titulo, required this.child, this.accion, this.padding = const EdgeInsets.all(20)});
  final String? titulo;
  final Widget child;
  final Widget? accion;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (titulo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                Expanded(child: Text(titulo!, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Paleta.texto))),
                ?accion,
              ]),
            ),
          child,
        ]),
      ),
    );
  }
}

/// Banner que avisa que los datos son sintéticos (entorno de demostración).
class AvisoDemo extends StatelessWidget {
  const AvisoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: Paleta.naranjaClaro,
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.science_outlined, size: 16, color: Paleta.naranja),
        SizedBox(width: 8),
        Flexible(
          child: Text('Entorno de demostración · datos sintéticos, no corresponden a registros reales',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Color(0xFF7A4A00), fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
