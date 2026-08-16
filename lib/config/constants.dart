import 'package:flutter/material.dart';

class AppConstants {
  // Configuración de la URL base del servidor backend PHP en producción
  static const String baseUrl = "https://sistramite.mallfers.com/index.php"; 
  static const String fallbackUrl = "http://localhost/sistramite/index.php";

  // Endpoints API
  static const String loginAction = "api-login";
  static const String registroAction = "api-registro";
  static const String catalogosAction = "api-catalogos";
  static const String tiposTramiteAction = "api-tipos-tramite";
  static const String crearTramiteAction = "api-crear-tramite";
  static const String misTramitesAction = "api-mis-tramites";
  static const String tramiteDetalleAction = "api-tramite-detalle";

  // Paleta de Colores Institucionales de Alta Estética
  static const Color primaryNavy = Color(0xFF1D2939);     // Azul Marino Profundo
  static const Color primaryBlue = Color(0xFF0052CC);     // Azul Primario
  static const Color accentCyan = Color(0xFF00B8D9);      // Cian Acento
  static const Color bgLight = Color(0xFFF4F6F9);         // Fondo Claro Suave
  static const Color cardWhite = Color(0xFFFFFFFF);       // Tarjeta Blanca
  static const Color textDark = Color(0xFF101828);        // Texto Oscuro
  static const Color textMuted = Color(0xFF667085);       // Texto Secundario
  static const Color successGreen = Color(0xFF12B76A);    // Verde Éxito
  static const Color dangerRed = Color(0xFFF04438);       // Rojo Error
  static const Color warningOrange = Color(0xFFF79009);   // Naranja Alerta

  // Sombra suave para tarjetas
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 15,
      offset: const Offset(0, 5),
    )
  ];
}
