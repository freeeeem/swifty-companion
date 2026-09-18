import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Traduction FR des noms de compétences renvoyés par l'API 42 (en
/// anglais). Recherche par clé normalisée (minuscules) pour être robuste
/// aux variations de casse.
const Map<String, String> _skillNameFr = {
  'algorithms & ai': 'Algorithmique & IA',
  'basic programming': 'Programmation de base',
  'unix': 'Unix',
  'network & system administration': 'Administration réseau & système',
  'imperative programming': 'Programmation impérative',
  'object-oriented programming': 'Programmation orientée objet',
  'graphics': 'Graphisme',
  'web': 'Web',
  'security': 'Sécurité',
  'db & data': 'Bases de données & Data',
  'data science': 'Science des données',
  'functional programming': 'Programmation fonctionnelle',
  'rigor': 'Rigueur',
  'organization': 'Organisation',
  'adaptation & creativity': 'Adaptation & créativité',
  'adaptability & group work': 'Adaptabilité & travail de groupe',
  'company experience': 'Expérience en entreprise',
  'digital exposure': 'Exposition digitale',
  'human interaction': 'Interaction humaine',
  'group & interpersonal': 'Groupe & relations interpersonnelles',
  'technology integration': 'Intégration technologique',
  'teamwork': "Travail d'équipe",
  'work management': 'Gestion du travail',
  'parallel computing': 'Calcul parallèle',
};

/// Renvoie le nom français d'une compétence API 42, ou le nom d'origine
/// s'il n'est pas connu de la table (les compétences non couvertes
/// s'affichent alors telles quelles).
String _skillFr(String name) {
  return _skillNameFr[name.trim().toLowerCase()] ?? name.trim();
}

class SkillsRadarChart extends StatelessWidget {
  final List<dynamic> skills;

  /// Si vrai, le radar remplit la hauteur disponible (mode côte à côte avec
  /// IntrinsicHeight). Sinon, il est dimensionné sur la largeur disponible.
  final bool expand;

  const SkillsRadarChart({
    super.key,
    required this.skills,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Parser et filtrer les compétences
    final List<Map<String, dynamic>> parsedSkills = skills.map((s) {
      final name = _skillFr(s['name'] as String? ?? '');
      final level = (s['level'] as num?)?.toDouble() ?? 0.0;
      return {'name': name, 'level': level};
    }).toList();

    // Trier par niveau décroissant et prendre les 6 principales compétences
    parsedSkills.sort(
      (a, b) => (b['level'] as double).compareTo(a['level'] as double),
    );
    final displaySkills = parsedSkills.take(6).toList();

    // Si on a moins de 3 compétences, un radar chart n'est pas très lisible
    if (displaySkills.length < 3) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: AppCard.decoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Compétences", style: AppText.heading(fontSize: 16)),
            const SizedBox(height: 12),
            Text(
              "Pas assez de données pour afficher l'arbre.",
              style: AppText.body(
                color: AppColors.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // Clic sur la carte -> détail de toutes les compétences.
        onTap: () => _showAllSkillsSheet(context, parsedSkills),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppCard.decoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Compétences", style: AppText.heading(fontSize: 16)),
                  const Spacer(),
                  // Indice visuel : la carte est cliquable.
                  Text(
                    'TOUS',
                    style: AppText.mono(
                      fontSize: 9.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'TOP ${displaySkills.length}',
                style: AppText.mono(
                  fontSize: 10,
                  color: AppColors.mutedLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              expand
                  ? Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _InteractiveRadar(skills: displaySkills),
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final double chartSide = constraints.maxWidth.clamp(
                          180.0,
                          260.0,
                        );
                        return Center(
                          child: SizedBox(
                            width: chartSide,
                            height: chartSide,
                            child: _InteractiveRadar(skills: displaySkills),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet listant toutes les compétences (pas seulement le TOP 6
  /// du radar), triées par niveau décroissant.
  void _showAllSkillsSheet(
    BuildContext context,
    List<Map<String, dynamic>> skills,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.hairline),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mutedLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Compétences', style: AppText.heading(fontSize: 17)),
                      const Spacer(),
                      Text(
                        '${skills.length} TOTAL',
                        style: AppText.mono(
                          fontSize: 10,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    itemCount: skills.length,
                    itemBuilder: (context, index) {
                      final skill = skills[index];
                      final String name = skill['name'] as String;
                      final double level = skill['level'] as double;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  level.toStringAsFixed(2),
                                  style: AppText.mono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: (level / 21).clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: AppColors.divider,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> skills;

  /// Index de la compétence survolée (-1 = aucune). Dessine un tooltip
  /// nom + niveau près du sommet correspondant.
  final int hoverIndex;

  RadarChartPainter({required this.skills, this.hoverIndex = -1});

  // Raccourcir les noms de compétences trop longs pour un affichage propre
  String _shortenName(String name) {
    switch (name.trim()) {
      case "Administration réseau & système":
        return "Réseau & Sys";
      case "Programmation impérative":
        return "Impératif";
      case "Programmation orientée objet":
        return "POO";
      case "Algorithmique & IA":
        return "Algo & IA";
      case "Intégration technologique":
        return "Intég. Tech";
      case "Programmation fonctionnelle":
        return "Fonctionnel";
      case "Bases de données & Data":
        return "BDD & Data";
      case "Adaptabilité & travail de groupe":
        return "Adapt. & Groupe";
      case "Expérience en entreprise":
        return "Entreprise";
      case "Group & relations interpersonnelles":
        return "Groupe";
      case "Gestion du travail":
        return "Gestion";
      case "Unix":
        return "Unix";
      default:
        // Tronquer si vraiment trop long
        if (name.length > 15) {
          return "${name.substring(0, 12)}...";
        }
        return name;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final int count = skills.length;
    final double center = size.width / 2;
    final double maxRadius = (size.width / 2) - 40; // Marge pour le texte
    final double angleStep = (2 * pi) / count;

    // Calculer le niveau max pour l'échelle (au moins 20.0)
    double maxVal = 20.0;
    for (var s in skills) {
      if (s['level'] > maxVal) {
        maxVal = s['level'] as double;
      }
    }

    final Paint gridPaint = Paint()
      ..color = AppColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint radialPaint = Paint()
      ..color = AppColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint dataFillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final Paint dataOutlinePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    // 1. Grille concentrique (4 niveaux)
    for (int step = 1; step <= 4; step++) {
      final double r = maxRadius * (step / 4);
      final Path gridPath = Path();

      for (int i = 0; i < count; i++) {
        final double angle = i * angleStep - pi / 2; // Commencer en haut
        final double x = center + r * cos(angle);
        final double y = center + r * sin(angle);

        if (i == 0) {
          gridPath.moveTo(x, y);
        } else {
          gridPath.lineTo(x, y);
        }
      }
      gridPath.close();
      canvas.drawPath(gridPath, gridPaint);
    }

    // 2. Axes radiaux et labels
    for (int i = 0; i < count; i++) {
      final double angle = i * angleStep - pi / 2;

      final double targetX = center + maxRadius * cos(angle);
      final double targetY = center + maxRadius * sin(angle);
      canvas.drawLine(
        Offset(center, center),
        Offset(targetX, targetY),
        radialPaint,
      );

      final String name = _shortenName(skills[i]['name'] as String);
      final double levelVal = skills[i]['level'] as double;

      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$name\n",
              style: AppText.body(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
                height: 1.25,
              ),
            ),
            TextSpan(
              text: levelVal.toStringAsFixed(1),
              style: AppText.mono(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
                height: 1.25,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final double textDist = maxRadius + 14;
      final double labelX = center + textDist * cos(angle);
      final double labelY = center + textDist * sin(angle);

      double xOffset = 0;
      double yOffset = 0;
      final double cosVal = cos(angle);
      final double sinVal = sin(angle);

      if (cosVal > 0.1) {
        xOffset = 0;
      } else if (cosVal < -0.1) {
        xOffset = -textPainter.width;
      } else {
        xOffset = -textPainter.width / 2;
      }

      if (sinVal > 0.1) {
        yOffset = 0;
      } else if (sinVal < -0.1) {
        yOffset = -textPainter.height;
      } else {
        yOffset = -textPainter.height / 2;
      }

      textPainter.paint(canvas, Offset(labelX + xOffset, labelY + yOffset));
    }

    // 3. Zone de données de l'utilisateur
    final Path dataPath = Path();
    for (int i = 0; i < count; i++) {
      final double angle = i * angleStep - pi / 2;
      final double level = skills[i]['level'] as double;
      final double r = maxRadius * (level / maxVal);
      final double x = center + r * cos(angle);
      final double y = center + r * sin(angle);

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, dataFillPaint);
    canvas.drawPath(dataPath, dataOutlinePaint);

    // Points sur les sommets
    final Paint pointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final Paint pointBorderPaint = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < count; i++) {
      final double angle = i * angleStep - pi / 2;
      final double level = skills[i]['level'] as double;
      final double r = maxRadius * (level / maxVal);
      final double x = center + r * cos(angle);
      final double y = center + r * sin(angle);
      canvas.drawCircle(Offset(x, y), 3.0, pointPaint);
      canvas.drawCircle(Offset(x, y), 3.0, pointBorderPaint);
    }

    // Tooltip au survol : point agrandi + bulle nom / niveau.
    if (hoverIndex >= 0 && hoverIndex < count) {
      final int i = hoverIndex;
      final double angle = i * angleStep - pi / 2;
      final double level = skills[i]['level'] as double;
      final double r = maxRadius * (level / maxVal);
      final double x = center + r * cos(angle);
      final double y = center + r * sin(angle);

      canvas.drawCircle(Offset(x, y), 5.5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5.5, pointBorderPaint);

      final tooltipPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: "${_shortenName(skills[i]['name'] as String)}\n",
              style: AppText.body(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
                height: 1.3,
              ),
            ),
            TextSpan(
              text: level.toStringAsFixed(2),
              style: AppText.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 150);

      const double pad = 8;
      final double w = tooltipPainter.width + pad * 2;
      final double h = tooltipPainter.height + pad * 1.5;
      double left = (x - w / 2).clamp(2.0, size.width - w - 2);
      double top = y - h - 14;
      if (top < 2) top = y + 14;

      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w, h),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, Paint()..color = AppColors.cardElevated);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      tooltipPainter.paint(canvas, Offset(left + pad, top + pad * 0.75));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Enveloppe interactive du radar : détecte le survol (souris) ou le tap
/// (tactile) sur les sommets et transmet l'index au painter pour afficher
/// le tooltip nom / niveau.
class _InteractiveRadar extends StatefulWidget {
  final List<Map<String, dynamic>> skills;

  const _InteractiveRadar({required this.skills});

  @override
  State<_InteractiveRadar> createState() => _InteractiveRadarState();
}

class _InteractiveRadarState extends State<_InteractiveRadar> {
  int _hoverIndex = -1;

  /// Retrouve le sommet le plus proche de la position locale, avec la
  /// même géométrie que [RadarChartPainter] (seuil de tolérance ~22 px).
  int? _hitTest(Offset local) {
    final Size? size = context.size;
    if (size == null || widget.skills.isEmpty) return null;

    final double side = size.shortestSide;
    final int count = widget.skills.length;
    final double center = side / 2;
    final double maxRadius = (side / 2) - 40;
    final double angleStep = (2 * pi) / count;

    double maxVal = 20.0;
    for (var s in widget.skills) {
      final double level = s['level'] as double;
      if (level > maxVal) maxVal = level;
    }

    int? best;
    double bestDist = 22;
    for (int i = 0; i < count; i++) {
      final double level = widget.skills[i]['level'] as double;
      final double r = maxRadius * (level / maxVal);
      final double angle = i * angleStep - pi / 2;
      final Offset point = Offset(
        center + r * cos(angle),
        center + r * sin(angle),
      );
      final double dist = (local - point).distance;
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
  }

  void _updateHover(Offset local) {
    setState(() => _hoverIndex = _hitTest(local) ?? -1);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onHover: (event) => _updateHover(event.localPosition),
      onExit: (_) => setState(() => _hoverIndex = -1),
      child: GestureDetector(
        // Support tactile : un tap sur un sommet affiche le tooltip,
        // un tap ailleurs sur le radar le referme.
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _updateHover(details.localPosition),
        child: CustomPaint(
          painter: RadarChartPainter(
            skills: widget.skills,
            hoverIndex: _hoverIndex,
          ),
        ),
      ),
    );
  }
}
