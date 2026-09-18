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

/// Carte Projets : titre + actions (recherche ouvrable, tri), chips de
/// statut sobres, liste sobre. La barre de recherche ne prend de la place
/// que quand elle est ouverte.
class ProjectsCard extends StatefulWidget {
  final List<ProjectItem> allProjects;

  const ProjectsCard({super.key, required this.allProjects});

  @override
  State<ProjectsCard> createState() => _ProjectsCardState();
}

class _ProjectsCardState extends State<ProjectsCard> {
  final Set<String> _expandedGroups = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  bool _searchOpen = false;
  int _statusFilter = 0; // 0 tous, 1 valides, 2 echoues, 3 en cours
  bool _newestFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
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

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (_searchOpen) {
        _searchFocus.requestFocus();
      } else {
        _searchController.clear();
        _query = '';
        _searchFocus.unfocus();
      }
    });
  }

  Widget _chip(int value, String label) {
    final selected = _statusFilter == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.dark : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.dark : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppText.body(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.background : AppColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _mark(bool ok, String mark, {bool inProgress = false}) {
    final Color color;
    final String text;
    if (inProgress) {
      color = AppColors.primary;
      text = 'En cours';
    } else {
      color = ok ? AppColors.success : AppColors.muted;
      text = mark;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: AppText.body(
                fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.darkSoft)),
      ],
    );
  }

  Widget _singleRow(ProjectItem p) {
    final inProgress = p.status == 'in_progress';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.75)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(p.name,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.dark)),
          ),
          const SizedBox(width: 8),
          _mark(p.validated == true, p.finalMark?.toString() ?? '-', inProgress: inProgress),
        ],
      ),
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(open ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                      size: 18, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(g.groupName,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dark)),
                  ),
                  const SizedBox(width: 8),
                  Text('$okCount/${g.projects.length}',
                      style: AppText.body(
                          fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
          if (open)
            ...g.projects.map((p) {
              final inProgress = p.status == 'in_progress';
              return Padding(
                padding: const EdgeInsets.only(left: 22, top: 2, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(p.name,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(fontSize: 12.5, color: AppColors.muted)),
                    ),
                    const SizedBox(width: 8),
                    _mark(p.validated == true, p.finalMark?.toString() ?? '-',
                        inProgress: inProgress),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = _group(_filtered);
    final bool isFiltered = _query.trim().isNotEmpty || _statusFilter != 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Projets', style: AppText.heading(fontSize: 15)),
              const SizedBox(width: 8),
              Text(
                '${_filtered.length}',
                style: AppText.body(fontSize: 12, color: AppColors.muted),
              ),
              const Spacer(),
              IconButton(
                tooltip: _newestFirst ? 'Trier : recents' : 'Trier : anciens',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _newestFirst = !_newestFirst),
                icon: Icon(
                  _newestFirst ? Icons.south_rounded : Icons.north_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
              ),
              IconButton(
                tooltip: 'Rechercher',
                visualDensity: VisualDensity.compact,
                onPressed: _toggleSearch,
                icon: Icon(
                  _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                  size: 18,
                  color: _searchOpen ? AppColors.dark : AppColors.muted,
                ),
              ),
            ],
          ),
          if (_searchOpen) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (v) => setState(() => _query = v),
              style: AppText.body(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Filtrer les projets...',
                hintStyle: AppText.body(fontSize: 13, color: AppColors.mutedLight),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
                filled: true,
                fillColor: AppColors.cardElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
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
          const SizedBox(height: 4),
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
