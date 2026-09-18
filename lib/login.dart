import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'home.dart';
import 'theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _loginWith42() async {
    setState(() {
      _isLoading = true;
    });

    final String? token = await AuthService.loginWith42();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (token != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de la connexion'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo sobre : simple carte mate, pas de lueur.
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 88,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Ton compagnon 42',
                    textAlign: TextAlign.center,
                    style: AppText.heading(fontSize: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Consultez vos infos de l\'Intra 42\nen un coup d\'œil',
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      color: AppColors.muted,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // CTA principal : composant partagé du design system.
                  SizedBox(
                    width: 260,
                    child: PrimaryButton(
                      label: 'Se connecter avec 42',
                      icon: Icons.login_rounded,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _loginWith42,
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