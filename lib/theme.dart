import 'package:flutter/material.dart';

/// Design system centralisé de l'application — Dark premium « 42 ».
/// Direction : fond encre profonde + halos teal/bleu, cartes verre dépoli,
/// accent menthe → ciel, coins généreux (18px), ombres profondes + lueurs.
class AppColors {
  AppColors._();

  /// Couleur d'accent principale (teal 42, éclaircie pour le fond sombre).
  static const Color primary = Color(0xFF00D1D2);
  static const Color primaryDark = Color(0xFF00BABC);
  static const Color primarySoft = Color(0xFF0E2A2C);

  /// Accents secondaires pour les dégradés premium.
  static const Color mint = Color(0xFF34F5C5);
  static const Color sky = Color(0xFF38BDF8);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color gold = Color(0xFFFBBF24);

  /// Surfaces (du plus sombre au plus élevé).
  static const Color background = Color(0xFF070B14);
  static const Color backgroundSoft = Color(0xFF0B1220);
  static const Color card = Color(0xFF0F172A);
  static const Color cardElevated = Color(0xFF1A2438);
  static const Color headerGradientStart = Color(0xFF1A2B4D);
  static const Color headerGradientEnd = Color(0xFF0E172D);

  /// Texte et neutres.
  static const Color dark = Color(0xFFF1F5F9);
  static const Color darkSoft = Color(0xFFCBD5E1);
  static const Color muted = Color(0xFF8A93A6);
  static const Color mutedLight = Color(0xFF5A6378);
  static const Color divider = Color(0xFF1C2434);
  static const Color hairline = Color(0xFF222B3D);

  /// États.
  static const Color success = Color(0xFF4ADE80);
  static const Color successSoft = Color(0xFF0F2A1C);
  static const Color danger = Color(0xFFF87171);
  static const Color dangerSoft = Color(0xFF2E1517);

  /// Dégradé d'accent utilisé pour les anneaux et touches d'accent.
  /// Menthe → ciel : plus vibrant et moderne que l'ancien teal → teal.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF34F5C5), Color(0xFF00B3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé pour les surfaces hero (header profil, carte niveau).
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16213A), Color(0xFF0F172A)],
  );

  /// Dégradé de fond pour la page de login.
  static const LinearGradient loginBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF060A13),
      Color(0xFF0A1222),
      Color(0xFF0C2B33),
      Color(0xFF10233F),
    ],
  );

  /// Dégradé du header de profil.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerGradientStart, headerGradientEnd],
  );

  /// Halos d'ambiance posés derrière le contenu (opacité très faible).
  static const Color haloTeal = Color(0xFF00D1D2);
  static const Color haloBlue = Color(0xFF2563EB);
  static const Color haloViolet = Color(0xFF8B5CF6);
}

/// Décoration de carte réutilisable : verre dépoli sombre, liseré lumineux
/// en haut, ombre profonde + halo teal subtil. Coins généreux (18px).
class AppCard {
  AppCard._();

  static BoxDecoration decoration({double radius = 18, Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.07),
        width: 1,
      ),
      boxShadow: [
        const BoxShadow(
          color: Color(0x99000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.05),
          blurRadius: 32,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Variante « hero » avec dégradé de surface intégré (header profil,
  /// carte niveau, CTA).
  static BoxDecoration hero({double radius = 20}) {
    return BoxDecoration(
      gradient: AppColors.surfaceGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.09),
        width: 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x99000000),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    );
  }
}

/// Fond d'ambiance : halos teal/bleu/violet flous posés sur le fond encre.
/// À placer en bas d'un Stack, contenu par-dessus.
class AppBackground extends StatelessWidget {
  final double opacity;
  const AppBackground({super.key, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Halo teal haut-droit
          Positioned(
            top: -90,
            right: -70,
            child: Opacity(
              opacity: 0.16 * opacity,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.haloTeal, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          // Halo bleu bas-gauche
          Positioned(
            bottom: -100,
            left: -80,
            child: Opacity(
              opacity: 0.14 * opacity,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.haloBlue, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          // Halo violet centre (très discret, donne la profondeur)
          Positioned(
            top: 260,
            left: -110,
            child: Opacity(
              opacity: 0.08 * opacity,
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.haloViolet, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Titre de section : pastille dégradée + libellé mono espacé + compteur.
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
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 16, color: AppColors.background),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: AppText.mono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
            letterSpacing: 1.6,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                trailing!,
                style: AppText.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.6,
                ),
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

/// Bouton primaire réutilisable : dégradé menthe → ciel, texte encre,
/// lueur d'accent. Hauteur 56, coins 16.
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
    return Container(
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.primaryGradient : null,
        color: enabled ? null : AppColors.cardElevated,
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.muted,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: AppColors.background),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color:
                            enabled ? AppColors.background : AppColors.mutedLight,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Étiquette statut (disponible / en ligne / hors ligne…) : pilule teintée.
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          if (dot) const SizedBox(width: 6),
          Text(
            label,
            style: AppText.mono(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
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