import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOwnProfile();
  }

  Future<void> _loadOwnProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await AuthService.getMe();

    if (mounted) {
      setState(() {
        _userProfile = data;
        _isLoading = false;
        if (data == null) {
          _errorMessage =
              "Une erreur est survenue durant le chargement de votre profil.";
        }
      });
    }
  }

  Future<void> _searchStudent(String login) async {
    if (login.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await AuthService.getUserProfile(login.trim().toLowerCase());

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data == null) {
          _errorMessage = "Aucun résultat.";
        } else {
          _userProfile = data;
        }
      });
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
      // appBar: AppBar(
      //   backgroundColor: Colors.blueGrey,
      //   title: Container(
      //     height: 38,
      //     decoration: BoxDecoration(
      //       color: Colors.white.withOpacity(0.2),
      //       borderRadius: BorderRadius.circular(8),
      //     ),
      //     child: TextField(
      //       style: const TextStyle(
      //         color: Colors.white,
      //         fontSize: 14,
      //         fontFamily: 'Arial',
      //       ),
      //       decoration: const InputDecoration(
      //         hintText: 'Rechercher',
      //         hintStyle: TextStyle(
      //           color: Colors.white60,
      //           fontSize: 13,
      //           fontFamily: 'Arial',
      //         ),
      //         prefixIcon: Icon(Icons.search, color: Colors.white60, size: 20),
      //         border: InputBorder.none,
      //         contentPadding: EdgeInsets.symmetric(vertical: 9),
      //       ),
      //       textInputAction: TextInputAction.search,
      //       onSubmitted: (value) {
      //         _searchStudent(value);
      //       },
      //     ),
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.logout),
      //       onPressed: _handleLogout,
      //       tooltip: 'Se déconnecter',
      //       color: Colors.white,
      //     ),
      //   ],
      // ),
      backgroundColor: Colors.grey[75],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOwnProfile,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final String displayName = _userProfile?['displayname'] ?? 'Erreur';
    final String login = _userProfile?['login'] ?? 'N/A';
    final String email = _userProfile?['email'] ?? 'N/A';
    final String? avatarUrl = _userProfile?['image']?['versions']?['medium'];
    final String campus = _userProfile?['campus'][0]['name'] ?? 'N/A';
    final double level = _userProfile?['cursus_users'][1]['level'] ?? 0.0;
    final int levelInt = level.floor();
    final int levelPercent = ((level - levelInt) * 100).round();
    final int wallet = _userProfile?['wallet'] ?? 0;
    final int correctionsPoints = _userProfile?['correction_point'] ?? 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Avatar with shadow and border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(75),
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 130,
                          height: 130,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(
                            Icons.account_circle,
                            size: 100,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      )
                    : Container(
                        width: 130,
                        height: 130,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.account_circle,
                          size: 100,
                          color: Color(0xFF0F172A),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Display Name
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            // Login/Handle
            Text(
              login,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Level Progress Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level $levelInt',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '$levelPercent%',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (level % 1),
                      minHeight: 10,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFF0F172A),
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$wallet ₳',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Wallet',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.reviews_outlined,
                          color: Color(0xFF0F172A),
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$correctionsPoints',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Correction Points',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info Card (Email & Campus)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: email,
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Campus',
                    value: campus,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
