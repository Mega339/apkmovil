import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class ApiService {
  static const String _userKey = 'current_user_data';

  // Obtener catálogos para los select (Tipos de Usuario, Oficinas, Programas de Estudio)
  static Future<Map<String, dynamic>> getCatalogos() async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.catalogosAction}");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al conectar con los catálogos del servidor: $e"
      };
    }
  }

  // Inicio de sesión enviando usuario y contraseña al backend PHP
  static Future<Map<String, dynamic>> login(String usuario, String password) async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.loginAction}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "usuario": usuario,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData['status'] == 'success') {
        UserModel user = UserModel.fromJson(responseData['data']);
        await saveUserSession(user);
      }

      return responseData;
    } catch (e) {
      return {
        "status": "error",
        "message": "Error de conexión con el servidor. Verifica tu conexión a internet o el servidor backend."
      };
    }
  }

  // Registro de cuenta nueva desde la app móvil (alineado a usuario-view.php)
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String dni,
    required String correo,
    required String telefono,
    required String usuario,
    required String password,
    required int tipoUsuario,
    String? sexo,
    int? oficina,
    int? programasEstudio,
  }) async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.registroAction}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json; charset=UTF-8"},
        body: jsonEncode({
          "nombre": nombre,
          "apellido": apellido,
          "dni": dni,
          "correo": correo,
          "telefono": telefono,
          "sexo": sexo ?? "",
          "usuario": usuario,
          "password": password,
          "tipo_usuario": tipoUsuario,
          "oficina": oficina,
          "programas_estudio": programasEstudio,
        }),
      ).timeout(const Duration(seconds: 12));

      return jsonDecode(response.body);
    } catch (e) {
      return {
        "status": "error",
        "message": "Error de comunicación con el servidor al registrar cuenta: $e"
      };
    }
  }

  // Guardar datos del usuario en sesión local (SharedPreferences)
  static Future<bool> saveUserSession(UserModel user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Obtener usuario actualmente autenticado
  static Future<UserModel?> getCurrentUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(_userKey);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Cerrar sesión
  static Future<bool> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_userKey);
  }
}
