import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Dotenv loaded successfully.");
  } catch (e) {
    debugPrint("ERROR loading .env file: $e");
  }

  bool isLoggedIn = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');
    isLoggedIn = accessToken != null;
    debugPrint("SharedPreferences loaded. isLoggedIn: $isLoggedIn");
  } catch (e) {
    debugPrint("ERROR loading SharedPreferences: $e");
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
      home: isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}
