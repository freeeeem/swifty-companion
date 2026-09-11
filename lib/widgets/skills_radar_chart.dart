import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

class SkillsRadarChart extends StatelessWidget {
  final List<dynamic> skills;

  /// Si vrai, le radar remplit la hauteur disponible (mode côte à côte avec
  /// IntrinsicHeight). Sinon, il est dimensionné sur la largeur disponible.
  final bool expand;

  const SkillsRadarChart({super.key, required this.skills, this.expand = false});

  @override
  Widget build(BuildContext context) {
    // 1. Parser et filtrer les compétences
    final List<Map<String, dynamic>> parsedSkills = skills.map((s) {
      final name = s['name'] as String? ?? '';
      final level = (s['level'] as num?)?.toDouble() ?? 0.0;
      return {'name': name, 'level': level};
    }).toList();

    // Trier par niveau décroissant et prendre les 6 principales compétences
    parsedSkills
        .sort((a, b) => (b['level'] as double).compareTo(a['level'] as double));
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Compétences", style: AppText.heading(fontSize: 16)),
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
                      child: CustomPaint(
                        painter: RadarChartPainter(skills: displaySkills),
                      ),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final double chartSide =
                        constraints.maxWidth.clamp(180.0, 260.0);
                    return Center(
                      child: SizedBox(
                        width: chartSide,
                        height: chartSide,
                        child: CustomPaint(
                          painter: RadarChartPainter(skills: displaySkills),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> skills;

  RadarChartPainter({required this.skills});

  // Raccourcir les noms de compétences trop longs pour un affichage propre
  String _shortenName(String name) {
    switch (name.trim()) {
      case "Network & system administration":
        return "Réseau & Sys";
      case "Imperative programming":
        return "Impératif";
      case "Object-oriented programming":
        return "C++ / OOP";
      case "Algorithms & AI":
        return "Algo & IA";
      case "Technology integration":
        return "Intég. Tech";
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
          Offset(center, center), Offset(targetX, targetY), radialPaint);

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}