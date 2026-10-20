import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';

/// RF-01.1 Iniciar sesión (wireframe Figura 34).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.alEntrar, this.demo = false});
  final VoidCallback alEntrar;
  final bool demo;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;
  bool _verClave = false;
  String? _error;

  Future<void> _entrar() async {
    if (_usuario.text.trim().isEmpty || _clave.text.isEmpty) {
      setState(() => _error = 'Ingrese usuario y contraseña.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await Api.instance.login(_usuario.text.trim(), _clave.text);
      widget.alEntrar();
    } on ApiError catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEAF2FF), Color(0xFFCFE0FA)]),
        ),
        child: Column(children: [
          if (widget.demo) const SafeArea(bottom: false, child: AvisoDemo()),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    elevation: 8,
                    shadowColor: Paleta.marino.withValues(alpha: .18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: const BoxDecoration(color: Paleta.azulClaro, shape: BoxShape.circle),
                                child: const Icon(Icons.folder_copy_rounded, size: 44, color: Paleta.azul),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text('SISTEMA DOCUMENTAL',
                                textAlign: TextAlign.center, style: TextStyle(color: Paleta.marino, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: .5)),
                            const SizedBox(height: 4),
                            const Text('SIGEDOC · VIALZACHIN E.P.', textAlign: TextAlign.center, style: TextStyle(color: Paleta.textoSuave)),
                            const SizedBox(height: 26),
                            const Text('Usuario o correo', style: TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _usuario,
                              autofillHints: const [AutofillHints.username],
                              decoration: const InputDecoration(hintText: 'Ingrese su usuario o correo', prefixIcon: Icon(Icons.person_outline, color: Paleta.azul)),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _clave,
                              obscureText: !_verClave,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                hintText: 'Ingrese su contraseña',
                                prefixIcon: const Icon(Icons.lock_outline, color: Paleta.azul),
                                suffixIcon: IconButton(
                                  tooltip: _verClave ? 'Ocultar contraseña' : 'Mostrar contraseña',
                                  icon: Icon(_verClave ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  onPressed: () => setState(() => _verClave = !_verClave),
                                ),
                              ),
                              onSubmitted: (_) => _entrar(),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Paleta.rojoClaro, borderRadius: BorderRadius.circular(10), border: Border.all(color: Paleta.rojo.withValues(alpha: .4))),
                                child: Row(children: [
                                  const Icon(Icons.error_outline, color: Paleta.rojo, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(_error!, style: const TextStyle(color: Paleta.rojo))),
                                ]),
                              ),
                            ],
                            const SizedBox(height: 22),
                            FilledButton.icon(
                              onPressed: _cargando ? null : _entrar,
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                              icon: _cargando ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.login),
                              label: Text(_cargando ? 'Ingresando…' : 'INICIAR SESIÓN'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
