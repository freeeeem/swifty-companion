import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;
import '../models/user_profile.dart';
import '../theme.dart';
import 'projects_card.dart';
import 'skills_radar_chart.dart';

class ProfileCard extends StatefulWidget {
  final UserProfile profile;

  const ProfileCard({super.key, required this.profile});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  /// Hauteur mesurée de la carte Projets, réutilisée pour la carte
  /// Compétences afin que les deux cartes soient strictement égales.
  double? _projectsCardHeight;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final String email = profile.email;
    final double level = profile.level;
    final int levelInt = profile.levelInt;
    final int levelPercent = profile.levelPercent;
    final int wallet = profile.wallet;
    final int correctionsPoints = profile.correctionPoints;
    final List<ProjectItem> allProjects = profile.projects
        .where((p) => p.finalMark != null || p.status == 'in_progress')
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        _buildHeaderCard(profile),
        const SizedBox(height: 12),
        _buildLevelCard(level, levelInt, levelPercent),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                value: '$wallet',
                unit: '₳',
                label: 'WALLET',
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                value: '$correctionsPoints',
                unit: 'pts',
                label: 'CORRECTION',
                icon: Icons.fact_check_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppCard.decoration(),
          child: Column(
            children: [
              _buildInfoRow(
                label: 'Email',
                value: email,
              ),
              const Divider(height: 20, color: AppColors.divider),
              _buildInfoRow(
                label: 'Campus',
                value: profile.campus,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 580;
            final projectsCard = ProjectsCard(
              key: ValueKey('projects-${profile.login}'),
              allProjects: allProjects,
            );

            final skillsChart =
                SkillsRadarChart(skills: profile.skills, expand: isWide);

            if (isWide) {
              // Les deux cartes prennent la même hauteur : celle de la carte
              // Projets, mesurée après le premier frame.
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MeasureSize(
                      onChange: (size) {
                        if (_projectsCardHeight != size.height) {
                          setState(() => _projectsCardHeight = size.height);
                        }
                      },
                      child: projectsCard,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      // Repli le temps de la première mesure post-frame.
                      height: _projectsCardHeight ?? 320.0,
                      child: skillsChart,
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  projectsCard,
                  const SizedBox(height: 12),
                  skillsChart,
                ],
              );
            }
          },
        ),
      ],
    );
  }

  // --- Header sombre avec avatar, nom, login et présence cluster ---

  Widget _buildHeaderCard(UserProfile profile) {
    final String displayName = profile.displayName;
    final String login = profile.login;
    final String campus = profile.campus;
    final String? avatarUrl = profile.avatarUrl;
    final String? location = profile.location;
    final bool isOnline = location != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          _buildAvatar(avatarUrl, isOnline),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.heading(
                    fontSize: 19,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        login,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mono(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Vrai statut : la pastille + le libellé reflètent la
                    // présence sur un poste du cluster (champ location).
                    StatusPill(
                      label: isOnline ? 'EN LIGNE' : 'HORS LIGNE',
                      color: isOnline
                          ? AppColors.success
                          : AppColors.mutedLight,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      size: 13,
                      color: AppColors.mutedLight,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        campus,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          fontSize: 12,
                          color: AppColors.mutedLight,
                        ),
                      ),
                    ),
                  ],
                ),
                // Poste occupé quand connu (ex. "En ce moment : c1r2s3").
                if (location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.computer_rounded,
                        size: 13,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'En ce moment : $location',
                          overflow: TextOverflow.ellipsis,
                          style: AppText.mono(
                            fontSize: 11.5,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildAvatarPlaceholder(),
                  )
                : _buildAvatarPlaceholder(),
          ),
          // Pastille de présence : verte sur un poste du cluster
          // (location non null), grise sinon.
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card,
                border: Border.all(color: AppColors.card, width: 2),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.success : AppColors.mutedLight,
                  boxShadow: [
                    if (isOnline)
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 68,
      height: 68,
      color: AppColors.cardElevated,
      child: const Icon(
        Icons.person_rounded,
        size: 34,
        color: AppColors.mutedLight,
      ),
    );
  }

  // --- Barre de niveau segmentée (blocs, esprit 42) ---

  Widget _buildLevelCard(double level, int levelInt, int levelPercent) {
    const segments = 20;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'NIVEAU ',
                      style: AppText.mono(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: '$levelInt',
                      style: AppText.mono(
                        fontSize: 15,
                        color: AppColors.dark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$levelPercent%',
                style: AppText.mono(
                  fontSize: 13,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: level % 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              final filled = value * segments;
              return Row(
                children: List.generate(segments, (i) {
                  final isFilled = i < filled;
                  final isPartial = !isFilled && i - 1 < filled && filled > i;
                  return Expanded(
                    child: Container(
                      height: 8,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: isFilled || isPartial
                            ? AppColors.primary
                            : AppColors.cardElevated,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Stats ---

  Widget _buildStatCard({
    required String value,
    required String unit,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.mono(
                    fontSize: 10,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppText.mono(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: unit,
                  style: AppText.mono(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Infos ---

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.mono(
            fontSize: 10,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppText.body(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }
}

// Mesure la taille de son enfant après chaque frame (pour aligner les cartes).
class _MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSize({required this.onChange, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMeasureSize renderObject) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  ValueChanged<Size> onChange;
  Size? _oldSize;

  _RenderMeasureSize(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child!.size;
    if (_oldSize == null || _oldSize != newSize) {
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
    }
  }
}

// Les types d'affichage (projets simples / groupés) vivent dans
// projects_card.dart ; profile_card les utilise via son import en tête
// de fichier au lieu d'une réexportation (interdite après une classe).