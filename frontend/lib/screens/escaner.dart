import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'acciones_prestamo.dart';
import 'documento_detalle.dart';

/// RF-03.4 Leer código QR (wireframe Figura 37): cámara con marco de enfoque, ingreso manual
/// del código y ficha del documento con su estado y ubicación (RF-05.3).
class EscanerScreen extends StatefulWidget {
  const EscanerScreen({super.key});

  @override
  State<EscanerScreen> createState() => _EscanerScreenState();
}

class _EscanerScreenState extends State<EscanerScreen> {
  MobileScannerController? _camara;
  Map<String, dynamic>? _documento;
  String? _error;
  bool _consultando = false;
  bool _camaraActiva = true;
  String? _ultimo;

  @override
  void initState() {
    super.initState();
    _camara = MobileScannerController(formats: const [BarcodeFormat.qrCode], detectionSpeed: DetectionSpeed.noDuplicates);
  }

  @override
  void dispose() {
    _camara?.dispose();
    super.dispose();
  }

  Future<void> _resolver(String leido) async {
    if (_consultando || leido == _ultimo) return;
    _ultimo = leido;
    setState(() {
      _consultando = true;
      _error = null;
    });
    try {
      _documento = Map<String, dynamic>.from(await Api.instance.post('qr/resolver', {'codigo': leido}));
    } on ApiError catch (e) {
      _documento = null;
      _error = e.mensaje;
    }
    if (mounted) setState(() => _consultando = false);
  }

  void _reiniciar() => setState(() {
        _documento = null;
        _error = null;
        _ultimo = null;
      });

  Future<void> _manual() async {
    final c = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ingresar código manualmente'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Código del documento', hintText: 'SIGEDOC:xxxxxxxx-xxxx-…'), onSubmitted: (v) => Navigator.pop(context, v)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Consultar'))],
      ),
    );
    if (codigo != null && codigo.trim().isNotEmpty) {
      _ultimo = null;
      _resolver(codigo.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final mostrandoResultado = _documento != null || _error != null || _consultando;
    return Pagina(ancho: 560, children: [
      Panel(
        padding: EdgeInsets.zero,
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(color: Paleta.marino, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
            child: const Text('Escanear código QR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              if (!mostrandoResultado) _visor() else _resultado(),
              const SizedBox(height: 16),
              Row(children: [
                const Expanded(child: Divider()),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.qr_code_2, color: Paleta.azul, size: 30)),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 10),
              Text(mostrandoResultado ? 'Consulta realizada' : 'Coloque el código dentro del recuadro', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Paleta.texto)),
              const SizedBox(height: 14),
              if (mostrandoResultado)
                FilledButton.icon(onPressed: _reiniciar, icon: const Icon(Icons.qr_code_scanner), label: const Text('Escanear otro código'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)))
              else
                OutlinedButton.icon(onPressed: _manual, icon: const Icon(Icons.keyboard_outlined), label: const Text('Ingresar código manual'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48))),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _visor() {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(fit: StackFit.expand, children: [
          if (_camaraActiva)
            MobileScanner(
              controller: _camara,
              onDetect: (captura) {
                final valor = captura.barcodes.firstOrNull?.rawValue;
                if (valor != null) _resolver(valor);
              },
              errorBuilder: (context, error) => _sinCamara(),
            )
          else
            _sinCamara(),
          IgnorePointer(child: CustomPaint(painter: _MarcoPainter())),
        ]),
      ),
    );
  }

  Widget _sinCamara() => Container(
        color: const Color(0xFF1B2433),
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text('No se pudo acceder a la cámara.\nPermita el acceso en el navegador o use «Ingresar código manual».', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        ),
      );

  Widget _resultado() {
    if (_consultando) return const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator());
    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Paleta.rojoClaro, borderRadius: BorderRadius.circular(14), border: Border.all(color: Paleta.rojo.withValues(alpha: .4))),
        child: Column(children: [
          const Icon(Icons.qr_code_scanner, color: Paleta.rojo, size: 40),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Paleta.rojo, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    final d = _documento!;
    final api = Api.instance;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Paleta.fondo, borderRadius: BorderRadius.circular(14), border: Border.all(color: Paleta.borde)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(d['codigo_documental'], style: const TextStyle(fontWeight: FontWeight.w800, color: Paleta.azul, fontSize: 16))),
          EstadoChip(d['estado']),
        ]),
        const SizedBox(height: 6),
        Text(d['titulo'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Dato('Departamento', d['tipo_documental']?['departamento']?['nombre']),
        Dato('Tipo', d['tipo_documental']?['nombre']),
        Dato('Fecha', fmtFecha(d['fecha_documento'])),
        const Divider(),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.place_rounded, color: Paleta.azul),
          const SizedBox(width: 8),
          Expanded(child: Text(d['ubicacion']?['etiqueta'] ?? 'Sin ubicación asignada', style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentoDetalleScreen(id: d['id_documento']))),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ver ficha completa'),
          ),
          if (api.esFuncionario && d['estado'] == 'disponible')
            FilledButton.icon(
              onPressed: () async {
                if (await solicitarPrestamo(context, d)) _reiniciar();
              },
              icon: const Icon(Icons.handshake_outlined),
              label: const Text('Solicitar préstamo'),
            ),
        ]),
      ]),
    );
  }
}

/// Esquinas blancas del recuadro de enfoque.
class _MarcoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lado = size.width * .62;
    final r = Rect.fromCenter(center: size.center(Offset.zero), width: lado, height: lado);
    final largo = lado * .22;
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final (x, y, dx, dy) in [(r.left, r.top, 1.0, 1.0), (r.right, r.top, -1.0, 1.0), (r.left, r.bottom, 1.0, -1.0), (r.right, r.bottom, -1.0, -1.0)]) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * largo, y), p);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * largo), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
