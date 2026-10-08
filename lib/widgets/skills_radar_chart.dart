import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import '../theme.dart';

/// Traduction FR des noms de competences renvoyes par l'API 42 (en
/// anglais). Recherche par cle normalisee (minuscules) pour etre robuste
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
  'db & data': 'Bases de données & data',
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

/// Renvoie le nom francais d'une competence API 42, ou le nom d'origine
/// s'il n'est pas connu de la table.
String _skillFr(String name) {
  return _skillNameFr[name.trim().toLowerCase()] ?? name.trim();
}

/// Carte Competences : barres a hauteur NATURElle, animees a l'entree.
///
/// Le top 6 est visible, le reste via 'Tout voir' qui deploye la carte en
/// `AnimatedSize` (plus de `SizedBox` fige, plus de `ListView` imbrique
/// dans le scroll de la page : le geste ne se fait plus voler). Toucher
/// une ligne met en avant la competence et affiche son niveau exact.
class SkillsRadarChart extends StatefulWidget {
  final List<dynamic> skills;

  const SkillsRadarChart({super.key, required this.skills});

  @override
  State<SkillsRadarChart> createState() => _SkillsRadarChartState();
}

/// Pastille d'action compacte : le contrôle de dépliage de la carte des
/// compétences (« Voir les N autres » / « Réduire »).
///
/// Une seule instanciation vit dans la carte (en bas de la légende), mais
/// le composant reste factorisé hors du parent pour une raison précise :
/// son état d'appui lui appartient. Le parent n'a pas à savoir si le doigt
/// est posé sur la pastille, et l'animation ne peut pas être reconstruite
/// par un `setState` du parent qui reconstruirait tout l'arbre de la carte
/// (et relancerait au passage les animations d'entrée des lignes).
///
/// Au repos la pastille est plate (fond transparent, bordure `hairline`
/// d'un pixel) : elle s'efface dans la carte au lieu d'ajouter une zone
/// clignotante en permanence. C'est l'appui qui l'allume.
class _CardChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  /// Oriente le chevron : vers le bas quand la liste est repliée (à
  /// ouvrir), vers le haut quand elle est dépliée (à refermer).
  final bool expanded;

  const _CardChip({
    required this.label,
    required this.onTap,
    this.expanded = false,
  });

  @override
  State<_CardChip> createState() => _CardChipState();
}

class _CardChipState extends State<_CardChip> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          _setPressed(false);
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: AppMotion.instant,
          curve: AppMotion.standard,
          // Hauteur tactile ~32 px (21 px avant : trop petit au doigt).
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: _pressed ? AppColors.primary : AppColors.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: widget.expanded ? 0.5 : 0,
                duration: AppMotion.quick,
                curve: AppMotion.standard,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                widget.label,
                style: AppText.body(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compétence normalisée (nom FR + niveau), telle qu'affichée par la
/// carte. Remplace les `Map<String, dynamic>` bruts : un
/// `s['level'] as double` est fragile (l'API renvoie un `num`, qui peut
/// être un `int`) et rend le code illisible.
class _Skill {
  final String name;
  final double level;

  const _Skill(this.name, this.level);
}

/// Radar des compétences : hexagone (ou polygone à N sommets) tracé au
/// `CustomPainter`.
///
/// Choix visuels, dans la continuité du thème (mat, sans lueur ni
/// dégradé décoratif) :
/// - grille en 2 anneaux + axes, couleur `hairline` : présente la
///   structure sans jamais concurrencer la donnée ;
/// - surface remplie en `primary` à 14% d'opacité, trait de contour plein :
///   la forme se lit d'un coup d'œil sans halo ;
/// - les sommets sont des points pleins, le sommet mis en avant grossit.
class _RadarPainter extends CustomPainter {
  /// Valeurs normalisées 0 → 1, dans l'ordre des axes.
  final List<double> values;

  /// Index du sommet mis en avant, ou -1.
  final int highlight;

  /// Progression 0 → 1 de l'entrée en matière.
  final double progress;

  const _RadarPainter({
    required this.values,
    required this.highlight,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int n = values.length;
    if (n < 3) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    // Marge pour que le point le plus proche du bord ne soit pas coupé.
    final double radius = (size.shortestSide / 2) - 10;

    // Grille : deux anneaux concentriques, pas un anneau par valeur
    // (au-delà de deux, les lignes se croisent et font du bruit visuel).
    final Paint grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.hairline;

    for (final double ring in const [0.5, 1.0]) {
      final Path ringPath = Path();
      for (int i = 0; i < n; i++) {
        final Offset p = _point(i, ring, center, radius);
        i == 0 ? ringPath.moveTo(p.dx, p.dy) : ringPath.lineTo(p.dx, p.dy);
      }
      ringPath.close();
      canvas.drawPath(ringPath, grid);
    }

    // Axes : très discrets, on devine la structure sans la voir.
    final Paint axis = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.divider;
    for (int i = 0; i < n; i++) {
      canvas.drawLine(center, _point(i, 1, center, radius), axis);
    }

    // Figure : le rayon de chaque sommet est animé par `progress`, ce qui
    // donne la « mise en place » du graphique au chargement.
    final Path figure = Path();
    for (int i = 0; i < n; i++) {
      final double v = (values[i] * progress).clamp(0.0, 1.0);
      final Offset p = _point(i, v, center, radius);
      i == 0 ? figure.moveTo(p.dx, p.dy) : figure.lineTo(p.dx, p.dy);
    }
    figure.close();

    canvas.drawPath(
      figure,
      Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.primary.withValues(alpha: 0.14),
    );
    canvas.drawPath(
      figure,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.primary,
    );

    // Sommets : le mis en avant est plus gros, sinon c'est un point plein
    // de la couleur de la figure (donc invisible sur le remplissage).
    for (int i = 0; i < n; i++) {
      final double v = (values[i] * progress).clamp(0.0, 1.0);
      final Offset p = _point(i, v, center, radius);
      final bool on = i == highlight;
      if (on) {
        // Anneau de sélection : mat (pas de lueur), juste un disque large
        // qui lève le sommet du fond.
        canvas.drawCircle(
          p,
          6,
          Paint()..color = AppColors.primary.withValues(alpha: 0.22),
        );
      }
      canvas.drawCircle(
        p,
        on ? 3.4 : 2.4,
        Paint()..color = on ? AppColors.primary : AppColors.card,
      );
      if (on) {
        canvas.drawCircle(
          p,
          3.4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = AppColors.primary,
        );
      }
    }
  }

  /// Position du sommet [i] à la fraction [fraction] du rayon max.
  /// L'angle de départ est -90° (haut) et le pas est 360/n, donc le
  /// premier sommet est en haut et on tourne dans le sens horaire.
  Offset _point(int i, double fraction, Offset center, double radius) {
    final double angle = -math.pi / 2 + i * 2 * math.pi / values.length;
    return Offset(
      center.dx + math.cos(angle) * radius * fraction,
      center.dy + math.sin(angle) * radius * fraction,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.highlight != highlight ||
      old.progress != progress ||
      !listEquals(old.values, values);
}

class _SkillsRadarChartState extends State<SkillsRadarChart> {
  bool _showAll = false;

  /// Index de la compétence mise en avant (toucher la légende), ou -1.
  /// Sert à relier les deux moitiés de la carte : la ligne survolée
  /// éclaire le sommet correspondant du radar.
  int _selected = -1;

  /// Nombre de lignes visibles repliées. Au-delà, la carte propose
  /// « Tout voir » : on évite d'afficher 25 lignes d'un coup.
  static const int _collapsedCount = 6;

  /// Nombre de sommets du radar. Au-delà de 6 axes, la figure devient
  /// illisible sur un écran de téléphone : le radar ne montre donc que
  /// les [radarCount] premières compétences, la liste reste complète.
  static const int radarCount = 6;

  /// Échelle de référence des barres et du radar.
  ///
  /// Volontairement **absolue** et non relative au maximum : avec une
  /// échelle relative, la meilleure compétence est toujours à 100% et le
  /// graphique ne dit rien du niveau réel. `10` est le plancher, pour
  /// qu'un débutant voie ses 3/10 au lieu de barres quasi pleines. Le
  /// plafond de 21 correspond à l'échelle 42.
  double get _scale {
    final double max = _parsed.first.level;
    return max < 10 ? 10 : (max > 21 ? 21 : max);
  }

  List<_Skill> get _parsed {
    final parsed = <_Skill>[];
    for (final dynamic raw in widget.skills) {
      if (raw is! Map) continue;
      final String name = _skillFr(raw['name'] as String? ?? '');
      if (name.isEmpty) continue;
      parsed.add(_Skill(name, (raw['level'] as num?)?.toDouble() ?? 0.0));
    }
    parsed.sort((a, b) => b.level.compareTo(a.level));
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
            Text('Compétences', style: AppText.heading(fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.insights_rounded,
                  size: 16,
                  color: AppColors.mutedLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pas assez de données pour le moment.',
                    style: AppText.body(fontSize: 13, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final total = parsed.length;
    final scale = _scale;
    final visible = _showAll ? parsed : parsed.take(_collapsedCount).toList();
    // Le radar ne montre que les premières compétences ; la légende, elle,
    // suit la liste visible pour que les deux restent cohérents.
    final radar = parsed.take(radarCount).toList();
    final radarValues = radar
        .map((s) => (s.level / scale).clamp(0.0, 1.0))
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(total),
          const SizedBox(height: 14),
          // Point focal de la carte : la figure donne l'équilibre d'un
          // coup d'œil, la légende donne les chiffres exacts.
          Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: AppMotion.reveal,
                curve: AppMotion.progress,
                builder: (context, progress, _) => CustomPaint(
                  painter: _RadarPainter(
                    values: radarValues,
                    highlight: _selected,
                    progress: progress,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Légende : une ligne par compétence, nom / barre / valeur sur
          // une seule ligne. Bien plus compact et lisible que l'ancien
          // empilement nom-au-dessus, barre-en-dessous.
          AnimatedSize(
            duration: AppMotion.quick,
            curve: AppMotion.standard,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < visible.length; i++)
                  Padding(
                    // 2 px suffisent : la pastille et la barre fines
                    // supportent des lignes serrées sans se toucher.
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
                    child: StaggeredReveal(
                      key: ValueKey('skill-${visible[i].name}'),
                      delay: Duration(milliseconds: 40 + i * 35),
                      offset: const Offset(0.04, 0),
                      child: _row(visible[i], i, scale),
                    ),
                  ),
                if (total > _collapsedCount) _hiddenToggle(total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bascule de dépliage, en bas de liste : « Voir les N autres » quand la
  /// liste est repliée, « Réduire » quand elle est dépliée.
  ///
  /// C'est le **seul** contrôle de la carte : il tient donc les deux états.
  /// La pastille de l'en-tête qui faisait la moitié du travail a été
  /// retirée — un seul point d'entrée, et il est là où l'œil arrive en
  /// fin de liste, pas en haut à l'autre bout de la carte.
  ///
  /// Elle reste affichée une fois dépliée : sans elle, impossible de
  /// replier, la carte resterait définitivement agrandie.
  Widget _hiddenToggle(int total) {
    final int hidden = total - _collapsedCount;
    final bool expanded = _showAll;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _CardChip(
          label: expanded
              ? 'Réduire'
              : 'Voir les $hidden autre${hidden > 1 ? 's' : ''}',
          // Le chevron pointe vers le haut quand la liste est dépliée :
          // le sens du geste est lisible sans lire le libellé.
          expanded: expanded,
          onTap: () => setState(() {
            _showAll = !_showAll;
            _selected = -1;
          }),
        ),
      ),
    );
  }

  /// En-tête : titre, effectif et moyenne.
  ///
  /// La moyenne a été ajoutée parce que le radar seul ne dit pas si le
  /// profil est fort : c'est le seul chiffre qui donne le niveau global.
  Widget _header(int total) {
    final double avg = _parsed.fold<double>(0, (a, s) => a + s.level) / total;
    return Row(
      children: [
        // Le titre est le seul élément élastique : sur un écran étroit ou
        // avec une police large, ce sont les libellés de droite qui
        // doivent ceder, pas le titre qui déborde.
        Expanded(
          child: Text(
            'Compétences',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.heading(fontSize: 15),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$total',
          style: AppText.body(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(width: 10),
        // `scaleDown` : la moyenne disparaît proprement sur écran étroit
        // au lieu de pousser le reste hors du cadre.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'moy. ${avg.toStringAsFixed(1)}',
            style: AppText.mono(fontSize: 11, color: AppColors.mutedLight),
          ),
        ),
      ],
    );
  }

  /// Une ligne de légende : `nom · barre fine · valeur`, tout sur une
  /// seule ligne.
  ///
  /// L'ancien rendu empilait le nom puis la barre en dessous : deux
  /// lignes par compétence, donc une carte deux fois plus haute et un
  /// oeil qui devait sauter d'une ligne à l'autre pour lire le couple
  /// nom/valeur. Sur une seule ligne, la comparaison est immédiate et la
  /// carte reste compacte.
  Widget _row(_Skill skill, int index, double scale) {
    final selected = _selected == index;
    // Seul le top du radar porte un sommet : au-delà, l'index ne
    // correspondrait à aucun axe et le lien légende ↔ figure mentirait.
    final bool onRadar = index < radarCount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = selected ? -1 : index),
      child: Container(
        // Fond qui s'allume à la sélection : donne un retour immédiat sans
        // changer la hauteur (donc pas de saut de mise en page).
        // Hauteur tactile ~38 px : à 5 px verticaux les lignes sont trop
        // fines pour être tapées au doigt sur mobile.
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Pastille de liaison avec le radar : même couleur que la
            // figure, elle indique à quel sommet correspond la ligne.
            //
            // La sélection l'emporte toujours sur le gris : sans cela, une
            // compétence hors radar (donc sans sommet) gardait une pastille
            // grise alors que le reste de la ligne s'illuminait, et le tap
            // semblait ne rien faire.
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.primary
                    : (onRadar ? AppColors.primaryDark : AppColors.mutedLight),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                skill.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.dark : AppColors.darkSoft,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Barre contrainte en largeur : les barres restent alignées
            // en colonne, ce qui rend la comparaison visuelle immédiate.
            SizedBox(
              width: 68,
              child: AppProgressBar(
                value: (skill.level / scale).clamp(0.0, 1.0),
                color: selected ? AppColors.primary : AppColors.primaryDark,
                height: 4,
              ),
            ),
            const SizedBox(width: 10),
            // `scaleDown` plutôt qu'une largeur fixe rigide : les décimales
            // ne font pas danser la colonne, et une valeur atypiquement
            // longue rétrécit au lieu de déborder.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 30,
                child: Text(
                  skill.level.toStringAsFixed(1),
                  textAlign: TextAlign.right,
                  style: AppText.mono(
                    fontSize: 11.5,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
