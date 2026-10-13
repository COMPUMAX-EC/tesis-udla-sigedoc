import 'package:flutter/material.dart';

import '../api.dart';

/// RF-01.1 Iniciar sesión (wireframe Figura 34).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.alEntrar});
  final VoidCallback alEntrar;

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
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colores.surfaceContainerLow,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.folder_copy_outlined, size: 48, color: colores.primary),
                      const SizedBox(height: 12),
                      Text('SIGEDOC', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                      Text('Sistema de Gestión Documental\nVIALZACHIN E.P.',
                          textAlign: TextAlign.center, style: TextStyle(color: colores.onSurfaceVariant)),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _usuario,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                            labelText: 'Usuario o correo', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _clave,
                        obscureText: !_verClave,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _verClave = !_verClave),
                          ),
                        ),
                        onSubmitted: (_) => _entrar(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: colores.error)),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _cargando ? null : _entrar,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        child: _cargando
                            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Iniciar sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
