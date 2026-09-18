import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'login.dart';
import 'models/user_profile.dart';
import 'theme.dart';
import 'widgets/profile_tab.dart';
import 'widgets/search_tab.dart';
import 'widgets/slots_tab.dart';

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
  final GlobalKey _avatarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _restoreTabIndex();
    _loadOwnProfile();
  }

  /// Restaure le dernier onglet actif (persisté) : sans ça, un refresh
  /// de la page web ramène systématiquement sur l'onglet Profil.
  Future<void> _restoreTabIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('home_tab_index') ?? 0;
    if (mounted && index >= 0 && index < 3) {
      setState(() => _currentIndex = index);
    }
  }

  Future<void> _changeTab(int index) async {
    setState(() => _currentIndex = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('home_tab_index', index);
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
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 20.0,
                      right: 20.0,
                      top: 8.0,
                      bottom: 120.0, // espace pour la navbar flottante
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.03),
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
        ],
      ),
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildHeader() {
    final profile = _myProfile;
    final name = profile != null
        ? (profile.firstName ?? profile.login)
        : 'Little 42 Companion';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.mint,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mint
                                .withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _greeting.toUpperCase(),
                      style: AppText.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(fontSize: 26),
                ),
              ],
            ),
          ),
          _buildAvatarMenu(profile),
        ],
      ),
    );
  }

  /// Photo de profil cliquable — le padding du child élargit la zone
  /// tactile (~66 px) bien au-delà de l'avatar lui-même (46 px).
  /// GestureDetector + showMenu au lieu de PopupMenuButton : aucun
  /// ripple d'appui, donc la hitbox reste invisible.
  Widget _buildAvatarMenu(UserProfile? profile) {
    return Tooltip(
      message: 'Menu du profil',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _showAvatarMenu,
          child: Padding(
            key: _avatarKey,
            // Zone tactile généreuse : 46 px d'avatar + 2 x 10 px de marge.
            padding: const EdgeInsets.all(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background,
                    ),
                    child: ClipOval(
                      child: profile?.avatarUrl != null
                          ? Image.network(
                              profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _avatarFallback(),
                            )
                          : _avatarFallback(),
                    ),
                  ),
                ),
                // Petit chevron : indice visuel que l'avatar ouvre un menu.
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ouvre le menu du profil juste sous l'avatar (aligné à droite).
  Future<void> _showAvatarMenu() async {
    final RenderBox? box =
        _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !mounted) return;

    final Offset bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
    );

    final String? value = await showMenu<String>(
      context: context,
      // Le point d'ancrage est le coin bas-droit de la zone tactile :
      // le menu s'ouvre en dessous, aligné vers la gauche du point.
      position: RelativeRect.fromLTRB(
        bottomRight.dx,
        bottomRight.dy + 6,
        bottomRight.dx,
        0,
      ),
      color: AppColors.cardElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.hairline),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'logout',
          height: 44,
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: AppColors.danger),
              const SizedBox(width: 10),
              Text(
                'Déconnexion',
                style: AppText.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!mounted) return;
    if (value == 'logout') _handleLogout();
  }

  Widget _avatarFallback() {
    return Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 24, color: AppColors.primary),
    );
  }

  Widget _buildGlassNavBar() {
    const items = [
      (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
      (icon: Icons.search, activeIcon: Icons.search, label: 'Rechercher'),
      (
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note,
        label: 'Slots',
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
                      onTap: () => _changeTab(index),
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
                              style: AppText.body(
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
        final profile = _myProfile;
        if (profile == null) {
          // Le profil n'est pas (encore) disponible : l'onglet Slots en dépend.
          return Center(
            child: Text(
              _isLoadingMyProfile
                  ? 'Chargement de votre profil…'
                  : 'Profil indisponible, impossible d\'afficher vos slots.',
              textAlign: TextAlign.center,
              style: AppText.body(fontSize: 14, color: AppColors.muted),
            ),
          );
        }
        return SlotsTab(myProfile: profile);
      default:
        return const SizedBox.shrink();
    }
  }
}