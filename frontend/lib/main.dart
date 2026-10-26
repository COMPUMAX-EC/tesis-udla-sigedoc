import 'package:flutter/material.dart';

import 'api.dart';
import 'screens/login.dart';
import 'screens/shell.dart';
import 'theme.dart';

void main() => runApp(const SigedocApp());

class SigedocApp extends StatelessWidget {
  const SigedocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGEDOC · VIALZACHIN E.P.',
      debugShowCheckedModeBanner: false,
      theme: temaSigedoc(),
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
  bool _demo = false;

  @override
  void initState() {
    super.initState();
    Api.esDemo().then((d) => mounted ? setState(() => _demo = d) : null);
    Api.instance.restaurarSesion().then((ok) => setState(() => _autenticado = ok));
  }

  @override
  Widget build(BuildContext context) {
    return switch (_autenticado) {
      null => const Scaffold(body: Center(child: CircularProgressIndicator())),
      true => Shell(demo: _demo, alSalir: () => setState(() => _autenticado = false)),
      false => LoginScreen(demo: _demo, alEntrar: () => setState(() => _autenticado = true)),
    };
  }
}
