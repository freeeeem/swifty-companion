import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SkillsRadarChart extends StatelessWidget {
  final List<dynamic> skills;

  const SkillsRadarChart({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    // 1. Parser et filtrer les compétences
    final List<Map<String, dynamic>> parsedSkills = skills.map((s) {
      final name = s['name'] as String? ?? '';
      final level = (s['level'] as num?)?.toDouble() ?? 0.0;
      return {'name': name, 'level': level};
    }).toList();

    // Trier par niveau décroissant et prendre les 6 principales compétences
    parsedSkills.sort((a, b) => (b['level'] as double).compareTo(a['level'] as double));
    final displaySkills = parsedSkills.take(6).toList();

    // Si on a moins de 3 compétences, un radar chart n'est pas très lisible
    if (displaySkills.length < 3) {
      return Container(
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
            Text(
              "Compétences",
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Pas assez de données pour afficher l'arbre.",
              style: GoogleFonts.roboto(
                color: const Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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
          Text(
            "Compétences principales",
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: CustomPaint(
                painter: RadarChartPainter(skills: displaySkills),
              ),
            ),
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
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint radialPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint dataFillPaint = Paint()
      ..color = const Color(0xFF00BABC).withValues(alpha: 0.20) // Couleur 42 avec transparence
      ..style = PaintingStyle.fill;

    final Paint dataOutlinePaint = Paint()
      ..color = const Color(0xFF00BABC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 1. Dessiner la grille concentrique (4 niveaux de cercles/polygones : 25%, 50%, 75%, 100%)
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

    // 2. Dessiner les axes radiaux et le texte
    for (int i = 0; i < count; i++) {
      final double angle = i * angleStep - pi / 2;
      
      // Ligne radiale
      final double targetX = center + maxRadius * cos(angle);
      final double targetY = center + maxRadius * sin(angle);
      canvas.drawLine(Offset(center, center), Offset(targetX, targetY), radialPaint);

      // Texte de la compétence
      final String name = _shortenName(skills[i]['name'] as String);
      final double levelVal = skills[i]['level'] as double;
      final String text = "$name\n(${levelVal.toStringAsFixed(1)})";

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.roboto(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
            height: 1.2,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Décalage pour ne pas chevaucher le graphique
      final double textDist = maxRadius + 14;
      final double labelX = center + textDist * cos(angle);
      final double labelY = center + textDist * sin(angle);

      // Ajustement de l'alignement selon le quadrant
      double xOffset = 0;
      double yOffset = 0;
      final double cosVal = cos(angle);
      final double sinVal = sin(angle);

      if (cosVal > 0.1) {
        xOffset = 0; // à droite de l'axe
      } else if (cosVal < -0.1) {
        xOffset = -textPainter.width; // à gauche de l'axe
      } else {
        xOffset = -textPainter.width / 2; // centré
      }

      if (sinVal > 0.1) {
        yOffset = 0; // en bas
      } else if (sinVal < -0.1) {
        yOffset = -textPainter.height; // en haut
      } else {
        yOffset = -textPainter.height / 2; // centré
      }

      textPainter.paint(canvas, Offset(labelX + xOffset, labelY + yOffset));
    }

    // 3. Dessiner la zone des données de l'utilisateur
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

    // Dessiner de petits points sur les sommets du graphe de l'utilisateur
    final Paint pointPaint = Paint()
      ..color = const Color(0xFF00BABC)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < count; i++) {
      final double angle = i * angleStep - pi / 2;
      final double level = skills[i]['level'] as double;
      final double r = maxRadius * (level / maxVal);
      final double x = center + r * cos(angle);
      final double y = center + r * sin(angle);
      canvas.drawCircle(Offset(x, y), 3.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
