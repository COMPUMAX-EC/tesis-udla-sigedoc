import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Cliente de la API REST de SIGEDOC (RNF-07: los clientes solo hablan con la API).
///
/// En web usa el mismo origen que sirve la app (`/api`); en Android se configura con
/// `--dart-define=API_URL=https://servidor/api`.
class Api {
  Api._();
  static final instance = Api._();

  static const _definida = String.fromEnvironment('API_URL');
  static String get base =>
      _definida.isNotEmpty ? _definida : (kIsWeb ? '${Uri.base.origin}/api' : 'http://10.0.2.2:8000/api');

  String? _token;
  Map<String, dynamic>? usuario;

  String get rol => usuario?['rol']?['nombre'] ?? '';
  bool get esAdmin => rol == 'Administrador';

  Future<bool> restaurarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token == null) return false;
    try {
      usuario = await get('auth/me');
      return true;
    } catch (_) {
      await _guardarToken(null);
      return false;
    }
  }

  Future<void> login(String usuarioOCorreo, String clave) async {
    final r = await post('auth/login', {'usuario': usuarioOCorreo, 'clave': clave, 'dispositivo': kIsWeb ? 'web' : 'movil'});
    usuario = r['usuario'];
    await _guardarToken(r['token']);
  }

  Future<void> logout() async {
    try {
      await post('auth/logout', {});
    } catch (_) {}
    usuario = null;
    await _guardarToken(null);
  }

  Future<void> _guardarToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    token == null ? await prefs.remove('token') : await prefs.setString('token', token);
  }

  Future<dynamic> get(String ruta, [Map<String, String>? query]) =>
      _enviar(http.get(Uri.parse('$base/$ruta').replace(queryParameters: query), headers: _headers));
  Future<dynamic> post(String ruta, Map<String, dynamic> body) =>
      _enviar(http.post(Uri.parse('$base/$ruta'), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> put(String ruta, Map<String, dynamic> body) =>
      _enviar(http.put(Uri.parse('$base/$ruta'), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> delete(String ruta) => _enviar(http.delete(Uri.parse('$base/$ruta'), headers: _headers));

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _enviar(Future<http.Response> peticion) async {
    final http.Response r;
    try {
      r = await peticion;
    } catch (_) {
      throw ApiError('No se pudo conectar con el servidor.');
    }
    final cuerpo = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 200 && r.statusCode < 300) return cuerpo;
    if (r.statusCode == 401) usuario = null;
    throw ApiError.desde(cuerpo, r.statusCode);
  }
}

class ApiError implements Exception {
  ApiError(this.mensaje, [this.status = 0]);
  final String mensaje;
  final int status;

  /// Toma el primer error de validación de Laravel, o el `message` general.
  factory ApiError.desde(dynamic cuerpo, int status) {
    if (cuerpo is Map) {
      final errores = cuerpo['errors'];
      if (errores is Map && errores.isNotEmpty) {
        final primero = errores.values.first;
        return ApiError(primero is List ? primero.first.toString() : primero.toString(), status);
      }
      if (cuerpo['message'] != null) return ApiError(cuerpo['message'].toString(), status);
    }
    return ApiError('Error del servidor ($status).', status);
  }

  @override
  String toString() => mensaje;
}
