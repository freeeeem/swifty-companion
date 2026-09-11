import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import 'home.dart';
import 'login.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Dotenv loaded successfully.");
  } catch (e) {
    debugPrint("ERROR loading .env file: $e");
  }

  // Une session existe tant qu'un token est stocké. Même expiré, il sera
  // rafraîchi automatiquement via le refresh token au premier appel API.
  bool isLoggedIn = false;
  try {
    isLoggedIn = await AuthService.hasSession();
    debugPrint("Session loaded. isLoggedIn: $isLoggedIn");
  } catch (e) {
    debugPrint("ERROR loading session: $e");
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isLoggedIn});
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Little 42 Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}