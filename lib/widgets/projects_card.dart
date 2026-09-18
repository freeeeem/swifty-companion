import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme.dart';

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

/// Carte Projets autonome : recherche locale, filtres de statut, tri
/// recents/anciens et groupes repliables.
///
/// Stateful dedie : le focus du champ de recherche et les filtres survivent
/// aux reconstructions du parent (et le radar parent n'est pas relance a
/// chaque frappe).
class ProjectsCard extends StatefulWidget {
  final List<ProjectItem> allProjects;

  const ProjectsCard({super.key, required this.allProjects});

  @override
  State<ProjectsCard> createState() => _ProjectsCardState();
}

class _ProjectsCardState extends State<ProjectsCard> {
  final Set<String> _expandedGroups = {};
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _statusFilter = 0; // 0 tous, 1 valides, 2 echoues, 3 en cours
  bool _newestFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProjectItem> get _filtered {
    final q = _query.trim().toLowerCase();
    final filtered = widget.allProjects.where((p) {
      final matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q);
      final bool matchesStatus;
      switch (_statusFilter) {
        case 1:
          matchesStatus = p.validated == true;
          break;
        case 2:
          matchesStatus = p.validated == false && p.status != 'in_progress';
          break;
        case 3:
          matchesStatus = p.status == 'in_progress';
          break;
        default:
          matchesStatus = true;
      }
      return matchesQuery && matchesStatus;
    }).toList();
    filtered.sort((a, b) {
      final ad = a.createdAt ?? a.updatedAt;
      final bd = b.createdAt ?? b.updatedAt;
      return _newestFirst ? bd.compareTo(ad) : ad.compareTo(bd);
    });
    return filtered;
  }

  List<ProjectDisplayItem> _group(List<ProjectItem> projects) {
    final cpp = projects.where((p) => p.name.startsWith('CPP Module')).toList();
    final py = projects.where((p) => p.name.startsWith('Piscine Python')).toList();
    final dj = projects.where((p) => p.name.startsWith('Piscine Django')).toList();
    final ex = projects.where((p) => p.name.startsWith('Exam')).toList();
    final groupedNames = [
      ...cpp.map((p) => p.name),
      ...py.map((p) => p.name),
      ...dj.map((p) => p.name),
      ...ex.map((p) => p.name),
    ];
    final others = projects.where((p) => !groupedNames.contains(p.name)).toList();
    for (final l in [cpp, py, dj, ex]) {
      l.sort((a, b) => a.name.compareTo(b.name));
    }
    DateTime latest(List<ProjectItem> l) {
      if (l.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
      return l
          .map((p) => p.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
    final List<ProjectDisplayItem> combined = [
      if (cpp.isNotEmpty)
        GroupedProjectDisplayItem(
            groupName: 'C++ Modules', projects: cpp, referenceDate: latest(cpp)),
      if (py.isNotEmpty)
        GroupedProjectDisplayItem(
            groupName: 'Piscine Python', projects: py, referenceDate: latest(py)),
      if (dj.isNotEmpty)
        GroupedProjectDisplayItem(
            groupName: 'Piscine Django', projects: dj, referenceDate: latest(dj)),
      if (ex.isNotEmpty)
        GroupedProjectDisplayItem(
            groupName: 'Examens', projects: ex, referenceDate: latest(ex)),
      ...others.map(SingleProjectDisplayItem.new),
    ];
    DateTime dateOf(ProjectDisplayItem item) {
      if (item is GroupedProjectDisplayItem) return item.referenceDate;
      final p = (item as SingleProjectDisplayItem).project;
      return p.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    combined.sort((a, b) => dateOf(b).compareTo(dateOf(a)));
    return combined;
  }

  Widget _chip(int value, String label) {
    final selected = _statusFilter == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppText.mono(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.background : AppColors.darkSoft,
          ),
        ),
      ),
    );
  }

  Widget _mark(bool ok, String mark, {double fontSize = 12}) {
    final color = ok ? AppColors.success : AppColors.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ok ? Icons.check_rounded : Icons.close_rounded,
            color: color, size: fontSize + 3),
        const SizedBox(width: 4),
        Text(mark,
            style: AppText.mono(
                fontSize: fontSize, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _singleRow(ProjectItem p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.75)),
      ),
      child: Row(
        children: [
          Expanded(child: _projectName(p.name)),
          const SizedBox(width: 8),
          _mark(p.validated == true, p.finalMark?.toString() ?? '-'),
        ],
      ),
    );
  }

  Widget _projectName(String name) {
    final q = _query.trim();
    final base = AppText.body(
        fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.dark);
    if (q.isEmpty) {
      return Text(name, overflow: TextOverflow.ellipsis, style: base);
    }
    final start = name.toLowerCase().indexOf(q.toLowerCase());
    if (start < 0) {
      return Text(name, overflow: TextOverflow.ellipsis, style: base);
    }
    final end = start + q.length;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: name.substring(0, start)),
        TextSpan(
            text: name.substring(start, end),
            style: const TextStyle(
                backgroundColor: AppColors.primarySoft,
                color: AppColors.primary,
                fontWeight: FontWeight.w700)),
        TextSpan(text: name.substring(end)),
      ], style: base),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _groupWidget(GroupedProjectDisplayItem g) {
    final open = _expandedGroups.contains(g.groupName);
    final okCount = g.projects.where((p) => p.validated == true).length;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              setState(() {
                if (open) {
                  _expandedGroups.remove(g.groupName);
                } else {
                  _expandedGroups.add(g.groupName);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: open ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.muted),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(g.groupName,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark)),
                  ),
                  const SizedBox(width: 8),
                  Text('$okCount/${g.projects.length}',
                      style: AppText.mono(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOut,
            crossFadeState:
                open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: g.projects.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(left: 22, top: 2, bottom: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(p.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                                fontSize: 12.5, color: AppColors.muted)),
                      ),
                      const SizedBox(width: 8),
                      _mark(p.validated == true, p.finalMark?.toString() ?? '-',
                          fontSize: 11),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = _group(_filtered);
    final bool isFiltered = _query.trim().isNotEmpty || _statusFilter != 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Projets', style: AppText.heading(fontSize: 16)),
              Row(
                children: [
                  Text(
                    '${_filtered.length}/${widget.allProjects.length}',
                    style: AppText.mono(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _newestFirst = !_newestFirst),
                    child: Row(
                      children: [
                        Icon(
                          _newestFirst
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _newestFirst ? 'Recents' : 'Anciens',
                          style: AppText.mono(
                              fontSize: 10.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            style: AppText.body(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Filtrer les projets...',
              hintStyle: AppText.body(fontSize: 13, color: AppColors.mutedLight),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
              suffixIcon: _query.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(Icons.clear_rounded, size: 17, color: AppColors.muted),
                    ),
              filled: true,
              fillColor: AppColors.cardElevated,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(0, 'Tous'),
              _chip(1, 'Valides'),
              _chip(2, 'Echoues'),
              _chip(3, 'En cours'),
            ],
          ),
          const SizedBox(height: 6),
          if (displayItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  isFiltered ? 'Aucun projet ne correspond aux filtres' : 'Aucun projet',
                  style: AppText.body(color: AppColors.muted, fontStyle: FontStyle.italic),
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
                  return _singleRow(item.project);
                } else if (item is GroupedProjectDisplayItem) {
                  return _groupWidget(item);
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }
}
