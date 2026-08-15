import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = await ApiService.getCurrentUser();
    setState(() {
      _currentUser = user;
      _isLoadingUser = false;
    });
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que deseas salir del sistema?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.dangerRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Cerrar Sesión", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.assignment_turned_in, size: 26, color: AppConstants.accentCyan),
            SizedBox(width: 10),
            Text(
              "CONTICOMTC Móvil",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: "Cerrar Sesión",
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryNavy))
          : RefreshIndicator(
              onRefresh: () async => _loadUserData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de Bienvenida al Usuario
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppConstants.primaryNavy, Color(0xFF2C3E50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppConstants.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppConstants.primaryBlue,
                                child: Text(
                                  _currentUser?.nombre.isNotEmpty == true 
                                      ? _currentUser!.nombre[0].toUpperCase() 
                                      : 'U',
                                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "¡Hola, ${_currentUser?.nombre ?? 'Usuario'}!",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppConstants.accentCyan.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _currentUser?.tipoUsuarioNombre ?? 'Solicitante',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppConstants.accentCyan,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "DNI: ${_currentUser?.dni ?? '-'}",
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              Text(
                                "CÓDIGO: ${_currentUser?.codigo ?? '-'}",
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título Módulos Principales
                    const Text(
                      "Panel de Control",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Grid de Accesos Rápidos
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.2,
                      children: [
                        _buildMenuCard(
                          title: "Mis Trámites",
                          subtitle: "Consulta tus expedientes",
                          icon: Icons.folder_copy_outlined,
                          color: AppConstants.primaryBlue,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Módulo de Mis Trámites seleccionado.")),
                            );
                          },
                        ),
                        _buildMenuCard(
                          title: "Nuevo Trámite",
                          subtitle: "Registrar solicitud",
                          icon: Icons.note_add_outlined,
                          color: AppConstants.successGreen,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Módulo de Registro de Trámite seleccionado.")),
                            );
                          },
                        ),
                        _buildMenuCard(
                          title: "Buscar Trámite",
                          subtitle: "Por N° Expediente",
                          icon: Icons.search_rounded,
                          color: AppConstants.warningOrange,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Módulo de Búsqueda de Trámite seleccionado.")),
                            );
                          },
                        ),
                        _buildMenuCard(
                          title: "Mi Perfil",
                          subtitle: "Mis datos personales",
                          icon: Icons.account_circle_outlined,
                          color: AppConstants.primaryNavy,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Módulo Perfil seleccionado.")),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Resumen Informativo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppConstants.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: AppConstants.primaryBlue),
                              SizedBox(width: 8),
                              Text(
                                "Estado del Sistema Móvil",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Conectado correctamente a la API del Sistema de Trámite Documentario.",
                            style: TextStyle(fontSize: 13, color: AppConstants.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppConstants.cardWhite,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: AppConstants.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppConstants.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
