import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import '../config/constants.dart';
import 'api_service.dart';

class UpdateService {
  // Comprueba si hay una nueva versión y despliega el diálogo interactivo de actualización
  static Future<void> checkAndShowUpdateDialog(BuildContext context, {bool showNoUpdateToast = false}) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      final res = await ApiService.checkAppVersion();

      if (res['status'] == 'success' && res['data'] != null) {
        final data = res['data'];
        final String latestVersion = data['latest_version'] ?? currentVersion;
        final int latestVersionCode = data['version_code'] ?? currentBuildNumber;
        final bool forceUpdate = data['force_update'] ?? false;
        final String releaseNotes = data['release_notes'] ?? '• Mejoras de rendimiento y corrección de errores.';
        final String apkUrl = data['apk_url'] ?? '';

        // Si la versión del servidor es mayor a la instalada
        if (latestVersionCode > currentBuildNumber || _isVersionHigher(latestVersion, currentVersion)) {
          if (!context.mounted) return;
          _showUpdateModal(
            context: context,
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseNotes: releaseNotes,
            apkUrl: apkUrl,
            forceUpdate: forceUpdate,
          );
        } else if (showNoUpdateToast) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppConstants.successGreen,
              content: Text("¡Tu aplicación ya está en la versión más reciente! ($currentVersion)"),
            ),
          );
        }
      }
    } catch (e) {
      if (showNoUpdateToast && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al comprobar la versión: $e")),
        );
      }
    }
  }

  // Comparador helper semántico (ej. "1.1.0" > "1.0.0")
  static bool _isVersionHigher(String latest, String current) {
    try {
      List<int> lParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < lParts.length && i < cParts.length; i++) {
        if (lParts[i] > cParts[i]) return true;
        if (lParts[i] < cParts[i]) return false;
      }
      return lParts.length > cParts.length;
    } catch (_) {
      return false;
    }
  }

  // Modal estético de notificación y descarga OTA
  static void _showUpdateModal({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    required String releaseNotes,
    required String apkUrl,
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (BuildContext dialogContext) {
        return _UpdateDialogWidget(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          releaseNotes: releaseNotes,
          apkUrl: apkUrl,
          forceUpdate: forceUpdate,
        );
      },
    );
  }
}

class _UpdateDialogWidget extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String apkUrl;
  final bool forceUpdate;

  const _UpdateDialogWidget({
    Key? key,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.apkUrl,
    required this.forceUpdate,
  }) : super(key: key);

  @override
  State<_UpdateDialogWidget> createState() => _UpdateDialogWidgetState();
}

class _UpdateDialogWidgetState extends State<_UpdateDialogWidget> {
  bool _isDownloading = false;
  String _downloadProgress = '0%';
  double _progressValue = 0.0;
  String _statusMessage = '';
  bool _hasError = false;

  void _startOtaUpdate() {
    if (widget.apkUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _statusMessage = 'La URL de descarga no es válida.';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _hasError = false;
      _statusMessage = 'Iniciando descarga...';
    });

    try {
      OtaUpdate()
          .execute(widget.apkUrl, destinationFilename: 'conticomtc_update.apk')
          .listen(
        (OtaEvent event) {
          if (!mounted) return;
          setState(() {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                _statusMessage = 'Descargando nueva versión...';
                int val = int.tryParse(event.value ?? '0') ?? 0;
                _progressValue = val / 100.0;
                _downloadProgress = '$val%';
                break;

              case OtaStatus.INSTALLING:
                _statusMessage = '¡Descarga completa! Abriendo instalador nativo...';
                _progressValue = 1.0;
                _downloadProgress = '100%';
                break;

              case OtaStatus.ALREADY_RUNNING_ERROR:
                _statusMessage = 'Ya hay una actualización en curso.';
                break;

              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                _hasError = true;
                _statusMessage = 'Permiso denegado para instalar paquetes.';
                break;

              case OtaStatus.INTERNAL_ERROR:
              case OtaStatus.CHECKSUM_ERROR:
                _hasError = true;
                _statusMessage = 'Error al descargar el paquete de actualización.';
                break;

              default:
                _statusMessage = 'Procesando actualización...';
                break;
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _hasError = true;
            _statusMessage = 'Error durante la descarga: $error';
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'No se pudo iniciar la actualización: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera del Diálogo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryBlue.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: AppConstants.primaryBlue, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "¡Nueva Versión!",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text("v${widget.currentVersion}", style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                          const Icon(Icons.arrow_forward, size: 12, color: AppConstants.primaryBlue),
                          Text(" v${widget.latestVersion}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.successGreen)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cuadro de Novedades / Release Notes
            const Text(
              "Novedades de esta versión:",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.releaseNotes,
                  style: const TextStyle(fontSize: 12, color: AppConstants.textDark, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Barra de Descarga o Estado
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _progressValue > 0 ? _progressValue : null,
                backgroundColor: Colors.grey.shade200,
                color: AppConstants.primaryBlue,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: _hasError ? AppConstants.dangerRed : AppConstants.textMuted,
                        fontWeight: _hasError ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(_downloadProgress, style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryBlue)),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Botones de Acción
            if (!_isDownloading) ...[
              Row(
                children: [
                  if (!widget.forceUpdate)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("Más tarde", style: TextStyle(color: AppConstants.textMuted)),
                      ),
                    ),
                  if (!widget.forceUpdate) const SizedBox(width: 12),
                  Expanded(
                    flex: widget.forceUpdate ? 1 : 1,
                    child: ElevatedButton.icon(
                      onPressed: _startOtaUpdate,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text("Actualizar", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.successGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (_hasError) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _startOtaUpdate,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Reintentar Descarga"),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
