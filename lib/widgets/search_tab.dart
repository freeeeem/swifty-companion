import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth_service.dart';
import '../models/user_profile.dart';
import 'profile_card.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  UserProfile? _searchedProfile;
  bool _isLoadingSearch = false;
  String? _searchError;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchStudent(String login) async {
    if (login.trim().isEmpty) return;

    setState(() {
      _isLoadingSearch = true;
      _searchError = null;
      _searchedProfile = null;
    });

    try {
      final data = await AuthService.getUserProfile(login.trim().toLowerCase());

      if (mounted) {
        setState(() {
          _isLoadingSearch = false;
          if (data == null) {
            _searchError = "Aucun résultat.";
          } else {
            _searchedProfile = UserProfile.fromJson(data);
          }
        });
      }
    } catch (e, stack) {
      debugPrint("Error searching student: $e\n$stack");
      if (mounted) {
        setState(() {
          _isLoadingSearch = false;
          _searchError = "Erreur de recherche: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSpotifySearchBar(),
        const SizedBox(height: 20),
        if (_isLoadingSearch)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 80.0),
            child: CircularProgressIndicator(
              color: Color(0xFF00BABC),
            ),
          )
        else if (_searchError != null)
          _buildErrorWidget(
            _searchError!,
            () {
              setState(() {
                _searchError = null;
              });
            },
          )
        else if (_searchedProfile != null)
          ProfileCard(profile: _searchedProfile!)
        else
          _buildSearchPlaceholder(),
      ],
    );
  }

  Widget _buildSpotifySearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) => _searchStudent(value),
        style: GoogleFonts.roboto(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: "Rechercher un login (ex: lrezette)",
          hintStyle: GoogleFonts.roboto(
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF64748B),
            size: 22,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () {
                  _searchController.clear();
                },
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSearchPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search,
            size: 80,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            "Rechercher un étudiant",
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "Saisissez le login d'un étudiant pour voir son profil, ses projets et ses compétences.",
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String errorMsg, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            errorMsg,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              "Réessayer",
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
