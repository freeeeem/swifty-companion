import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_profile.dart';
import 'skills_radar_chart.dart';

class ProfileCard extends StatefulWidget {
  final UserProfile profile;

  const ProfileCard({super.key, required this.profile});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  final Set<String> _expandedGroups = {};

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
        const SizedBox(height: 45),
        // Avatar with shadow and border
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
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
                      width: 120,
                      height: 120,
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
        const SizedBox(height: 12),
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
        // Login/Handle
        Text(
          login,
          style: GoogleFonts.roboto(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // Level Progress Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
        const SizedBox(height: 10),
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
                      color: Colors.black.withValues(alpha: 0.04),
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
                      size: 20,
                    ),
                    const SizedBox(height: 2),
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
            const SizedBox(width: 10),
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
                      color: Colors.black.withValues(alpha: 0.04),
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
                      size: 20,
                    ),
                    const SizedBox(height: 2),
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
        const SizedBox(height: 10),

        // Info Card (Email & Campus)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
        const SizedBox(height: 10),

        // 3 last projects
        // Grouped projects with scrollable layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 580;
            final displayItems = _groupProjects(allProjects);

            final projectsCard = Container(
              height: isWide ? 322 : 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                        "Projets",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "${allProjects.length}",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (displayItems.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          "Aucun projet",
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
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
                    ),
                ],
              ),
            );

            final skillsChart = SkillsRadarChart(skills: profile.skills);

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: projectsCard),
                  const SizedBox(width: 16),
                  Expanded(child: skillsChart),
                ],
              );
            } else {
              return Column(
                children: [
                  projectsCard,
                  const SizedBox(height: 10),
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
    // Grouping C++ modules
    final cppProjects = allProjects.where((p) => p.name.startsWith('CPP Module')).toList();
    // Grouping Python Piscine modules
    final pythonProjects = allProjects.where((p) => p.name.startsWith('Piscine Python')).toList();
    // Grouping Django Piscine modules
    final djangoProjects = allProjects.where((p) => p.name.startsWith('Piscine Django')).toList();
    // Grouping Exams
    final examProjects = allProjects.where((p) => p.name.startsWith('Exam')).toList();

    // Collect all grouped names
    final groupedNames = [
      ...cppProjects.map((p) => p.name),
      ...pythonProjects.map((p) => p.name),
      ...djangoProjects.map((p) => p.name),
      ...examProjects.map((p) => p.name),
    ];

    // The remaining projects are single
    final otherProjects = allProjects.where((p) => !groupedNames.contains(p.name)).toList();

    // Sort subprojects in groups ascending (e.g. CPP Module 00, CPP Module 01, etc.)
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
      groups.add(GroupedProjectDisplayItem(groupName: "C++ Modules", projects: cppProjects, referenceDate: getLatestCreate(cppProjects)));
    }
    if (pythonProjects.isNotEmpty) {
      groups.add(GroupedProjectDisplayItem(groupName: "Piscine Python", projects: pythonProjects, referenceDate: getLatestCreate(pythonProjects)));
    }
    if (djangoProjects.isNotEmpty) {
      groups.add(GroupedProjectDisplayItem(groupName: "Piscine Django", projects: djangoProjects, referenceDate: getLatestCreate(djangoProjects)));
    }
    if (examProjects.isNotEmpty) {
      groups.add(GroupedProjectDisplayItem(groupName: "Examens", projects: examProjects, referenceDate: getLatestCreate(examProjects)));
    }

    final List<SingleProjectDisplayItem> singles = otherProjects
        .map((p) => SingleProjectDisplayItem(p))
        .toList();

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

  Widget _buildSingleProjectRow(ProjectItem project) {
    final isValidated = project.validated == true;
    final markStr = project.finalMark?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              project.name,
              style: GoogleFonts.roboto(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Icon(
              isValidated ? Icons.check : Icons.close,
              color: isValidated ? Colors.green : Colors.red,
              size: 19,
            ),
          ),
          const SizedBox(width: 0),
          SizedBox(
            width: 32,
            child: Text(
              markStr,
              textAlign: TextAlign.right,
              style: GoogleFonts.roboto(
                color: isValidated ? Colors.green : Colors.red,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupWidget(GroupedProjectDisplayItem groupItem) {
    final isExpanded = _expandedGroups.contains(groupItem.groupName);
    final validatedCount = groupItem.projects.where((p) => p.validated == true).length;
    final totalCount = groupItem.projects.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
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
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        groupItem.groupName,
                        style: GoogleFonts.roboto(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$validatedCount/$totalCount",
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...groupItem.projects.map((p) => _buildSubProjectRow(p)),
      ],
    );
  }

  Widget _buildSubProjectRow(ProjectItem project) {
    final isValidated = project.validated == true;
    final markStr = project.finalMark?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              project.name,
              style: GoogleFonts.roboto(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Icon(
              isValidated ? Icons.check : Icons.close,
              color: isValidated ? Colors.green : Colors.red,
              size: 17,
            ),
          ),
          const SizedBox(width: 0),
          SizedBox(
            width: 32,
            child: Text(
              markStr,
              textAlign: TextAlign.right,
              style: GoogleFonts.roboto(
                color: isValidated ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
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
