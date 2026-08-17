import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import '../services/update_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkAndShowUpdateDialog(context);
    });
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ApiService.login(
      _usuarioController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("¡Bienvenido al sistema!"),
            ],
          ),
          backgroundColor: AppConstants.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
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
              Text("Error de Ingreso"),
            ],
          ),
          content: Text(result['message'] ?? 'Usuario o contraseña incorrectos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Aceptar", style: TextStyle(color: AppConstants.primaryNavy, fontWeight: FontWeight.bold)),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Encabezado e Isotipo Institucional
                Image.asset(
                  'imagen/logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 14),
                const Text(
                  "SIS TRÁMITE",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryNavy,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Sistema de Trámite Documentario Móvil",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textMuted,
                  ),
                ),
                const SizedBox(height: 32),

                // Tarjeta Principal de Formulario
                Container(
                  padding: const EdgeInsets.all(24),
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
                          "Iniciar Sesión",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textDark,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Campo Usuario / DNI / Correo
                        TextFormField(
                          controller: _usuarioController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: "Usuario, DNI o Correo",
                            hintText: "Ingrese su usuario o DNI",
                            prefixIcon: const Icon(Icons.person_outline, color: AppConstants.primaryBlue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppConstants.primaryBlue, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Ingrese su usuario o correo.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Contraseña
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Contraseña",
                            hintText: "Ingrese su contraseña",
                            prefixIcon: const Icon(Icons.lock_outline, color: AppConstants.primaryBlue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppConstants.textMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppConstants.primaryBlue, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Ingrese su contraseña.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Botón de Iniciar Sesión
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SpinKitThreeBounce(color: Colors.white, size: 22)
                              : const Text(
                                  "INGRESAR AL SISTEMA",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Enlace a Registro de Cuenta Nueva
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "¿No tienes una cuenta? ",
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        "Regístrate aquí",
                        style: TextStyle(
                          color: AppConstants.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
