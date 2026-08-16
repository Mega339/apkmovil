import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../config/constants.dart';
import '../models/user_model.dart';

class ApiService {
  static const String _userKey = 'current_user_data';

  // Cabeceras HTTP estándar para evitar bloqueos ModSecurity / WAF
  static final Map<String, String> _headers = {
    "Content-Type": "application/json; charset=UTF-8",
    "Accept": "application/json",
    "User-Agent": "Mozilla/5.0 (Linux; Android 10; Mobile) MobileApp/1.0",
  };

  // Helper para decodificar JSON de forma segura evitando FormatException por páginas HTML o WAF
  static Map<String, dynamic> _safeJsonDecode(String body, String defaultErrorMsg) {
    try {
      return jsonDecode(body);
    } catch (_) {
      String cleanText = body.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleanText.length > 200) {
        cleanText = cleanText.substring(0, 200) + '...';
      }
      return {
        "status": "error",
        "message": cleanText.isNotEmpty 
            ? "Respuesta del servidor: $cleanText"
            : defaultErrorMsg
      };
    }
  }

  // Obtener catálogos para los select (Tipos de Usuario, Oficinas, Programas de Estudio)
  static Future<Map<String, dynamic>> getCatalogos() async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.catalogosAction}");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      return _safeJsonDecode(response.body, "Asegúrate de haber subido 'api-catalogos-action.php' a tu hosting.");
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al conectar con los catálogos del servidor: $e"
      };
    }
  }

  // Obtener tipos de trámites disponibles y siguiente número de expediente
  static Future<Map<String, dynamic>> getTiposTramite() async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.tiposTramiteAction}");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      return _safeJsonDecode(response.body, "Asegúrate de haber subido 'api-tipos-tramite-action.php' a tu hosting.");
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al conectar con los tipos de trámites: $e"
      };
    }
  }

  // Obtener requisitos específicos de un Tipo de Trámite
  static Future<Map<String, dynamic>> getRequisitosPorTipo(int tipoTramiteId) async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.tiposTramiteAction}&tipo_tramite_id=$tipoTramiteId");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      return _safeJsonDecode(response.body, "Asegúrate de haber subido 'api-tipos-tramite-action.php' a tu hosting.");
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al obtener requisitos del trámite: $e"
      };
    }
  }

  // Registrar un Nuevo Trámite desde la App Móvil con archivos adjuntos en Base64
  static Future<Map<String, dynamic>> crearTramite({
    required int solicitanteId,
    required int tipoTramiteId,
    String? asunto,
    String? descripcion,
    Map<int, PlatformFile>? archivosRequisitos,
  }) async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.crearTramiteAction}");

    try {
      List<Map<String, dynamic>> listArchivos = [];
      
      if (archivosRequisitos != null) {
        for (var entry in archivosRequisitos.entries) {
          int reqId = entry.key;
          PlatformFile pFile = entry.value;

          List<int>? bytes;
          if (pFile.bytes != null) {
            bytes = pFile.bytes;
          } else if (pFile.path != null && pFile.path!.isNotEmpty) {
            bytes = await File(pFile.path!).readAsBytes();
          }

          if (bytes != null && bytes.isNotEmpty) {
            String b64 = base64Encode(bytes);
            listArchivos.add({
              "requisito_id": reqId,
              "nombre": pFile.name,
              "base64": b64
            });
          }
        }
      }

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "solicitante": solicitanteId,
          "tipo_tramite": tipoTramiteId,
          "recepcionista": 1,
          "asunto": asunto ?? "",
          "descripcion": descripcion ?? "",
          "archivos_requisitos": listArchivos
        }),
      ).timeout(const Duration(seconds: 35));

      return _safeJsonDecode(
        response.body, 
        "Falta subir el archivo 'api-crear-tramite-action.php' a tu servidor web (sistramite.mallfers.com)."
      );
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al enviar el nuevo trámite: $e"
      };
    }
  }

  // Inicio de sesión enviando usuario y contraseña al backend PHP
  static Future<Map<String, dynamic>> login(String usuario, String password) async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.loginAction}");

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "usuario": usuario,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> responseData = _safeJsonDecode(
        response.body, 
        "Falta subir 'api-login-action.php' o 'Database.php' a tu hosting web."
      );

      if (responseData['status'] == 'success' && responseData['data'] != null) {
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
        headers: _headers,
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

      return _safeJsonDecode(
        response.body, 
        "Falta subir el archivo 'api-registro-action.php' a tu servidor web."
      );
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
