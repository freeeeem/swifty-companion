import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_service.dart';
import 'login.dart';
import 'models/user_profile.dart';
import 'theme.dart';
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
        // Si la session a expiré et que le refresh a échoué, l'AuthService
        // a purgé les tokens : on renvoie l'utilisateur vers le login.
        if (data == null && !(await AuthService.hasSession())) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
          return;
        }

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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 8.0,
                  bottom: 110.0, // espace pour la navbar en verre
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentIndex),
                    child: _getCurrentTabWidget(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildHeader() {
    final profile = _myProfile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting.toUpperCase(),
                  style: AppText.mono(
                    fontSize: 10,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile != null ? profile.login : 'Little 42 Companion',
                  style: AppText.heading(fontSize: 20),
                ),
              ],
            ),
          ),
          if (profile?.avatarUrl != null)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  profile!.avatarUrl!,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const CircleAvatar(
                    radius: 21,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                ),
              ),
            )
          else
            const CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.primarySoft,
              child: Icon(Icons.person, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassNavBar() {
    const items = [
      (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
      (icon: Icons.search, activeIcon: Icons.search, label: 'Rechercher'),
      (
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Réglages'
      ),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1220).withValues(alpha: 0.82),
            border: const Border(
              top: BorderSide(
                color: AppColors.hairline,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: List.generate(items.length, (index) {
                  final isSelected = _currentIndex == index;
                  final item = items[index];
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _currentIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.muted,
                              size: 22,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              style: GoogleFonts.roboto(
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
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