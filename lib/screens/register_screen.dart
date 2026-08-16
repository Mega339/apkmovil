import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../config/constants.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isLoadingCatalogos = true;

  // Listas de catálogos desde la base de datos
  List<dynamic> _tiposUsuario = [];
  List<dynamic> _oficinas = [];
  List<dynamic> _programas = [];

  // Selecciones del usuario
  int? _selectedTipoUsuario;
  String _selectedCampoExtra = ''; // 'oficina', 'programa' o ''
  int? _selectedOficina;
  int? _selectedPrograma;
  String? _selectedSexo;

  @override
  void initState() {
    super.initState();
    _loadCatalogos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _usuarioController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadCatalogos() async {
    final result = await ApiService.getCatalogos();
    if (mounted) {
      setState(() {
        if (result['status'] == 'success' && result['data'] != null) {
          _tiposUsuario = result['data']['tipos_usuario'] ?? [];
          _oficinas = result['data']['oficinas'] ?? [];
          _programas = result['data']['programas'] ?? [];
        }
        _isLoadingCatalogos = false;
      });
    }
  }

  void _onTipoUsuarioChanged(int? newTipoId) {
    if (newTipoId == null) return;
    final tipoObj = _tiposUsuario.firstWhere((t) => t['id'] == newTipoId, orElse: () => null);
    setState(() {
      _selectedTipoUsuario = newTipoId;
      _selectedCampoExtra = tipoObj != null ? (tipoObj['campo'] ?? '') : '';
      _selectedOficina = null;
      _selectedPrograma = null;
    });
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Las contraseñas no coinciden."),
          backgroundColor: AppConstants.dangerRed,
        ),
      );
      return;
    }

    if (_selectedTipoUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor selecciona un Tipo de Usuario."),
          backgroundColor: AppConstants.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.register(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      dni: _dniController.text.trim(),
      correo: _correoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      usuario: _usuarioController.text.trim(),
      password: _passwordController.text,
      tipoUsuario: _selectedTipoUsuario!,
      sexo: _selectedSexo,
      oficina: _selectedCampoExtra == 'oficina' ? _selectedOficina : null,
      programasEstudio: _selectedCampoExtra == 'programa' ? _selectedPrograma : null,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['status'] == 'success') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppConstants.successGreen),
              SizedBox(width: 8),
              Text("¡Registro Exitoso!"),
            ],
          ),
          content: Text(result['message'] ?? 'Cuenta creada correctamente.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryNavy),
              onPressed: () {
                Navigator.pop(context); // Cierra diálogo
                Navigator.pop(context); // Vuelve a pantalla de Login
              },
              child: const Text("IR A INICIAR SESIÓN", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: AppConstants.dangerRed),
              SizedBox(width: 8),
              Text("Error al Registrar"),
            ],
          ),
          content: Text(result['message'] ?? 'No se pudo crear la cuenta.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendido"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final RegExp nameRegex = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñÜü ]+$');
    final RegExp dniRegex = RegExp(r'^[0-9]{8}$');
    final RegExp phoneRegex = RegExp(r'^[0-9]{9}$');

    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        title: const Text("Crear Cuenta", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoadingCatalogos
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitFadingCube(color: AppConstants.primaryNavy, size: 40),
                    SizedBox(height: 16),
                    Text("Cargando opciones del sistema...", style: TextStyle(color: AppConstants.textMuted)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConstants.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppConstants.softShadow,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Registro de Usuario",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Completa la información para crear tu cuenta en el sistema.",
                          style: TextStyle(fontSize: 13, color: AppConstants.textMuted),
                        ),
                        const SizedBox(height: 20),

                        // Nombres
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: "Nombre *",
                            prefixIcon: const Icon(Icons.person_outline, color: AppConstants.primaryBlue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Ingresa tu nombre.";
                            if (!nameRegex.hasMatch(val.trim())) {
                              return "Solo se permiten letras y espacios.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Apellidos
                        TextFormField(
                          controller: _apellidoController,
                          decoration: InputDecoration(
                            labelText: "Apellido *",
                            prefixIcon: const Icon(Icons.person_outline, color: AppConstants.primaryBlue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Ingresa tu apellido.";
                            if (!nameRegex.hasMatch(val.trim())) {
                              return "Solo se permiten letras y espacios.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // DNI
                        TextFormField(
                          controller: _dniController,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          decoration: InputDecoration(
                            labelText: "DNI *",
                            counterText: "",
                            prefixIcon: const Icon(Icons.badge_outlined, color: AppConstants.primaryBlue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || !dniRegex.hasMatch(val.trim())) {
                              return "El DNI debe tener exactamente 8 números.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Sexo
                        DropdownButtonFormField<String>(
                          value: _selectedSexo,
                          decoration: InputDecoration(
                            labelText: "Sexo",
                            prefixIcon: const Icon(Icons.wc_outlined, color: AppConstants.primaryBlue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: "M", child: Text("Masculino")),
                            DropdownMenuItem(value: "F", child: Text("Femenino")),
                          ],
                          onChanged: (val) => setState(() => _selectedSexo = val),
                        ),
                        const SizedBox(height: 14),

                        // Correo electrónico
                        TextFormField(
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Correo Electrónico",
                            prefixIcon: const Icon(Icons.email_outlined, color: AppConstants.primaryBlue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val != null && val.trim().isNotEmpty && !val.contains("@")) {
                              return "Ingresa un correo electrónico válido.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Teléfono
                        TextFormField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          maxLength: 9,
                          decoration: InputDecoration(
                            labelText: "Teléfono *",
                            counterText: "",
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppConstants.primaryBlue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || !phoneRegex.hasMatch(val.trim())) {
                              return "El teléfono debe tener exactamente 9 números.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Select Tipo de Usuario
                        DropdownButtonFormField<int>(
                          value: _selectedTipoUsuario,
                          decoration: InputDecoration(
                            labelText: "Tipo de Usuario *",
                            prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: AppConstants.primaryBlue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _tiposUsuario.map<DropdownMenuItem<int>>((item) {
                            return DropdownMenuItem<int>(
                              value: item['id'],
                              child: Text(item['nombre']),
                            );
                          }).toList(),
                          onChanged: _onTipoUsuarioChanged,
                          validator: (val) => val == null ? "Selecciona un tipo de usuario." : null,
                        ),
                        const SizedBox(height: 14),

                        // Select dinámico Oficina (si es Administrativo)
                        if (_selectedCampoExtra == 'oficina') ...[
                          DropdownButtonFormField<int>(
                            value: _selectedOficina,
                            decoration: InputDecoration(
                              labelText: "Oficina *",
                              prefixIcon: const Icon(Icons.business_outlined, color: AppConstants.primaryBlue),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _oficinas.map<DropdownMenuItem<int>>((item) {
                              return DropdownMenuItem<int>(
                                value: item['id'],
                                child: Text(item['nombre']),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedOficina = val),
                            validator: (val) => _selectedCampoExtra == 'oficina' && val == null 
                                ? "Selecciona una oficina." 
                                : null,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Select dinámico Programa de Estudios (si es Docente, Estudiante o Egresado)
                        if (_selectedCampoExtra == 'programa') ...[
                          DropdownButtonFormField<int>(
                            value: _selectedPrograma,
                            decoration: InputDecoration(
                              labelText: "Programa de Estudios *",
                              prefixIcon: const Icon(Icons.school_outlined, color: AppConstants.primaryBlue),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _programas.map<DropdownMenuItem<int>>((item) {
                              return DropdownMenuItem<int>(
                                value: item['id'],
                                child: Text(item['nombre']),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedPrograma = val),
                            validator: (val) => _selectedCampoExtra == 'programa' && val == null 
                                ? "Selecciona un programa de estudios." 
                                : null,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Nombre de Usuario
                        TextFormField(
                          controller: _usuarioController,
                          decoration: InputDecoration(
                            labelText: "Nombre de Usuario *",
                            prefixIcon: const Icon(Icons.account_circle_outlined, color: AppConstants.primaryBlue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? "Elige un usuario." : null,
                        ),
                        const SizedBox(height: 14),

                        // Contraseña
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Contraseña *",
                            prefixIcon: const Icon(Icons.lock_outline, color: AppConstants.primaryBlue),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? "Ingresa tu contraseña." : null,
                        ),
                        const SizedBox(height: 14),

                        // Confirmar Contraseña
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: "Confirmar Contraseña *",
                            prefixIcon: const Icon(Icons.lock_outline, color: AppConstants.primaryBlue),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? "Confirma tu contraseña." : null,
                        ),
                        const SizedBox(height: 24),

                        // Botón Registrarse
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SpinKitThreeBounce(color: Colors.white, size: 22)
                              : const Text(
                                  "CREAR MI CUENTA",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
