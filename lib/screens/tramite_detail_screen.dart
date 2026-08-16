import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants.dart';
import '../services/api_service.dart';

class TramiteDetailScreen extends StatefulWidget {
  final int tramiteId;
  final String? numeroExpediente;

  const TramiteDetailScreen({
    Key? key,
    required this.tramiteId,
    this.numeroExpediente,
  }) : super(key: key);

  @override
  State<TramiteDetailScreen> createState() => _TramiteDetailScreenState();
}

class _TramiteDetailScreenState extends State<TramiteDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _tramiteData;
  List<dynamic> _archivos = [];
  List<dynamic> _derivaciones = [];
  List<dynamic> _comentarios = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTramiteDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTramiteDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.getTramiteDetalle(widget.tramiteId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['status'] == 'success' && res['data'] != null) {
          _tramiteData = res['data']['tramite'];
          _archivos = res['data']['archivos'] ?? [];
          _derivaciones = res['data']['derivaciones'] ?? [];
          _comentarios = res['data']['comentarios'] ?? [];
        } else {
          _errorMessage = res['message'] ?? 'No se pudo cargar la información del trámite.';
        }
      });
    }
  }

  Color _getStatusColor(String estado) {
    final lower = estado.toLowerCase();
    if (lower.contains('registrado')) return AppConstants.primaryBlue;
    if (lower.contains('revis')) return Colors.purple;
    if (lower.contains('observado')) return AppConstants.warningOrange;
    if (lower.contains('derivado')) return AppConstants.accentCyan;
    if (lower.contains('aprobado') || lower.contains('finalizado')) return AppConstants.successGreen;
    if (lower.contains('rechazado')) return AppConstants.dangerRed;
    return AppConstants.primaryNavy;
  }

  void _openFileUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        launched = await launchUrl(
          url,
          mode: LaunchMode.platformDefault,
        );
      }

      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo abrir el navegador para: $urlString")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al abrir el archivo: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String titleExpediente = widget.numeroExpediente ?? _tramiteData?['numeroexpediente'] ?? 'Detalle Trámite';

    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        title: Text(titleExpediente, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitFadingCube(color: AppConstants.primaryNavy, size: 40),
                    SizedBox(height: 16),
                    Text("Cargando expediente...", style: TextStyle(color: AppConstants.textMuted)),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppConstants.dangerRed),
                          const SizedBox(height: 14),
                          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadTramiteDetail,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Reintentar"),
                            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryNavy),
                          )
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Header Card del Trámite
                      _buildHeaderCard(),

                      // TabBar de Navegación
                      Container(
                        color: AppConstants.cardWhite,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppConstants.primaryNavy,
                          unselectedLabelColor: AppConstants.textMuted,
                          indicatorColor: AppConstants.primaryBlue,
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(icon: Icon(Icons.info_outline, size: 20), text: "Detalles"),
                            Tab(icon: Icon(Icons.attach_file, size: 20), text: "Archivos"),
                            Tab(icon: Icon(Icons.alt_route, size: 20), text: "Seguimiento"),
                          ],
                        ),
                      ),

                      // TabBarView Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildInfoTab(),
                            _buildArchivosTab(),
                            _buildSeguimientoTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // Tarjeta de Cabecera del Trámite
  Widget _buildHeaderCard() {
    final estadoNombre = _tramiteData?['estado_nombre'] ?? 'Registrado';
    final estadoColor = _getStatusColor(estadoNombre);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppConstants.cardWhite,
        boxShadow: AppConstants.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _tramiteData?['numeroexpediente'] ?? 'EXP-000',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryNavy, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: estadoColor.withOpacity(0.3)),
                ),
                child: Text(
                  estadoNombre.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: estadoColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _tramiteData?['tipo_tramite_nombre'] ?? 'Trámite Documentario',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textDark),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppConstants.textMuted),
              const SizedBox(width: 6),
              Text(
                "Fecha de Registro: ${_tramiteData?['fecha'] ?? '-'}",
                style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 1: Detalles de la Solicitud
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppConstants.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppConstants.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoItem("Solicitante", _tramiteData?['solicitante_nombre'] ?? '-', Icons.person_outline),
                const Divider(height: 24),
                _buildInfoItem("Recepcionista / Atendido por", _tramiteData?['recepcionista_nombre'] ?? '-', Icons.admin_panel_settings_outlined),
                const Divider(height: 24),
                _buildInfoItem("Asunto", _tramiteData?['asunto']?.isNotEmpty == true ? _tramiteData!['asunto'] : '(Sin asunto)', Icons.title),
                const Divider(height: 24),
                _buildInfoItem("Descripción u Observaciones", _tramiteData?['descripcion']?.isNotEmpty == true ? _tramiteData!['descripcion'] : '(Sin descripción)', Icons.notes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppConstants.primaryBlue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.textMuted)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: AppConstants.textDark, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 2: Archivos Adjuntos
  Widget _buildArchivosTab() {
    if (_archivos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 48, color: AppConstants.textMuted),
            SizedBox(height: 12),
            Text("Este trámite no cuenta con archivos adjuntos.", style: TextStyle(color: AppConstants.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _archivos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = _archivos[index];
        final String nombreArchivo = a['nombre_archivo'] ?? 'Archivo';
        final String requisitoNombre = a['requisito_nombre'] ?? 'Archivo adjunto';
        final String url = a['url'] ?? '';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppConstants.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppConstants.softShadow,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_outlined, color: AppConstants.primaryBlue, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requisitoNombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppConstants.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nombreArchivo,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: url.isNotEmpty ? () => _openFileUrl(url) : null,
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text("Ver"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 3: Seguimiento, Derivaciones y Comentarios
  Widget _buildSeguimientoTab() {
    if (_derivaciones.isEmpty && _comentarios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 48, color: AppConstants.textMuted),
            SizedBox(height: 12),
            Text("Aún no se registran derivaciones ni comentarios.", style: TextStyle(color: AppConstants.textMuted)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_derivaciones.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.alt_route, color: AppConstants.primaryNavy),
                const SizedBox(width: 8),
                Text(
                  "Historial de Derivaciones (${_derivaciones.length})",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _derivaciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final d = _derivaciones[index];
                final estadoNombre = d['estado_nombre'] ?? '';
                final estadoColor = _getStatusColor(estadoNombre);
                final List<dynamic> archivosDeriva = d['archivos'] ?? [];
                final List<dynamic> comentariosDeriva = d['comentarios'] ?? [];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppConstants.softShadow,
                    border: Border.all(color: estadoColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado de la Derivación
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: estadoColor,
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              d['oficina_nombre'] ?? 'Oficina',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textDark),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: estadoColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              estadoNombre,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: estadoColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (d['programa_nombre']?.toString().isNotEmpty == true) ...[
                        Row(
                          children: [
                            const Icon(Icons.school_outlined, size: 16, color: AppConstants.primaryBlue),
                            const SizedBox(width: 6),
                            Text(
                              "Programa: ${d['programa_nombre']}",
                              style: const TextStyle(fontSize: 13, color: AppConstants.primaryBlue, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Enviado Por & Recibido Por
                      if (d['enviado_por_nombre']?.toString().isNotEmpty == true || d['recibido_por_nombre']?.toString().isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppConstants.bgLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (d['enviado_por_nombre']?.toString().isNotEmpty == true)
                                Text("Remitente: ${d['enviado_por_nombre']}", style: const TextStyle(fontSize: 12, color: AppConstants.textDark)),
                              if (d['recibido_por_nombre']?.toString().isNotEmpty == true)
                                Text("Destinatario / Atendido por: ${d['recibido_por_nombre']}", style: const TextStyle(fontSize: 12, color: AppConstants.textDark, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Fecha
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppConstants.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            "Fecha de derivación: ${d['fecha'] ?? '-'}",
                            style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
                          ),
                        ],
                      ),

                      // Archivos adjuntos en esta derivación
                      if (archivosDeriva.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          "Archivos de esta etapa:",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.primaryNavy),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          children: archivosDeriva.map<Widget>((ad) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryBlue.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.insert_drive_file_outlined, size: 18, color: AppConstants.primaryBlue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ad['nombre_archivo'] ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _openFileUrl(ad['url']),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryNavy,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text("Ver", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Comentarios / Observaciones en esta derivación
                      if (comentariosDeriva.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          "Observaciones de la oficina:",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          children: comentariosDeriva.map<Widget>((cd) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.comment_outlined, size: 16, color: Colors.brown),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cd['usuario_nombre'] ?? 'Oficial',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          cd['mensaje'] ?? '',
                                          style: const TextStyle(fontSize: 12, color: AppConstants.textDark),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Comentarios Generales si los hay fuera de derivaciones
          if (_comentarios.isNotEmpty) ...[
            const Text(
              "Comentarios y Observaciones Generales",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comentarios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = _comentarios[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppConstants.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppConstants.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, color: AppConstants.primaryBlue, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            c['usuario_nombre'] ?? 'Usuario',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            c['fecha'] ?? '',
                            style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c['mensaje'] ?? '',
                        style: const TextStyle(fontSize: 13, color: AppConstants.textDark),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
