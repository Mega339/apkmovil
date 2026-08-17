import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import 'tramite_detail_screen.dart';

class BuscarTramiteScreen extends StatefulWidget {
  const BuscarTramiteScreen({Key? key}) : super(key: key);

  @override
  State<BuscarTramiteScreen> createState() => _BuscarTramiteScreenState();
}

class _BuscarTramiteScreenState extends State<BuscarTramiteScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  List<dynamic> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch([String? term]) async {
    final query = term ?? _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa un N° de Expediente, DNI o palabra clave.")),
      );
      return;
    }

    if (term != null) {
      _searchController.text = term;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = null;
      _searchResults = [];
    });

    final currentUser = await ApiService.getCurrentUser();
    final res = await ApiService.buscarTramites(query, solicitanteId: currentUser?.id);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['status'] == 'success' && res['data'] != null) {
          _searchResults = res['data']['resultados'] ?? [];
        } else {
          _errorMessage = res['message'] ?? 'No se pudieron obtener resultados para la búsqueda.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        title: const Text("Buscar Trámite", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Hero de Búsqueda Moderna
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.cardWhite,
                boxShadow: AppConstants.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.manage_search_rounded, color: AppConstants.primaryBlue, size: 28),
                      SizedBox(width: 10),
                      Text(
                        "Búsqueda Precisa de Expedientes",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _performSearch(),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: "Ej. TR-001, DNI 74839201 o palabra...",
                            prefixIcon: const Icon(Icons.search, color: AppConstants.primaryBlue),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _hasSearched = false;
                                        _searchResults = [];
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppConstants.bgLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _performSearch(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Sugerencias rápidas de búsqueda
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text("Sugerencias: ", style: TextStyle(fontSize: 12, color: AppConstants.textMuted, fontWeight: FontWeight.bold)),
                        _buildQuickChip("TR-001"),
                        const SizedBox(width: 6),
                        _buildQuickChip("TR-002"),
                        const SizedBox(width: 6),
                        _buildQuickChip("Constancia"),
                        const SizedBox(width: 6),
                        _buildQuickChip("Certificado"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Resultados de Búsqueda
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SpinKitFadingCube(color: AppConstants.primaryNavy, size: 40),
                          SizedBox(height: 16),
                          Text("Buscando en el sistema...", style: TextStyle(color: AppConstants.textMuted)),
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
                                const SizedBox(height: 12),
                                Text(_errorMessage!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _performSearch(),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Reintentar"),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryNavy),
                                )
                              ],
                            ),
                          ),
                        )
                      : !_hasSearched
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(30),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.search_outlined, size: 64, color: AppConstants.textMuted),
                                    SizedBox(height: 14),
                                    Text(
                                      "Ingresa un N° de expediente, DNI o palabra clave arriba para realizar la búsqueda.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, color: AppConstants.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _searchResults.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(30),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey.shade400),
                                        const SizedBox(height: 14),
                                        Text(
                                          "No se encontraron trámites con: \"${_searchController.text}\"",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          "Verifica el número de expediente o DNI ingresado.",
                                          style: TextStyle(fontSize: 13, color: AppConstants.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _searchResults.length + 1,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                                        child: Text(
                                          "Se encontraron ${_searchResults.length} trámites:",
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textMuted),
                                        ),
                                      );
                                    }
                                    final tramite = _searchResults[index - 1];
                                    return _buildSearchResultCard(tramite);
                                  },
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: AppConstants.primaryNavy, fontWeight: FontWeight.bold)),
      backgroundColor: AppConstants.primaryBlue.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () => _performSearch(label),
    );
  }

  Widget _buildSearchResultCard(dynamic tramite) {
    final String exp = tramite['numeroexpediente'] ?? 'TR-000';
    final String tipoNombre = tramite['tipo_tramite_nombre'] ?? 'Trámite';
    final String estadoNombre = tramite['estado_nombre'] ?? 'Registrado';
    final String solicitante = tramite['solicitante_nombre'] ?? '';
    final String dni = tramite['solicitante_dni'] ?? '';
    final String asunto = tramite['asunto'] ?? '';
    final String fecha = tramite['fecha'] ?? '';
    final int totalArchivos = tramite['total_archivos'] ?? 0;
    final Color estadoColor = _getStatusColor(estadoNombre);

    return Material(
      color: AppConstants.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TramiteDetailScreen(
                tramiteId: tramite['id'],
                numeroExpediente: exp,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
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
                      exp,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryNavy, fontSize: 13),
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
                      estadoNombre,
                      style: TextStyle(fontWeight: FontWeight.bold, color: estadoColor, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tipoNombre,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
              ),
              if (solicitante.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppConstants.primaryBlue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Solicitante: $solicitante ${dni.isNotEmpty ? ' (DNI: $dni)' : ''}",
                        style: const TextStyle(fontSize: 12, color: AppConstants.textDark, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
              if (asunto.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  asunto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppConstants.textMuted),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 14, color: AppConstants.textMuted),
                      const SizedBox(width: 4),
                      Text("$totalArchivos archivos", style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                      const SizedBox(width: 14),
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppConstants.textMuted),
                      const SizedBox(width: 4),
                      Text(fecha.split(' ')[0], style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppConstants.primaryBlue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
