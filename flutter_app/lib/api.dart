import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  static const url = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8001',
  );

  static String token = '';

  static Future<dynamic> get(String ruta) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$url$ruta'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));
      return _revisar(respuesta);
    } catch (e) {
      throw Exception('No se pudo consultar la API: $e');
    }
  }

  static Future<dynamic> post(String ruta, Map<String, dynamic> datos) async {
    try {
      final respuesta = await http
          .post(
            Uri.parse('$url$ruta'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(datos),
          )
          .timeout(const Duration(seconds: 12));
      return _revisar(respuesta);
    } catch (e) {
      throw Exception('No se pudo conectar o guardar: $e');
    }
  }

  static Future<dynamic> put(String ruta, Map<String, dynamic> datos) async {
    try {
      final respuesta = await http
          .put(
            Uri.parse('$url$ruta'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(datos),
          )
          .timeout(const Duration(seconds: 12));
      return _revisar(respuesta);
    } catch (e) {
      throw Exception('No se pudo conectar o guardar: $e');
    }
  }

  static Future<dynamic> delete(String ruta) async {
    try {
      final respuesta = await http.delete(
        Uri.parse('$url$ruta'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));
      return _revisar(respuesta);
    } catch (e) {
      throw Exception('No se pudo conectar o eliminar: $e');
    }
  }

  static dynamic _revisar(http.Response respuesta) {
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    if (respuesta.statusCode >= 400) {
      final detalle = datos is Map ? datos['detail'] : 'Error de servidor';
      throw Exception(detalle.toString());
    }
    return datos;
  }
}
