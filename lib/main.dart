import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/constants.dart';
import 'models/user_model.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  UserModel? initialUser = await ApiService.getCurrentUser();
  runApp(MyApp(initialUser: initialUser));
}

class MyApp extends StatelessWidget {
  final UserModel? initialUser;

  const MyApp({Key? key, this.initialUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CONTICOMTC Móvil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryNavy,
          primary: AppConstants.primaryNavy,
          secondary: AppConstants.primaryBlue,
        ),
        scaffoldBackgroundColor: AppConstants.bgLight,
        textTheme: GoogleFonts.outfitTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: initialUser != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}
