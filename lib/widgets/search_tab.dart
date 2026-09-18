import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../models/user_profile.dart';
import '../theme.dart';
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
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _searchStudent(String login) async {
    if (login.trim().isEmpty) return;

    _searchFocus.unfocus();
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
        _buildSearchBar(),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          child: KeyedSubtree(
            key: ValueKey<String>(
              '$_isLoadingSearch-$_searchError-${_searchedProfile?.login}',
            ),
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoadingSearch) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80.0),
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_searchError != null) {
      return _buildErrorWidget(_searchError!);
    }
    if (_searchedProfile != null) {
      return ProfileCard(profile: _searchedProfile!);
    }
    return _buildSearchPlaceholder();
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchFocus,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _searchFocus.hasFocus
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : AppColors.hairline,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.search,
            onSubmitted: _searchStudent,
            style: AppText.body(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
            ),
            decoration: InputDecoration(
              hintText: "Rechercher un login (ex: lrezette)",
              hintStyle: AppText.body(
                fontSize: 15,
                color: AppColors.mutedLight,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.muted,
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
                      Icons.clear_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchedProfile = null;
                        _searchError = null;
                      });
                    },
                  );
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Rechercher un étudiant",
            style: AppText.heading(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "Saisissez le login d'un étudiant pour voir son profil, ses projets et ses compétences.",
              textAlign: TextAlign.center,
              style: AppText.body(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String errorMsg) {
    final bool isEmptyResult = errorMsg == "Aucun résultat.";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isEmptyResult ? AppColors.divider : AppColors.dangerSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEmptyResult
                  ? Icons.person_off_rounded
                  : Icons.error_outline_rounded,
              size: 44,
              color: isEmptyResult ? AppColors.muted : AppColors.danger,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isEmptyResult ? "Aucun résultat" : "Une erreur est survenue",
            style: AppText.heading(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              isEmptyResult
                  ? "Vérifiez l'orthographe du login et réessayez."
                  : errorMsg,
              textAlign: TextAlign.center,
              style: AppText.body(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Même CTA que les autres écrans d'erreur (design system).
          SizedBox(
            width: 220,
            child: PrimaryButton(
              label: 'Réessayer',
              icon: Icons.refresh_rounded,
              onPressed: () {
                setState(() {
                  _searchError = null;
                });
                _searchFocus.requestFocus();
              },
            ),
          ),
        ],
      ),
    );
  }
}