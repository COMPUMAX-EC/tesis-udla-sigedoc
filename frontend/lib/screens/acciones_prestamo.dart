import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

/// Diálogos del ciclo de préstamo (M04). Cada función devuelve `true` si la operación se realizó.

/// RF-04.1 Solicitar préstamo (Funcionario departamental).
Future<bool> solicitarPrestamo(BuildContext context, Map doc) async {
  final motivo = TextEditingController();
  final ok = await _formulario(
    context,
    titulo: 'Solicitar préstamo',
    icono: Icons.handshake_outlined,
    resumen: _resumenDocumento(doc),
    campos: [TextField(controller: motivo, maxLines: 2, maxLength: 250, decoration: const InputDecoration(labelText: 'Motivo de la solicitud'))],
    accion: 'Enviar solicitud',
    enviar: () => Api.instance.post('solicitudes', {'id_documento': doc['id_documento'], 'motivo': motivo.text.trim().isEmpty ? null : motivo.text.trim()}),
  );
  if (ok && context.mounted) avisar(context, 'Solicitud enviada. El responsable del archivo la revisará.');
  return ok;
}

/// RF-04.2 Autorizar o rechazar una solicitud (Responsable del archivo).
Future<bool> resolverSolicitud(BuildContext context, Map solicitud, {required bool aprobar}) async {
  final obs = TextEditingController();
  final ok = await _formulario(
    context,
    titulo: aprobar ? 'Aprobar solicitud' : 'Rechazar solicitud',
    icono: aprobar ? Icons.check_circle_outline : Icons.cancel_outlined,
    resumen: '${_resumenDocumento(solicitud['documento'])}\nSolicitante: ${nombreCompleto(solicitud['solicitante'])}',
    campos: [TextField(controller: obs, maxLines: 2, maxLength: 250, decoration: InputDecoration(labelText: aprobar ? 'Observación (opcional)' : 'Motivo del rechazo'))],
    accion: aprobar ? 'Aprobar' : 'Rechazar',
    peligro: !aprobar,
    enviar: () => Api.instance.post('solicitudes/${solicitud['id_solicitud']}/resolver', {'decision': aprobar ? 'aprobar' : 'rechazar', 'observacion': obs.text.trim().isEmpty ? null : obs.text.trim()}),
  );
  if (ok && context.mounted) avisar(context, aprobar ? 'Solicitud aprobada. Registre la entrega del documento.' : 'Solicitud rechazada.');
  return ok;
}

/// RF-04.3 Registrar préstamo (entrega). Puede partir de una solicitud aprobada o ser directo.
Future<bool> registrarPrestamo(BuildContext context, Map doc, {Map? solicitud}) async {
  List<dynamic> usuarios;
  try {
    usuarios = await Api.instance.get('directorio-usuarios');
  } on ApiError catch (e) {
    if (context.mounted) avisar(context, e.mensaje);
    return false;
  }
  if (!context.mounted) return false;

  int? receptor = solicitud?['id_solicitante'];
  var prevista = DateTime.now().add(const Duration(days: 7));
  final obs = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => StatefulBuilder(builder: (context, setState) {
      return _Dialogo(
        titulo: 'Registrar préstamo',
        icono: Icons.handshake_outlined,
        resumen: _resumenDocumento(doc),
        accion: 'Registrar entrega',
        validar: () => receptor == null ? 'Seleccione quién recibe el documento.' : null,
        enviar: () => Api.instance.post('prestamos', {
          'id_documento': doc['id_documento'],
          'id_receptor': receptor,
          if (solicitud != null) 'id_solicitud': solicitud['id_solicitud'],
          'fecha_devolucion_prevista': prevista.toIso8601String().substring(0, 10),
          'observacion': obs.text.trim().isEmpty ? null : obs.text.trim(),
        }),
        campos: [
          Selector<int>(
            etiqueta: 'Recibe el documento *',
            valor: receptor,
            opciones: [
              for (final u in usuarios)
                DropdownMenuItem(value: u['id_usuario'] as int, child: Text('${nombreCompleto(u)} · ${u['departamento']?['nombre'] ?? 'Sin departamento'}', overflow: TextOverflow.ellipsis)),
            ],
            alCambiar: solicitud != null ? (_) {} : (v) => setState(() => receptor = v),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final f = await showDatePicker(context: context, initialDate: prevista, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 180)));
              if (f != null) setState(() => prevista = f);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Devolución prevista *', suffixIcon: Icon(Icons.calendar_month_outlined)),
              child: Text(fmtFecha(prevista)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(controller: obs, maxLines: 2, maxLength: 250, decoration: const InputDecoration(labelText: 'Observación (opcional)')),
        ],
      );
    }),
  );
  if (ok == true && context.mounted) avisar(context, 'Préstamo registrado. El documento figura como Prestado.');
  return ok == true;
}

/// RF-04.4 Registrar devolución · RF-04.5 Registrar observación de la devolución.
Future<bool> registrarDevolucion(BuildContext context, Map prestamo) async {
  final obs = TextEditingController();
  final ok = await _formulario(
    context,
    titulo: 'Registrar devolución',
    icono: Icons.assignment_return_outlined,
    resumen: '${_resumenDocumento(prestamo['documento'])}\nPrestado a: ${nombreCompleto(prestamo['recibido_por'])}',
    campos: [TextField(controller: obs, maxLines: 3, maxLength: 250, decoration: const InputDecoration(labelText: 'Observaciones del estado físico (novedades)'))],
    accion: 'Registrar devolución',
    enviar: () => Api.instance.post('prestamos/${prestamo['id_prestamo']}/devolver', {'observacion': obs.text.trim().isEmpty ? null : obs.text.trim()}),
  );
  if (ok && context.mounted) avisar(context, 'Devolución registrada. El documento vuelve a estar Disponible.');
  return ok;
}

String _resumenDocumento(Map? d) => d == null ? '' : '${d['codigo_documental']} · ${d['titulo']}';

Future<bool> _formulario(
  BuildContext context, {
  required String titulo,
  required IconData icono,
  required String resumen,
  required List<Widget> campos,
  required String accion,
  required Future<dynamic> Function() enviar,
  bool peligro = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => _Dialogo(titulo: titulo, icono: icono, resumen: resumen, campos: campos, accion: accion, enviar: enviar, peligro: peligro),
  );
  return r == true;
}

class _Dialogo extends StatefulWidget {
  const _Dialogo({required this.titulo, required this.icono, required this.resumen, required this.campos, required this.accion, required this.enviar, this.validar, this.peligro = false});
  final String titulo;
  final IconData icono;
  final String resumen;
  final List<Widget> campos;
  final String accion;
  final Future<dynamic> Function() enviar;
  final String? Function()? validar;
  final bool peligro;

  @override
  State<_Dialogo> createState() => _DialogoState();
}

class _DialogoState extends State<_Dialogo> {
  bool _enviando = false;
  String? _error;

  Future<void> _enviar() async {
    final problema = widget.validar?.call();
    if (problema != null) {
      setState(() => _error = problema);
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await widget.enviar();
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      setState(() {
        _error = e.mensaje;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        Icon(widget.icono, color: widget.peligro ? Paleta.rojo : Paleta.azul),
        const SizedBox(width: 10),
        Expanded(child: Text(widget.titulo)),
      ]),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (widget.resumen.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Paleta.azulClaro, borderRadius: BorderRadius.circular(10)),
                child: Text(widget.resumen, style: const TextStyle(fontWeight: FontWeight.w600, color: Paleta.texto)),
              ),
            ...widget.campos,
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Paleta.rojo, fontWeight: FontWeight.w600)),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _enviando ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: widget.peligro ? FilledButton.styleFrom(backgroundColor: Paleta.rojo) : null,
          onPressed: _enviando ? null : _enviar,
          child: Text(_enviando ? 'Enviando…' : widget.accion),
        ),
      ],
    );
  }
}
