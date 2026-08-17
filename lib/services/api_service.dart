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

  // Comprobar si existe una versión más reciente del APK móvil en el servidor (Timeout ultra-corto de 3s no bloqueante)
  static Future<Map<String, dynamic>> checkAppVersion() async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.versionCheckAction}");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 3));
      return _safeJsonDecode(response.body, "Asegúrate de haber subido 'api-version-check-action.php' a tu hosting.");
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al verificar la versión del APK: $e"
      };
    }
  }

  // Obtener catálogos para los select (Tipos de Usuario, Oficinas, Programas de Estudio)
  static Future<Map<String, dynamic>> getCatalogos() async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.catalogosAction}");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 20));
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
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 20));
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
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 20));
      return _safeJsonDecode(response.body, "Asegúrate de haber subido 'api-tipos-tramite-action.php' a tu hosting.");
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al obtener requisitos del trámite: $e"
      };
    }
  }

  // Obtener la lista de Mis Trámites del usuario solicitante
  static Future<Map<String, dynamic>> getMisTramites(int solicitanteId) async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.misTramitesAction}&solicitante_id=$solicitanteId");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 20));
      return _safeJsonDecode(response.body, "Asegúrate de haber subido 'api-mis-tramites-action.php' a tu hosting.");
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al conectar para obtener mis trámites: $e"
      };
    }
  }

  // Obtener el detalle completo de un trámite (Información, Archivos, Derivaciones, Comentarios)
  static Future<Map<String, dynamic>> getTramiteDetalle(int tramiteId) async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.tramiteDetalleAction}&tramite_id=$tramiteId");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 20));
      return _safeJsonDecode(response.body, "Asegúrate de haber subido 'api-tramite-detalle-action.php' a tu hosting.");
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al obtener el detalle del trámite: $e"
      };
    }
  }

  // Buscar trámites en tiempo real por N° Expediente, DNI o palabra clave
  static Future<Map<String, dynamic>> buscarTramites(String query) async {
    final String encodedQuery = Uri.encodeComponent(query.trim());
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.buscarTramiteAction}&query=$encodedQuery");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 20));
      return _safeJsonDecode(response.body, "Asegúrate de haber subido 'api-buscar-tramite-action.php' a tu hosting.");
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al conectar con la búsqueda de trámites: $e"
      };
    }
  }

  // Obtener perfil completo y estadísticas del usuario
  static Future<Map<String, dynamic>> getPerfil(int usuarioId) async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.perfilAction}&accion=obtener&usuario_id=$usuarioId");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 20));
      return _safeJsonDecode(response.body, "Asegúrate de haber subido 'api-perfil-action.php' a tu hosting.");
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al obtener perfil del servidor: $e"
      };
    }
  }

  // Actualizar información personal del usuario
  static Future<Map<String, dynamic>> actualizarPerfil({
    required int usuarioId,
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String sexo,
  }) async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.perfilAction}");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "accion": "actualizar_perfil",
          "usuario_id": usuarioId,
          "nombre": nombre,
          "apellido": apellido,
          "correo": correo,
          "telefono": telefono,
          "sexo": sexo,
        }),
      ).timeout(const Duration(seconds: 20));

      final resData = _safeJsonDecode(response.body, "Asegúrate de haber subido 'api-perfil-action.php' a tu hosting.");
      if (resData['status'] == 'success' && resData['data'] != null) {
        UserModel user = UserModel.fromJson(resData['data']);
        await saveUserSession(user);
      }
      return resData;
    } catch (e) {
      return {
        "status": "error",
        "message": "Error de comunicación al actualizar perfil: $e"
      };
    }
  }

  // Cambiar contraseña del usuario
  static Future<Map<String, dynamic>> cambiarPassword({
    required int usuarioId,
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.perfilAction}");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "accion": "cambiar_password",
          "usuario_id": usuarioId,
          "password_actual": passwordActual,
          "password_nueva": passwordNueva,
        }),
      ).timeout(const Duration(seconds: 20));

      return _safeJsonDecode(response.body, "Asegúrate de haber subido 'api-perfil-action.php' a tu hosting.");
    } catch (e) {
      return {
        "status": "error",
        "message": "Error al conectar para cambiar contraseña: $e"
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
      ).timeout(const Duration(seconds: 45));

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

  // Inicio de sesión enviando usuario, DNI o correo y contraseña al backend PHP
  static Future<Map<String, dynamic>> login(String usuario, String password) async {
    final Uri url = Uri.parse("${AppConstants.baseUrl}?action=${AppConstants.loginAction}");

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "usuario": usuario.trim(),
          "password": password,
        }),
      ).timeout(const Duration(seconds: 20));

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
        "message": "Error de comunicación con el servidor ($e). Verifica tu conexión a internet o el backend."
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
      ).timeout(const Duration(seconds: 20));

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
