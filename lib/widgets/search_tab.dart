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
  List<UserCandidate> _candidates = const [];
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
      _candidates = const [];
    });

    try {
      final data = await AuthService.getUserProfile(login.trim().toLowerCase());

      // Login inconnu : l'API ne fait que de la correspondance exacte, donc on
      // enchaîne sur une recherche approximative pour proposer les logins
      // voisins. Le spinner reste affiché pendant les deux appels (on ne
      // bascule l'UI qu'une fois la réponse définitive connue) : afficher
      // « Aucun résultat. » entre les deux aurait promis une erreur avant de
      // l'avoir vérifiée.
      List<UserCandidate> alternatives = const [];
      if (data == null) {
        alternatives = await AuthService.searchUsersByLogin(login.trim());
      }

      if (!mounted) return;
      setState(() {
        _isLoadingSearch = false;
        if (data != null) {
          _searchedProfile = UserProfile.fromJson(data);
        } else if (alternatives.isNotEmpty) {
          // Des correspondants partiels : on montre la liste, pas une erreur.
          _candidates = alternatives;
        } else {
          // Vrai échec : ni correspondance exacte, ni correspondance
          // partielle.
          _searchError = "Aucun résultat.";
        }
      });
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

  /// Ouvre le profil complet d'un candidat (les candidats sont des versions
  /// « light », sans projets ni compétences : il faut refaire un appel exact).
  Future<void> _openCandidate(UserCandidate candidate) async {
    setState(() {
      _isLoadingSearch = true;
      _searchError = null;
      _candidates = const [];
      _searchController.text = candidate.login;
    });

    try {
      final data = await AuthService.getUserProfile(candidate.login);
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
    } catch (e) {
      debugPrint("Error opening candidate: $e");
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
            // La clé inclut les candidats : sans elle, l'AnimatedSwitcher ne
            // rejouerait pas son fondu quand la liste remplace l'erreur.
            key: ValueKey<String>(
              '$_isLoadingSearch-$_searchError-${_searchedProfile?.login}-'
              '${_candidates.length}',
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
    // Suggestions issues de la recherche approchée : elles priment sur le
    // message d'erreur, sinon « Aucun résultat. » resterait affiché au-dessus
    // d'une liste de logins valides.
    if (_candidates.isNotEmpty) {
      return _buildCandidatesList();
    }
    if (_searchError != null) {
      return _buildErrorWidget(_searchError!);
    }
    if (_searchedProfile != null) {
      return ProfileCard(profile: _searchedProfile!);
    }
    return _buildSearchPlaceholder();
  }

  /// Liste des logins correspondants à la saisie, triés par pertinence.
  Widget _buildCandidatesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            _candidates.length == 1
                ? "1 login correspondant"
                : "${_candidates.length} logins correspondants",
            style: AppText.heading(fontSize: 15),
          ),
        ),
        for (int i = 0; i < _candidates.length; i++)
          StaggeredReveal(
            // Cascade de 40 ms : la liste se pose ligne par ligne au lieu
            // d'apparaître d'un bloc (même grammaire que ProfileCard).
            delay: Duration(milliseconds: i * 40),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCandidateTile(_candidates[i]),
            ),
          ),
      ],
    );
  }

  /// Une ligne de résultat : avatar, nom, login, chevron.
  Widget _buildCandidateTile(UserCandidate candidate) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openCandidate(candidate),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: AppCard.decoration(),
          child: Row(
            children: [
              _buildCandidateAvatar(candidate),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.heading(fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      candidate.login,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateAvatar(UserCandidate candidate) {
    final String? avatarUrl = candidate.avatarUrl;
    return ClipOval(
      child: avatarUrl != null
          ? Image.network(
              avatarUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildCandidateAvatarFallback(),
            )
          : _buildCandidateAvatarFallback(),
    );
  }

  /// Initiales sur fond neutre, quand l'utilisateur n'a pas de photo (ou que
  /// l'image 42 échoue au chargement).
  Widget _buildCandidateAvatarFallback() {
    return Container(
      width: 40,
      height: 40,
      color: AppColors.cardElevated,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 20,
        color: AppColors.muted,
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchFocus,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _searchFocus.hasFocus
                  ? AppColors.primary
                  : AppColors.hairline,
              width: 1,
            ),
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
              // Hint raccourci : "Rechercher un login (ex: lrezette)" était
              // tronqué sur mobile étroit (320 px). L'exemple reste visible
              // dans le placeholder vide sous la barre.
              hintText: 'Rechercher un login',
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
                  // Croix 44 px tactiles : l'IconButton par défaut + le
                  // padding du TextField la rendaient minuscule au doigt.
                  return IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
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
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.cardElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 30,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Rechercher un étudiant",
            style: AppText.heading(fontSize: 16),
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEmptyResult
                  ? Icons.search_off_rounded
                  : Icons.error_outline_rounded,
              size: 30,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isEmptyResult ? "Aucun résultat" : "Une erreur est survenue",
            style: AppText.heading(fontSize: 16),
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