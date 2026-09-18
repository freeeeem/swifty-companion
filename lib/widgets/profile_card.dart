import 'package:flutter/material.dart';
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
                label: 'Wallet',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                value: '$correctionsPoints',
                unit: 'pts',
                label: 'Correction',
                icon: Icons.check_outlined,
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
        // Projets puis compétences : deux blocs indépendants, chacun à
        // hauteur naturelle. Le radar a une hauteur fixe (voir
        // SkillsRadarChart) donc la recherche ne le fait plus bouger.
        ProjectsCard(
          key: ValueKey('projects-${profile.login}'),
          allProjects: allProjects,
        ),
        const SizedBox(height: 12),
        SkillsRadarChart(skills: profile.skills),
      ],
    );
  }

  // --- Header simple : avatar, nom, login et présence cluster ---

  Widget _buildHeaderCard(UserProfile profile) {
    final String displayName = profile.displayName;
    final String login = profile.login;
    final String campus = profile.campus;
    final String? avatarUrl = profile.avatarUrl;
    final String? location = profile.location;
    final bool isOnline = location != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCard.decoration(),
      child: Row(
        children: [
          _buildAvatar(avatarUrl, isOnline),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.heading(
                    fontSize: 17,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        login,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          fontSize: 13,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Vrai statut : pastille mate + libellé sobre reflétant
                    // la présence sur un poste du cluster (champ location).
                    StatusPill(
                      label: isOnline ? 'En ligne' : 'Hors ligne',
                      color: isOnline
                          ? AppColors.success
                          : AppColors.mutedLight,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        campus,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                // Poste occupé quand connu (ex. "Sur c1r2s3").
                if (location != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Sur $location',
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.hairline, width: 1.5),
          ),
          child: ClipOval(
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildAvatarPlaceholder(),
                  )
                : _buildAvatarPlaceholder(),
          ),
        ),
        // Pastille de présence mate, sans lueur.
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.success : AppColors.mutedLight,
              border: Border.all(color: AppColors.card, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.cardElevated,
      child: const Icon(
        Icons.person_rounded,
        size: 32,
        color: AppColors.mutedLight,
      ),
    );
  }

  // --- Niveau : simple barre fine, sans segments ni animation ---

  Widget _buildLevelCard(double level, int levelInt, int levelPercent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Niveau $levelInt',
                style: AppText.body(
                  fontSize: 13,
                  color: AppColors.dark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$levelPercent%',
                style: AppText.body(
                  fontSize: 13,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (level % 1).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.cardElevated,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppText.body(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppText.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
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
          label,
          style: AppText.body(
            fontSize: 13,
            color: AppColors.muted,
            fontWeight: FontWeight.w400,
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

// Les types d'affichage (projets simples / groupés) vivent dans
// projects_card.dart ; profile_card les utilise via son import en tête
// de fichier au lieu d'une réexportation (interdite après une classe).