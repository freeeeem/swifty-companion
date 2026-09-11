import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;
import '../models/user_profile.dart';
import '../theme.dart';
import 'skills_radar_chart.dart';

class ProfileCard extends StatefulWidget {
  final UserProfile profile;

  const ProfileCard({super.key, required this.profile});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  final Set<String> _expandedGroups = {};

  /// Hauteur mesurée de la carte Projets, réutilisée pour la carte
  /// Compétences afin que les deux cartes soient strictement égales.
  double? _projectsCardHeight;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final String displayName = profile.displayName;
    final String login = profile.login;
    final String email = profile.email;
    final String? avatarUrl = profile.avatarUrl;
    final String campus = profile.campus;
    final double level = profile.level;
    final int levelInt = profile.levelInt;
    final int levelPercent = profile.levelPercent;
    final int wallet = profile.wallet;
    final int correctionsPoints = profile.correctionPoints;
    final List<ProjectItem> allProjects = profile.projects
        .where((p) => p.finalMark != null)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        _buildHeaderCard(displayName, login, campus, avatarUrl, levelInt),
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                value: '$correctionsPoints',
                unit: 'pts',
                label: 'CORRECTION',
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
                value: campus,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 580;
            final displayItems = _groupProjects(allProjects);

            final projectsCard = Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              decoration: AppCard.decoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Projets", style: AppText.heading(fontSize: 16)),
                      Text(
                        '${allProjects.length} projets',
                        style: AppText.mono(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (displayItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          "Aucun projet",
                          style: AppText.body(
                            color: AppColors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: displayItems.length,
                      itemBuilder: (context, index) {
                        final item = displayItems[index];
                        if (item is SingleProjectDisplayItem) {
                          return _buildSingleProjectRow(item.project);
                        } else if (item is GroupedProjectDisplayItem) {
                          return _buildGroupWidget(item);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
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

  List<ProjectDisplayItem> _groupProjects(List<ProjectItem> allProjects) {
    final cppProjects =
        allProjects.where((p) => p.name.startsWith('CPP Module')).toList();
    final pythonProjects =
        allProjects.where((p) => p.name.startsWith('Piscine Python')).toList();
    final djangoProjects =
        allProjects.where((p) => p.name.startsWith('Piscine Django')).toList();
    final examProjects =
        allProjects.where((p) => p.name.startsWith('Exam')).toList();

    final groupedNames = [
      ...cppProjects.map((p) => p.name),
      ...pythonProjects.map((p) => p.name),
      ...djangoProjects.map((p) => p.name),
      ...examProjects.map((p) => p.name),
    ];

    final otherProjects =
        allProjects.where((p) => !groupedNames.contains(p.name)).toList();

    cppProjects.sort((a, b) => a.name.compareTo(b.name));
    pythonProjects.sort((a, b) => a.name.compareTo(b.name));
    djangoProjects.sort((a, b) => a.name.compareTo(b.name));
    examProjects.sort((a, b) => a.name.compareTo(b.name));

    DateTime getLatestCreate(List<ProjectItem> list) {
      if (list.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
      return list
          .map((p) => p.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    final List<GroupedProjectDisplayItem> groups = [];
    if (cppProjects.isNotEmpty) {
      groups.add(GroupedProjectDisplayItem(
          groupName: "C++ Modules",
          projects: cppProjects,
          referenceDate: getLatestCreate(cppProjects)));
    }
    if (pythonProjects.isNotEmpty) {
      groups.add(GroupedProjectDisplayItem(
          groupName: "Piscine Python",
          projects: pythonProjects,
          referenceDate: getLatestCreate(pythonProjects)));
    }
    if (djangoProjects.isNotEmpty) {
      groups.add(GroupedProjectDisplayItem(
          groupName: "Piscine Django",
          projects: djangoProjects,
          referenceDate: getLatestCreate(djangoProjects)));
    }
    if (examProjects.isNotEmpty) {
      groups.add(GroupedProjectDisplayItem(
          groupName: "Examens",
          projects: examProjects,
          referenceDate: getLatestCreate(examProjects)));
    }

    final List<SingleProjectDisplayItem> singles =
        otherProjects.map((p) => SingleProjectDisplayItem(p)).toList();

    final List<ProjectDisplayItem> combined = [
      ...groups,
      ...singles,
    ];

    combined.sort((a, b) {
      final dateA = a is GroupedProjectDisplayItem
          ? a.referenceDate
          : ((a as SingleProjectDisplayItem).project.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0));
      final dateB = b is GroupedProjectDisplayItem
          ? b.referenceDate
          : ((b as SingleProjectDisplayItem).project.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0));
      return dateB.compareTo(dateA);
    });

    return combined;
  }

  // --- Header sombre avec avatar, nom et login ---

  Widget _buildHeaderCard(String displayName, String login, String campus,
      String? avatarUrl, int levelInt) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          _buildAvatar(avatarUrl),
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
                Text(
                  login,
                  style: AppText.mono(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: ClipOval(
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.mono(
              fontSize: 10,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
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

  // --- Projets ---

  Widget _buildMark(bool isValidated, String markStr, {double fontSize = 12}) {
    final color = isValidated ? AppColors.success : AppColors.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValidated ? Icons.check_rounded : Icons.close_rounded,
          color: color,
          size: fontSize + 3,
        ),
        const SizedBox(width: 4),
        Text(
          markStr,
          style: AppText.mono(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleProjectRow(ProjectItem project) {
    final isValidated = project.validated == true;
    final markStr = project.finalMark?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.75),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              project.name,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildMark(isValidated, markStr),
        ],
      ),
    );
  }

  Widget _buildGroupWidget(GroupedProjectDisplayItem groupItem) {
    final isExpanded = _expandedGroups.contains(groupItem.groupName);
    final validatedCount =
        groupItem.projects.where((p) => p.validated == true).length;
    final totalCount = groupItem.projects.length;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(groupItem.groupName);
                } else {
                  _expandedGroups.add(groupItem.groupName);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.mutedLight,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      groupItem.groupName,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$validatedCount/$totalCount",
                    style: AppText.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: validatedCount == totalCount
                          ? AppColors.success
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOut,
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: groupItem.projects
                  .map((p) => _buildSubProjectRow(p))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubProjectRow(ProjectItem project) {
    final isValidated = project.validated == true;
    final markStr = project.finalMark?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.only(left: 22, top: 2, bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              project.name,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                fontSize: 12.5,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildMark(isValidated, markStr, fontSize: 11),
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

// Display Items for Projects list
abstract class ProjectDisplayItem {}

class SingleProjectDisplayItem extends ProjectDisplayItem {
  final ProjectItem project;
  SingleProjectDisplayItem(this.project);
}

class GroupedProjectDisplayItem extends ProjectDisplayItem {
  final String groupName;
  final List<ProjectItem> projects;
  final DateTime referenceDate;

  GroupedProjectDisplayItem({
    required this.groupName,
    required this.projects,
    required this.referenceDate,
  });
}