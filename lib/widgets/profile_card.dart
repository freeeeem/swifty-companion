import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final List<ProjectItem> allProjects =
        profile.projects
            .where((p) => p.finalMark != null || p.status == 'in_progress')
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                ),
          );

    // Cascade descendante : chaque bloc apparaît 55 ms après le précédent.
    // Sans elle, les 6 cartes s'affichent d'un bloc et la page « claque » à
    // l'ouverture. L'écart est volontairement faible pour ne pas retarder
    // l'accès aux informations.
    Widget cascade(int index, Widget child) => StaggeredReveal(
      delay: Duration(milliseconds: index * 55),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        cascade(0, _buildHeaderCard(profile)),
        const SizedBox(height: 12),
        cascade(1, _buildLevelCard(level, levelInt, levelPercent)),
        const SizedBox(height: 12),
        cascade(
          2,
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
        ),
        const SizedBox(height: 12),
        cascade(
          3,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppCard.decoration(),
            child: Column(
              children: [
                _buildInfoRow(label: 'Login', value: profile.login, mono: true),
                const Divider(height: 20, color: AppColors.divider),
                // L'ID 42 (utile pour l'API / les slots) : affiché en mono,
                // copiable au tap comme le poste ci-dessus.
                _buildInfoRow(
                  label: 'ID',
                  value: '${profile.id}',
                  mono: true,
                  copyable: true,
                ),
                const Divider(height: 20, color: AppColors.divider),
                _buildInfoRow(label: 'Email', value: email),
                const Divider(height: 20, color: AppColors.divider),
                _buildInfoRow(label: 'Campus', value: profile.campus),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Projets puis compétences : deux blocs indépendants, chacun à
        // hauteur naturelle. Ni l'un ni l'autre ne dépend de la recherche
        // dans l'autre, donc ouvrir la recherche projets ne décale plus
        // la carte compétences.
        cascade(
          4,
          ProjectsCard(
            key: ValueKey('projects-${profile.login}'),
            allProjects: allProjects,
          ),
        ),
        const SizedBox(height: 12),
        cascade(5, SkillsRadarChart(skills: profile.skills)),
      ],
    );
  }

  // --- Header : avatar, nom, login, présence cluster + poste bien visible ---

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: AppText.heading(fontSize: 17, color: AppColors.dark),
                ),
                const SizedBox(height: 6),
                // Wrap plutôt que Row : sur mobile étroit (320 px), un login
                // long + la pastille ne tiennent pas sur une ligne. Avant, le
                // Flexible écrasait le login ; maintenant la pastille passe
                // sous le login au lieu de déborder.
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      login,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        fontSize: 13,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // Statut bien visible : pastille teintée (vert pâle quand
                    // en ligne) reflétant la présence sur un poste du cluster.
                    StatusPill(
                      label: isOnline ? 'En ligne' : 'Hors ligne',
                      color: isOnline
                          ? AppColors.success
                          : AppColors.mutedLight,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  campus,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppText.body(fontSize: 12, color: AppColors.muted),
                ),
                // Poste occupé (ex. "c1r2s3") : puce mono bien lisible avec
                // icône PC, au lieu du petit texte gris "Sur ..." d'avant.
                if (location != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.computer_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            location,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.mono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Aucun poste en ce moment',
                    style: AppText.body(
                      fontSize: 12,
                      color: AppColors.mutedLight,
                      fontStyle: FontStyle.italic,
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
    return Semantics(
      label: isOnline ? 'En ligne' : 'Hors ligne',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Anneau vert quand en ligne : le statut se lit même sans lire
              // la pastille (utile sur mobile où l'œil survole vite).
              border: Border.all(
                color: isOnline ? AppColors.success : AppColors.hairline,
                width: 1.5,
              ),
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
      ),
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
          // Track lisible (AppProgressBar) + remplissage anime : avant, la
          // portion vide se confondait avec la carte et la barre paraissait
          // "coupée" au niveau du fond.
          AppProgressBar(
            value: (level % 1).clamp(0.0, 1.0),
            color: AppColors.primary,
            height: 4,
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
    bool mono = false,
    bool copyable = false,
  }) {
    final textStyle = mono
        ? AppText.mono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          )
        : AppText.body(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.dark,
          );
    // Copiable : tap = copie presse-papier + feedback ; appui long =
    // sélection manuelle (utile pour un email ou un campus long).
    final valueWidget = copyable
        ? Builder(
            builder: (context) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _copyValue(context, label, value),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: textStyle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: AppColors.mutedLight,
                  ),
                ],
              ),
            ),
          )
        : SelectableText(value, textAlign: TextAlign.right, style: textStyle);
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
        const SizedBox(width: 12),
        const Spacer(),
        Flexible(flex: 3, child: Align(
          alignment: Alignment.centerRight,
          child: valueWidget,
        )),
      ],
    );
  }

  /// Copie une valeur (ID, login…) + confirme via SnackBar du langage courant.
  Future<void> _copyValue(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label copié : $value')));
  }
}

// Les types d'affichage (projets simples / groupés) vivent dans
// projects_card.dart ; profile_card les utilise via son import en tête
// de fichier au lieu d'une réexportation (interdite après une classe).
