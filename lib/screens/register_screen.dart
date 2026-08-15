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

    setState(() => _isLoading = true);

    final result = await ApiService.register(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      dni: _dniController.text.trim(),
      correo: _correoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      usuario: _usuarioController.text.trim(),
      password: _passwordController.text,
      tipoUsuario: 3, // Estudiante / Solicitante por defecto
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
    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        title: const Text("Crear Cuenta", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    "Registro de Solicitante",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Ingresa tus datos personales para acceder a tus trámites.",
                    style: TextStyle(fontSize: 13, color: AppConstants.textMuted),
                  ),
                  const SizedBox(height: 20),

                  // Nombres
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: "Nombres *",
                      prefixIcon: const Icon(Icons.person_outline, color: AppConstants.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? "Ingresa tus nombres." : null,
                  ),
                  const SizedBox(height: 14),

                  // Apellidos
                  TextFormField(
                    controller: _apellidoController,
                    decoration: InputDecoration(
                      labelText: "Apellidos *",
                      prefixIcon: const Icon(Icons.person_outline, color: AppConstants.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? "Ingresa tus apellidos." : null,
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
                      if (val == null || val.trim().length < 8) {
                        return "Ingresa un DNI válido de 8 dígitos.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Correo electrónico
                  TextFormField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Correo Electrónico *",
                      prefixIcon: const Icon(Icons.email_outlined, color: AppConstants.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || !val.contains("@")) {
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
                    decoration: InputDecoration(
                      labelText: "Teléfono / Celular",
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppConstants.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

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
                    validator: (val) => val == null || val.length < 4 ? "Mínimo 4 caracteres." : null,
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
