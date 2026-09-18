import 'package:flutter/material.dart';

/// Design system centralisé de l'application.
///
/// Direction : sobre, façon produit natif. Fonds plats façon zinc,
/// un seul accent (bleu 42), texte blanc cassé / gris. Pas de dégradés
/// décoratifs, pas de halos, pas de lueurs — tout est mat et lisible.
class AppColors {
  AppColors._();

  /// Accent unique : bleu 42, légèrement éclairci pour rester lisible
  /// sur fond sombre. Utilisé avec parcimonie (CTA, liens, data active).
  static const Color primary = Color(0xFF2EA8E0);
  static const Color primaryDark = Color(0xFF1F7FB2);
  static const Color primarySoft = Color(0xFF16232C);

  /// Accents secondaires — réservés aux états, jamais décoratifs.
  /// (gardés pour compat : success/danger uniquement utilisés)
  static const Color mint = Color(0xFF2EA8E0);
  static const Color sky = Color(0xFF2EA8E0);
  static const Color violet = Color(0xFF8A93A6);
  static const Color gold = Color(0xFFD9A441);

  /// Surfaces (du plus sombre au plus élevé). Plats, sans gradient.
  static const Color background = Color(0xFF0E0E11);
  static const Color backgroundSoft = Color(0xFF131316);
  static const Color card = Color(0xFF17171C);
  static const Color cardElevated = Color(0xFF1F1F25);
  static const Color headerGradientStart = Color(0xFF1B1B21);
  static const Color headerGradientEnd = Color(0xFF17171C);

  /// Texte et neutres.
  static const Color dark = Color(0xFFF4F4F5);
  static const Color darkSoft = Color(0xFFD4D4D8);
  static const Color muted = Color(0xFFA1A1AA);
  static const Color mutedLight = Color(0xFF71717A);
  static const Color divider = Color(0xFF26262C);
  static const Color hairline = Color(0xFF2A2A31);

  /// États.
  static const Color success = Color(0xFF4ADE80);
  static const Color successSoft = Color(0xFF14241A);
  static const Color danger = Color(0xFFF87171);
  static const Color dangerSoft = Color(0xFF2A1518);

  /// Accent uni (ex-dégradé menthe → ciel) : conservé comme LinearGradient
  /// pour ne pas casser les appelants, mais les deux stops sont identiques.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2EA8E0), Color(0xFF2EA8E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Surface hero (ex-dégradé) : rendue plate.
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF17171C), Color(0xFF17171C)],
  );

  /// Fond login : rendu plat.
  static const LinearGradient loginBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0E0E11),
      Color(0xFF0E0E11),
    ],
  );

  /// Header de profil : rendu plat.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerGradientStart, headerGradientEnd],
  );

  /// Halos d'ambiance : neutralisés (rendus invisibles) — le fond reste
  /// uni. Gardés pour ne pas casser AppBackground, qui les ignore déjà
  /// via opacité 0 par défaut (voir ci-dessous).
  static const Color haloTeal = Color(0x00000000);
  static const Color haloBlue = Color(0x00000000);
  static const Color haloViolet = Color(0x00000000);
}

/// Décoration de carte réutilisable : surface mate, bordure fine,
/// ombre portée discrète vers le bas. Coins 12px (sobre, façon natif).
class AppCard {
  AppCard._();

  static BoxDecoration decoration({double radius = 12, Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.hairline,
        width: 1,
      ),
    );
  }

  /// Variante « hero » : identique à la carte standard (fond plat).
  /// Gardée pour ne pas casser les appelants.
  static BoxDecoration hero({double radius = 12}) {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.hairline,
        width: 1,
      ),
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

/// Bouton d'action principal : fond accent uni, texte blanc, coins 10px.
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
        foregroundColor: Colors.white,
        disabledForegroundColor: AppColors.mutedLight,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
                  Icon(icon, size: 18, color: Colors.white),
                if (icon != null) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.white : AppColors.mutedLight,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Étiquette statut : texte simple avec pastille, sans lueur.
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          if (dot) const SizedBox(width: 6),
          Text(
            label,
            style: AppText.body(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.darkSoft,
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