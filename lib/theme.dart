import 'package:flutter/material.dart';

/// Jetons de mouvement centralisés : toute l'app anime avec la même
/// grammaire (durée + courbe) pour que les transitions paraissent
/// natives et jamais « collées » les unes aux autres.
///
/// Choix : courbes `easeOutCubic` (entrée, réaction immédiate puis
/// amortissement) et `easeInOutCubic` (transitions d'état, aller-retour).
class AppMotion {
  AppMotion._();

  /// Retours d'appui très courts : survol, sélection, toggle.
  static const Duration instant = Duration(milliseconds: 120);

  /// Transition d'état standard : expansion, swap de contenu.
  static const Duration quick = Duration(milliseconds: 220);

  /// Révélation de bloc, entrée/sortie de section.
  static const Duration normal = Duration(milliseconds: 320);

  /// Barre de progression qui se remplit : assez long pour être lisible.
  static const Duration reveal = Duration(milliseconds: 520);

  /// Courbe d'entrée : réponse immédiate, puis amortissement doux.
  static const Curve enter = Curves.easeOutCubic;

  /// Courbe de sortie : départ rapide, disappearance nette.
  static const Curve exit = Curves.easeInCubic;

  /// Courbe d'état : symétrique, pour les aller-retours.
  static const Curve standard = Curves.easeInOutCubic;

  /// Interpolation de valeur scalaire (0 → 1) pour les barres animées.
  static const Curve progress = Curves.easeOutCubic;
}

/// Design system centralisé de l'application.
///
/// Direction : monochrome noir / gris, façon produit natif. Fonds plats
/// façon zinc, texte blanc cassé / gris. Pas de couleur d'accent : les
/// CTA et la data active sont en blanc, les états sémantiques (succès,
/// danger) gardent leur vert / rouge. Pas de dégradés décoratifs, pas de
/// halos, pas de lueurs — tout est mat et lisible.
class AppColors {
  AppColors._();

  /// Accent neutre : blanc cassé. Utilisé avec parcimonie (CTA, liens,
  /// data active, focus). Sur fond sombre, le blanc remplace l'ancien
  /// bleu 42 : même hiérarchie, zéro teinte.
  static const Color primary = Color(0xFFF4F4F5);
  static const Color primaryDark = Color(0xFFA1A1AA);
  static const Color primarySoft = Color(0xFF232329);

  /// Accents secondaires — réservés aux états, jamais décoratifs.
  /// (gardés pour compat : success/danger uniquement utilisés ;
  /// violet/gold neutralisés en gris pour le thème monochrome)
  static const Color mint = Color(0xFFF4F4F5);
  static const Color sky = Color(0xFFF4F4F5);
  static const Color violet = Color(0xFFA3A3A3);
  static const Color gold = Color(0xFFA3A3A3);

  /// Surfaces : vrai noir / gris neutres, plats, sans gradient.
  /// Noir pur en fond pour un contraste maximal façon OLED.
  static const Color background = Color(0xFF000000);
  static const Color backgroundSoft = Color(0xFF0A0A0A);
  static const Color card = Color(0xFF111111);
  static const Color cardElevated = Color(0xFF1A1A1A);
  static const Color headerGradientStart = Color(0xFF111111);
  static const Color headerGradientEnd = Color(0xFF111111);

  /// Texte et neutres : échelle de gris pure, sans teinte bleue.
  static const Color dark = Color(0xFFFFFFFF);
  static const Color darkSoft = Color(0xFFE5E5E5);
  static const Color muted = Color(0xFFA3A3A3);
  static const Color mutedLight = Color(0xFF737373);
  static const Color divider = Color(0xFF262626);
  static const Color hairline = Color(0xFF2E2E2E);

  /// Fond des barres de progression : un cran au-dessus de `card` pour que
  /// la "track" reste lisible sur fond noir (sinon le vide de la barre
  /// disparaît et on ne lit plus que la partie remplie).
  static const Color track = Color(0xFF262626);

  /// États.
  static const Color success = Color(0xFF4ADE80);
  static const Color successSoft = Color(0xFF14241A);
  static const Color danger = Color(0xFFF87171);
  static const Color dangerSoft = Color(0xFF2A1518);

  /// Accent uni : blanc (ex-bleu 42). Conservé comme LinearGradient pour
  /// ne pas casser les appelants, mais les deux stops sont identiques.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Surface hero (ex-dégradé) : rendue plate, gris très sombre.
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111111), Color(0xFF111111)],
  );

  /// Fond login : rendu plat, noir pur.
  static const LinearGradient loginBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF000000), Color(0xFF000000)],
  );

  /// Header de profil : rendu plat.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerGradientStart, headerGradientEnd],
  );

  /// Halos d'ambiance : supprimés — le fond reste uni noir.
  /// (Les anciennes constantes haloTeal/haloBlue/haloViolet, déjà
  /// invisibles, ne sont plus référencées nulle part.)
}

/// Décoration de carte réutilisable : surface mate, bordure fine,
/// ombre portée discrète vers le bas. Coins 12px (sobre, façon natif).
class AppCard {
  AppCard._();

  static BoxDecoration decoration({double radius = 12, Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.hairline, width: 1),
    );
  }

  /// Variante « hero » : identique à la carte standard (fond plat).
  /// Gardée pour ne pas casser les appelants.
  static BoxDecoration hero({double radius = 12}) {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.hairline, width: 1),
    );
  }
}

/// Barre de progression fine et animée, partagée par les compétences et
/// le niveau.
///
/// Différences avec un `LinearProgressIndicator` nu :
/// - le fond ("track") est un cran au-dessus de la carte pour rester
///   visible sur fond sombre (le `cardElevated` d'origine se confondait) ;
/// - le remplissage part de 0 et s'anime à l'entrée, ce qui donne le
///   sentiment que la donnée "se charge" au lieu d'apparaître figée ;
/// - `TweenAnimationBuilder` permet aussi d'animer un *changement* de
///   valeur (filtre, sélection) sans reconstruire la barre.
class AppProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final bool animateOnMount;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.height = 5,
    this.animateOnMount = true,
  });

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        // Track : gris froid un cran plus clair que la surface.
        child: ColoredBox(
          color: AppColors.track,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: animateOnMount ? 0 : clamped,
                end: clamped,
              ),
              duration: AppMotion.reveal,
              curve: AppMotion.progress,
              builder: (context, animated, _) => FractionallySizedBox(
                // Les deux factors sont indispensables : sans heightFactor,
                // le ColoredBox (qui n'a pas d'enfant) se resize à 0 px de
                // haut et la partie remplie devient invisible.
                widthFactor: animated,
                heightFactor: 1,
                child: ColoredBox(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloc qui apparaît en fondu + léger glissement, avec un **retard
/// optionnel** : c'est ce qui permet de cascader les éléments d'une liste
/// (40 ms d'écart par ligne) au lieu de les faire tous sauter en même
/// temps, ce qui donne le rendu « burst » caractéristique des interfaces
/// peu soignées.
///
/// Le widget occupe sa place dans la layout dès le premier frame (le
/// contrôleur démarre à 0 mais le child est déjà monté) : la hauteur de
/// la page ne saute donc jamais pendant que l'animation se joue.
class StaggeredReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Décalage vertical de départ, en fraction de la hauteur du bloc.
  final Offset offset;

  const StaggeredReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.normal,
    this.offset = const Offset(0, 0.08),
  });

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.offset,
    end: Offset.zero,
  ).animate(_opacity);

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }
    // Le futur est annulé implicitement si le widget est disposé avant
    // l'échéance : le garde `mounted` évite tout setState sur un State mort.
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Fond d'ambiance : neutralisé (fond uni). Gardé pour ne pas casser les
/// appelants — ne peint plus aucun halo.
class AppBackground extends StatelessWidget {
  final double opacity;
  const AppBackground({super.key, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Titre de section : simple ligne de titre, sans pastille ni dégradé.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppText.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing!,
              style: AppText.body(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Helpers typographiques : police système pour le texte, pile monospace
/// pour les chiffres, logins et badges (esprit terminal 42).
/// Volontairement sans dépendance réseau (ex-GoogleFonts) : pas de
/// téléchargement de fonte au runtime, rendu identique hors-ligne et
/// sans jank sur le simulateur iOS.
class AppText {
  AppText._();

  static const List<String> _monoFallbacks = [
    'JetBrains Mono',
    'Menlo',
    'Consolas',
    'monospace',
  ];

  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.dark,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'JetBrains Mono',
      fontFamilyFallback: _monoFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.dark,
    double height = 1.4,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontStyle: fontStyle,
    );
  }

  static TextStyle heading({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.dark,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.4,
      height: 1.2,
    );
  }

  static TextStyle display({
    double fontSize = 30,
    FontWeight fontWeight = FontWeight.w800,
    Color color = AppColors.dark,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.8,
      height: 1.1,
    );
  }
}

/// Bouton d'action principal : fond blanc uni, texte noir, coins 10px.
/// Hauteur 48. État désactivé : fond carte surélevée, texte atténué.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.cardElevated,
        foregroundColor: AppColors.background,
        disabledForegroundColor: AppColors.mutedLight,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.muted),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    size: 18,
                    color: enabled
                        ? AppColors.background
                        : AppColors.mutedLight,
                  ),
                if (icon != null) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? AppColors.background
                          : AppColors.mutedLight,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Étiquette statut : pastille teintée + pastille colorée bien visible.
/// Le fond reprend la couleur du statut à 12 % (vert pâle pour « En ligne »)
/// pour que l'état se lise d'un coup d'œil, même sur petit écran.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.dot = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.14);
    final border = color.withValues(alpha: 0.45);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          if (dot) const SizedBox(width: 6),
          Text(
            label,
            style: AppText.body(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thème global de l'application (Material 3, dark premium).
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        surface: AppColors.card,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.dark,
        displayColor: AppColors.dark,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        surface: AppColors.card,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardElevated,
        contentTextStyle: AppText.body(color: AppColors.dark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),
    );
  }
}
