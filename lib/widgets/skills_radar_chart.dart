import 'package:flutter/material.dart';
import '../theme.dart';

/// Traduction FR des noms de competences renvoyes par l'API 42 (en
/// anglais). Recherche par cle normalisee (minuscules) pour etre robuste
/// aux variations de casse.
const Map<String, String> _skillNameFr = {
  'algorithms & ai': 'Algorithmique & IA',
  'basic programming': 'Programmation de base',
  'unix': 'Unix',
  'network & system administration': 'Administration reseau & systeme',
  'imperative programming': 'Programmation imperative',
  'object-oriented programming': 'Programmation orientee objet',
  'graphics': 'Graphisme',
  'web': 'Web',
  'security': 'Securite',
  'db & data': 'Bases de donnees & Data',
  'data science': 'Science des donnees',
  'functional programming': 'Programmation fonctionnelle',
  'rigor': 'Rigueur',
  'organization': 'Organisation',
  'adaptation & creativity': 'Adaptation & creativite',
  'adaptability & group work': 'Adaptabilite & travail de groupe',
  'company experience': 'Experience en entreprise',
  'digital exposure': 'Exposition digitale',
  'human interaction': 'Interaction humaine',
  'group & interpersonal': 'Groupe & relations interpersonnelles',
  'technology integration': 'Integration technologique',
  'teamwork': "Travail d'equipe",
  'work management': 'Gestion du travail',
  'parallel computing': 'Calcul parallele',
};

/// Renvoie le nom francais d'une competence API 42, ou le nom d'origine
/// s'il n'est pas connu de la table.
String _skillFr(String name) {
  return _skillNameFr[name.trim().toLowerCase()] ?? name.trim();
}

/// Carte Competences : barres sobres a hauteur FIXE (240px), ne bouge
/// jamais quelle que soit la recherche projets. Le top 6 est visible,
/// le reste via 'Tout voir'. Toucher une ligne affiche le niveau exact.
class SkillsRadarChart extends StatefulWidget {
  final List<dynamic> skills;

  const SkillsRadarChart({super.key, required this.skills});

  @override
  State<SkillsRadarChart> createState() => _SkillsRadarChartState();
}

class _SkillsRadarChartState extends State<SkillsRadarChart> {
  bool _showAll = false;
  int _selected = -1;

  List<Map<String, dynamic>> get _parsed {
    final parsed = widget.skills.map((s) {
      final name = _skillFr(s['name'] as String? ?? '');
      final level = (s['level'] as num?)?.toDouble() ?? 0.0;
      return {'name': name, 'level': level};
    }).toList();
    parsed.sort((a, b) => (b['level'] as double).compareTo(a['level'] as double));
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;
    if (parsed.length < 3) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: AppCard.decoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Competences', style: AppText.heading(fontSize: 15)),
            const SizedBox(height: 8),
            Text(
              'Pas assez de donnees pour le moment.',
              style: AppText.body(color: AppColors.muted, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    final visible = _showAll ? parsed : parsed.take(6).toList();
    final maxLevel = parsed.first['level'] as double;
    final scale = (maxLevel <= 0 ? 1.0 : maxLevel).clamp(1.0, 25.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Competences', style: AppText.heading(fontSize: 15)),
              const SizedBox(width: 8),
              Text('${parsed.length}',
                  style: AppText.body(fontSize: 12, color: AppColors.muted)),
              const Spacer(),
              if (parsed.length > 6)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    _showAll = !_showAll;
                    _selected = -1;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _showAll ? 'Reduire' : 'Tout voir',
                      style: AppText.body(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Hauteur FIXE : la carte ne change jamais de taille, la
          // recherche projets au-dessus ne la fait plus bouger.
          SizedBox(
            height: 240,
            child: _showAll
                ? ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: visible.length,
                    itemBuilder: (context, i) => _row(visible[i], i, scale),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < visible.length; i++) _row(visible[i], i, scale),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(Map<String, dynamic> skill, int index, double scale) {
    final String name = skill['name'] as String;
    final double level = skill['level'] as double;
    final selected = _selected == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = selected ? -1 : index),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.darkSoft)),
                ),
                const SizedBox(width: 8),
                Text(level.toStringAsFixed(2),
                    style: AppText.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected ? AppColors.primary : AppColors.muted)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (level / scale).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppColors.cardElevated,
                valueColor: AlwaysStoppedAnimation<Color>(
                    selected ? AppColors.primary : AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
