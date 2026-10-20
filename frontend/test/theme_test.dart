import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigedoc/theme.dart';

void main() {
  group('formato', () {
    test('fmtFecha y fmtFechaHora usan dd/MM/aaaa', () {
      expect(fmtFecha('2026-03-07'), '07/03/2026');
      expect(fmtFechaHora('2026-03-07T09:05:00'), '07/03/2026 09:05');
      expect(fmtFecha(null), '—');
      expect(fmtFecha('no-es-fecha'), '—');
    });

    test('fmtRelativa distingue hoy, ayer y fechas anteriores', () {
      final ahora = DateTime.now();
      expect(fmtRelativa(ahora.toIso8601String()), startsWith('Hoy, '));
      expect(fmtRelativa(ahora.subtract(const Duration(days: 1)).toIso8601String()), startsWith('Ayer, '));
      expect(fmtRelativa(DateTime(2020, 1, 2, 3, 4).toIso8601String()), '02/01/2020 03:04');
    });

    test('fmtTamano elige la unidad adecuada', () {
      expect(fmtTamano(512), '512 B');
      expect(fmtTamano(2048), '2 KB');
      expect(fmtTamano(5 * 1024 * 1024), '5.0 MB');
    });

    test('nombreCompleto y nombreMovimiento', () {
      expect(nombreCompleto({'nombres': 'Mónica', 'apellidos': 'Carrión'}), 'Mónica Carrión');
      expect(nombreCompleto(null), '—');
      expect(nombreMovimiento('devolucion'), 'Devolución registrada');
      expect(nombreMovimiento('desconocido'), 'desconocido');
    });
  });

  group('componentes', () {
    Future<void> montar(WidgetTester t, Widget w) => t.pumpWidget(MaterialApp(theme: temaSigedoc(), home: Scaffold(body: Center(child: w))));

    testWidgets('EstadoChip muestra el texto del estado y la mora', (t) async {
      await montar(t, const Column(children: [EstadoChip('disponible'), EstadoChip('prestado'), EstadoChip('activo', mora: true)]));
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Prestado'), findsOneWidget);
      expect(find.text('En mora'), findsOneWidget);
    });

    testWidgets('Indicador muestra título, valor y detalle', (t) async {
      await montar(t, const SizedBox(width: 360, child: Indicador(titulo: 'Documentos', valor: 250, icono: Icons.description, color: Paleta.azul, fondo: Paleta.azulClaro, detalle: '238 disponibles')));
      expect(find.text('Documentos'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.text('238 disponibles'), findsOneWidget);
    });

    testWidgets('AvisoDemo advierte que los datos son sintéticos', (t) async {
      await montar(t, const AvisoDemo());
      expect(find.textContaining('datos sintéticos'), findsOneWidget);
    });
  });
}
