import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../config/constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/update_service.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSavingPerfil = false;
  bool _isSavingPassword = false;
  String? _errorMessage;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _statsData;

  // Controllers para Datos Personales
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  String _sexoSeleccionado = 'Masculino';

  // Controllers para Cambio de Contraseña
  final TextEditingController _passActualController = TextEditingController();
  final TextEditingController _passNuevaController = TextEditingController();
  final TextEditingController _passConfirmController = TextEditingController();
  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPerfilData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passActualController.dispose();
    _passNuevaController.dispose();
    _passConfirmController.dispose();
    super.dispose();
  }

  void _loadPerfilData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentUser = await ApiService.getCurrentUser();
    if (currentUser != null) {
      final res = await ApiService.getPerfil(currentUser.id);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (res['status'] == 'success' && res['data'] != null) {
            _userData = res['data']['user'];
            _statsData = res['data']['estadisticas'];

            // Llenar datos en los formularios
            _nombreController.text = _userData?['nombre'] ?? '';
            _apellidoController.text = _userData?['apellido'] ?? '';
            _correoController.text = _userData?['correo'] ?? '';
            _telefonoController.text = _userData?['telefono'] ?? '';
            
            String s = _userData?['sexo'] ?? '';
            if (s.toLowerCase().contains('fem')) {
              _sexoSeleccionado = 'Femenino';
            } else {
              _sexoSeleccionado = 'Masculino';
            }
          } else {
            _errorMessage = res['message'] ?? 'No se pudieron obtener los datos del perfil.';
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se encontró una sesión activa.';
        });
      }
    }
  }

  void _handleActualizarPerfil() async {
    final String nombre = _nombreController.text.trim();
    final String apellido = _apellidoController.text.trim();
    final String correo = _correoController.text.trim();
    final String telefono = _telefonoController.text.trim();

    // Validaciones del cliente
    if (nombre.isEmpty || apellido.isEmpty || correo.isEmpty || telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa todos los campos obligatorios.")),
      );
      return;
    }

    final RegExp regexTexto = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñÜü ]+$');
    if (!regexTexto.hasMatch(nombre) || !regexTexto.hasMatch(apellido)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nombres y Apellidos solo pueden contener letras.")),
      );
      return;
    }

    if (!RegExp(r'^[0-9]{9}$').hasMatch(telefono)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El teléfono debe tener exactamente 9 dígitos.")),
      );
      return;
    }

    setState(() => _isSavingPerfil = true);

    final res = await ApiService.actualizarPerfil(
      usuarioId: _userData!['id'],
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      telefono: telefono,
      sexo: _sexoSeleccionado,
    );

    setState(() => _isSavingPerfil = false);

    if (!mounted) return;

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppConstants.successGreen,
          content: Text(res['message'] ?? "Perfil actualizado con éxito"),
        ),
      );
      _loadPerfilData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppConstants.dangerRed,
          content: Text(res['message'] ?? "Error al actualizar perfil"),
        ),
      );
    }
  }

  void _handleCambiarPassword() async {
    final String actual = _passActualController.text.trim();
    final String nueva = _passNuevaController.text.trim();
    final String confirm = _passConfirmController.text.trim();

    if (actual.isEmpty || nueva.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa tu contraseña actual y la nueva contraseña.")),
      );
      return;
    }

    if (nueva.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La nueva contraseña debe tener al menos 4 caracteres.")),
      );
      return;
    }

    if (nueva != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La nueva contraseña y su confirmación no coinciden.")),
      );
      return;
    }

    setState(() => _isSavingPassword = true);

    final res = await ApiService.cambiarPassword(
      usuarioId: _userData!['id'],
      passwordActual: actual,
      passwordNueva: nueva,
    );

    setState(() => _isSavingPassword = false);

    if (!mounted) return;

    if (res['status'] == 'success') {
      _passActualController.clear();
      _passNuevaController.clear();
      _passConfirmController.clear();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppConstants.successGreen),
              SizedBox(width: 8),
              Text("Contraseña Actualizada"),
            ],
          ),
          content: const Text("Tu contraseña ha sido cambiada correctamente. Úsala para tus próximos inicios de sesión."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendido"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppConstants.dangerRed,
          content: Text(res['message'] ?? "Error al cambiar contraseña"),
        ),
      );
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que deseas salir de tu cuenta?"),
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        title: const Text("Mi Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Text("Cargando información del perfil...", style: TextStyle(color: AppConstants.textMuted)),
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
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadPerfilData,
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
                      // Header Card del Usuario
                      _buildUserHeaderCard(),

                      // Resumen de Estadísticas
                      _buildStatsRow(),

                      // TabBar Navegación
                      Container(
                        color: AppConstants.cardWhite,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppConstants.primaryNavy,
                          unselectedLabelColor: AppConstants.textMuted,
                          indicatorColor: AppConstants.primaryBlue,
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(icon: Icon(Icons.person_outline, size: 20), text: "Datos Personales"),
                            Tab(icon: Icon(Icons.lock_outline, size: 20), text: "Seguridad"),
                          ],
                        ),
                      ),

                      // TabBarView Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildDatosPersonalesTab(),
                            _buildSeguridadTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // Header del Usuario
  Widget _buildUserHeaderCard() {
    final String nombre = _userData?['nombre'] ?? 'Usuario';
    final String apellido = _userData?['apellido'] ?? '';
    final String tipoNombre = _userData?['tipo_usuario_nombre'] ?? 'Solicitante';
    final String codigo = _userData?['codigo'] ?? '-';
    final String dni = _userData?['dni'] ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppConstants.primaryNavy,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppConstants.primaryBlue,
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "$nombre $apellido",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.accentCyan.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tipoNombre,
              style: const TextStyle(fontSize: 12, color: AppConstants.accentCyan, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("CÓDIGO: $codigo", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Text("DNI: $dni", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // Fila de Estadísticas de Trámites
  Widget _buildStatsRow() {
    final int total = _statsData?['total_tramites'] ?? 0;
    final int enProceso = _statsData?['en_proceso'] ?? 0;
    final int finalizados = _statsData?['finalizados'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      color: AppConstants.cardWhite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard("Total Trámites", "$total", AppConstants.primaryBlue, Icons.folder_copy_outlined),
          Container(height: 30, width: 1, color: Colors.grey.shade300),
          _buildStatCard("En Proceso", "$enProceso", AppConstants.warningOrange, Icons.pending_actions),
          Container(height: 30, width: 1, color: Colors.grey.shade300),
          _buildStatCard("Finalizados", "$finalizados", AppConstants.successGreen, Icons.task_alt),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppConstants.textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // TAB 1: Datos Personales
  Widget _buildDatosPersonalesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppConstants.cardWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppConstants.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Información de la Cuenta (Solo Lectura)",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textMuted),
                ),
                const SizedBox(height: 10),
                _buildReadOnlyField("Usuario", _userData?['usuario'] ?? '-', Icons.account_box_outlined),
                const SizedBox(height: 10),
                _buildReadOnlyField("DNI", _userData?['dni'] ?? '-', Icons.badge_outlined),
                const SizedBox(height: 10),
                if (_userData?['oficina_nombre'] != null)
                  _buildReadOnlyField("Oficina Asignada", _userData!['oficina_nombre'], Icons.business_outlined),
                if (_userData?['programa_nombre'] != null)
                  _buildReadOnlyField("Programa de Estudios", _userData!['programa_nombre'], Icons.school_outlined),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                const Text(
                  "Editar Datos Personales",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                ),
                const SizedBox(height: 14),

                // Campo Nombre
                TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: "Nombres *",
                    prefixIcon: const Icon(Icons.person, color: AppConstants.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Campo Apellido
                TextField(
                  controller: _apellidoController,
                  decoration: InputDecoration(
                    labelText: "Apellidos *",
                    prefixIcon: const Icon(Icons.person_outline, color: AppConstants.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Campo Correo
                TextField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Correo Electrónico *",
                    prefixIcon: const Icon(Icons.email_outlined, color: AppConstants.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Campo Teléfono
                TextField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  decoration: InputDecoration(
                    labelText: "Teléfono / Celular (9 dígitos) *",
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppConstants.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    counterText: "",
                  ),
                ),
                const SizedBox(height: 14),

                // Campo Sexo
                DropdownButtonFormField<String>(
                  value: _sexoSeleccionado,
                  decoration: InputDecoration(
                    labelText: "Sexo",
                    prefixIcon: const Icon(Icons.wc, color: AppConstants.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                    DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sexoSeleccionado = val);
                  },
                ),
                const SizedBox(height: 24),

                // Botón Guardar Cambios
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingPerfil ? null : _handleActualizarPerfil,
                    icon: _isSavingPerfil
                        ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _isSavingPerfil ? "Guardando..." : "Guardar Cambios",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Botón Cerrar Sesión al final
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, color: AppConstants.dangerRed),
              label: const Text("Cerrar Sesión", style: TextStyle(color: AppConstants.dangerRed, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppConstants.dangerRed),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppConstants.textMuted),
        const SizedBox(width: 10),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.textMuted)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, color: AppConstants.textDark, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // TAB 2: Seguridad (Cambiar Contraseña)
  Widget _buildSeguridadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppConstants.cardWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppConstants.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppConstants.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      "Cambiar Contraseña de la Cuenta",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Para proteger tu cuenta, utiliza una contraseña segura de al menos 4 caracteres.",
                  style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
                ),
                const SizedBox(height: 20),

                // Contraseña Actual
                TextField(
                  controller: _passActualController,
                  obscureText: _obscureActual,
                  decoration: InputDecoration(
                    labelText: "Contraseña Actual *",
                    prefixIcon: const Icon(Icons.lock_outline, color: AppConstants.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureActual ? Icons.visibility_off : Icons.visibility, color: AppConstants.textMuted),
                      onPressed: () => setState(() => _obscureActual = !_obscureActual),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Nueva Contraseña
                TextField(
                  controller: _passNuevaController,
                  obscureText: _obscureNueva,
                  decoration: InputDecoration(
                    labelText: "Nueva Contraseña *",
                    prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppConstants.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNueva ? Icons.visibility_off : Icons.visibility, color: AppConstants.textMuted),
                      onPressed: () => setState(() => _obscureNueva = !_obscureNueva),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirmar Nueva Contraseña
                TextField(
                  controller: _passConfirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: "Confirmar Nueva Contraseña *",
                    prefixIcon: const Icon(Icons.check_circle_outline, color: AppConstants.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: AppConstants.textMuted),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Actualizar Contraseña
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingPassword ? null : _handleCambiarPassword,
                    icon: _isSavingPassword
                        ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                        : const Icon(Icons.key_rounded),
                    label: Text(
                      _isSavingPassword ? "Actualizando..." : "Actualizar Contraseña",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta de Comprobar Actualizaciones OTA
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppConstants.cardWhite,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppConstants.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.system_update_rounded, color: AppConstants.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      "Actualizaciones del Sistema",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Comprueba si existe una versión más reciente del APK en el servidor para actualizar automáticamente.",
                  style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      UpdateService.checkAndShowUpdateDialog(context, showNoUpdateToast: true);
                    },
                    icon: const Icon(Icons.refresh_rounded, color: AppConstants.primaryNavy),
                    label: const Text(
                      "Buscar Actualizaciones del APK",
                      style: TextStyle(color: AppConstants.primaryNavy, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppConstants.primaryNavy),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
