import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../config/constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'tramite_detail_screen.dart';

class MisTramitesScreen extends StatefulWidget {
  const MisTramitesScreen({Key? key}) : super(key: key);

  @override
  State<MisTramitesScreen> createState() => _MisTramitesScreenState();
}

class _MisTramitesScreenState extends State<MisTramitesScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _allTramites = [];
  List<dynamic> _filteredTramites = [];

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos'; // 'Todos', 'En Proceso', 'Finalizados'

  @override
  void initState() {
    super.initState();
    _loadTramites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTramites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await ApiService.getCurrentUser();
    _currentUser = user;

    if (user != null) {
      final res = await ApiService.getMisTramites(user.id);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (res['status'] == 'success' && res['data'] != null) {
            _allTramites = res['data']['tramites'] ?? [];
            _applyFilters();
          } else {
            _errorMessage = res['message'] ?? 'No se pudieron obtener los trámites.';
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se encontró la sesión del usuario.';
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredTramites = _allTramites.where((t) {
        final exp = (t['numeroexpediente'] ?? '').toString().toLowerCase();
        final asunto = (t['asunto'] ?? '').toString().toLowerCase();
        final tipo = (t['tipo_tramite_nombre'] ?? '').toString().toLowerCase();
        final estado = (t['estado_nombre'] ?? '').toString().toLowerCase();

        final matchesSearch = query.isEmpty || exp.contains(query) || asunto.contains(query) || tipo.contains(query);

        if (!matchesSearch) return false;

        if (_selectedFilter == 'En Proceso') {
          return !estado.contains('finalizado') && !estado.contains('aprobado') && !estado.contains('rechazado');
        } else if (_selectedFilter == 'Finalizados') {
          return estado.contains('finalizado') || estado.contains('aprobado') || estado.contains('rechazado');
        }

        return true;
      }).toList();
    });
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
        title: const Text("Mis Trámites", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de Búsqueda y Filtros
            Container(
              padding: const EdgeInsets.all(16),
              color: AppConstants.cardWhite,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: "Buscar por N° Expediente, tipo o asunto...",
                      prefixIcon: const Icon(Icons.search, color: AppConstants.primaryBlue),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppConstants.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todos'),
                        const SizedBox(width: 8),
                        _buildFilterChip('En Proceso'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Finalizados'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de Trámites
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SpinKitFadingCube(color: AppConstants.primaryNavy, size: 40),
                          SizedBox(height: 16),
                          Text("Cargando tus expedientes...", style: TextStyle(color: AppConstants.textMuted)),
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
                                  onPressed: _loadTramites,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Reintentar"),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryNavy),
                                )
                              ],
                            ),
                          ),
                        )
                      : _filteredTramites.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_off_outlined, size: 56, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text("No se encontraron trámites.", style: TextStyle(fontSize: 16, color: AppConstants.textMuted)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async => _loadTramites(),
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredTramites.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final tramite = _filteredTramites[index];
                                  return _buildTramiteCard(tramite);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppConstants.primaryNavy,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppConstants.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppConstants.bgLight,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
            _applyFilters();
          });
        }
      },
    );
  }

  Widget _buildTramiteCard(dynamic tramite) {
    final String exp = tramite['numeroexpediente'] ?? 'TR-000';
    final String tipoNombre = tramite['tipo_tramite_nombre'] ?? 'Trámite';
    final String estadoNombre = tramite['estado_nombre'] ?? 'Registrado';
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
