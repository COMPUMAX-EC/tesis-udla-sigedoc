import 'package:flutter/material.dart';

import 'api.dart';
import 'screens/login.dart';
import 'screens/shell.dart';

void main() => runApp(const SigedocApp());

class SigedocApp extends StatelessWidget {
  const SigedocApp({super.key});

  static const verde = Color(0xFF1B5E3A);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGEDOC · VIALZACHIN E.P.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: verde, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: verde, brightness: Brightness.dark, useMaterial3: true),
      home: const Inicio(),
    );
  }
}

/// Restaura la sesión guardada y decide entre login y panel principal.
class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  bool? _autenticado;

  @override
  void initState() {
    super.initState();
    Api.instance.restaurarSesion().then((ok) => setState(() => _autenticado = ok));
  }

  @override
  Widget build(BuildContext context) {
    return switch (_autenticado) {
      null => const Scaffold(body: Center(child: CircularProgressIndicator())),
      true => Shell(alSalir: () => setState(() => _autenticado = false)),
      false => LoginScreen(alEntrar: () => setState(() => _autenticado = true)),
    };
  }
}
