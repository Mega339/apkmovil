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
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo abrir el archivo: $urlString")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al abrir archivo: $e")),
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
                _buildInfoItem("Recepcionista", _tramiteData?['recepcionista_nombre'] ?? '-', Icons.admin_panel_settings_outlined),
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
            const Text(
              "Historial de Derivaciones",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _derivaciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = _derivaciones[index];
                final estadoColor = _getStatusColor(d['estado_nombre'] ?? '');

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppConstants.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppConstants.softShadow,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: estadoColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.business, color: estadoColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['oficina_nombre'] ?? 'Oficina',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (d['programa_nombre']?.toString().isNotEmpty == true)
                              Text(
                                d['programa_nombre'],
                                style: const TextStyle(fontSize: 12, color: AppConstants.primaryBlue),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              "Fecha: ${d['fecha'] ?? '-'}",
                              style: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: estadoColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          d['estado_nombre'] ?? '',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: estadoColor),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          if (_comentarios.isNotEmpty) ...[
            const Text(
              "Observaciones y Comentarios",
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
