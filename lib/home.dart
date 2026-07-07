import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_service.dart';
import 'login.dart';
import 'models/user_profile.dart';
import 'widgets/profile_tab.dart';
import 'widgets/search_tab.dart';
import 'widgets/settings_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserProfile? _myProfile;
  bool _isLoadingMyProfile = true;
  String? _myProfileError;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadOwnProfile();
  }

  Future<void> _loadOwnProfile() async {
    setState(() {
      _isLoadingMyProfile = true;
      _myProfileError = null;
    });

    try {
      final data = await AuthService.getMe();

      if (mounted) {
        setState(() {
          _myProfile = data != null ? UserProfile.fromJson(data) : null;
          _isLoadingMyProfile = false;
          if (data == null) {
            _myProfileError =
                "Une erreur est survenue durant le chargement de votre profil.";
          }
        });
      }
    } catch (e, stack) {
      debugPrint("Error loading profile: $e\n$stack");
      if (mounted) {
        setState(() {
          _isLoadingMyProfile = false;
          _myProfileError = "Erreur de chargement: $e";
        });
      }
    }
  }

  void _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 20.0,
              bottom: 100.0, // Added padding to scroll above the glass navbar
            ),
            child: _getCurrentTabWidget(),
          ),
        ),
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              border: Border(
                top: BorderSide(
                  color: Colors.black.withValues(alpha: 0.05),
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              selectedItemColor: const Color(0xFF00BABC),
              unselectedItemColor: const Color(0xFF64748B),
              selectedLabelStyle: GoogleFonts.roboto(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person, color: Color(0xFF00BABC)),
                  label: 'Profil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  activeIcon: Icon(Icons.search, color: Color(0xFF00BABC)),
                  label: 'Rechercher',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings, color: Color(0xFF00BABC)),
                  label: 'Réglages',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCurrentTabWidget() {
    switch (_currentIndex) {
      case 0:
        return ProfileTab(
          profile: _myProfile,
          isLoading: _isLoadingMyProfile,
          error: _myProfileError,
          onRetry: _loadOwnProfile,
        );
      case 1:
        return const SearchTab();
      case 2:
        return SettingsTab(
          myProfile: _myProfile,
          onLogout: _handleLogout,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
