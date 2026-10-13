import 'package:flutter_test/flutter_test.dart';
import 'package:sigedoc/api.dart';

void main() {
  test('ApiError toma el primer error de validación de Laravel', () {
    final e = ApiError.desde({
      'message': 'The given data was invalid.',
      'errors': {'usuario': ['Usuario o contraseña incorrectos.']},
    }, 422);
    expect(e.mensaje, 'Usuario o contraseña incorrectos.');
  });

  test('ApiError usa message cuando no hay errores de campo', () {
    expect(ApiError.desde({'message': 'No tiene permisos para esta acción.'}, 403).mensaje,
        'No tiene permisos para esta acción.');
  });
}
