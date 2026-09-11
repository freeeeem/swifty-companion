import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system centralisé de l'application — Dark premium.
class AppColors {
  AppColors._();

  /// Couleur d'accent principale (teal 42, éclaircie pour le fond sombre).
  static const Color primary = Color(0xFF00D1D2);
  static const Color primaryDark = Color(0xFF00BABC);
  static const Color primarySoft = Color(0xFF0E2A2C);

  /// Surfaces (du plus sombre au plus élevé).
  static const Color background = Color(0xFF0A0E17);
  static const Color card = Color(0xFF111726);
  static const Color cardElevated = Color(0xFF182033);
  static const Color headerGradientStart = Color(0xFF152035);
  static const Color headerGradientEnd = Color(0xFF101726);

  /// Texte et neutres.
  static const Color dark = Color(0xFFE8ECF4);
  static const Color darkSoft = Color(0xFFB9C1D0);
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
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E0E1), Color(0xFF00A8A9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé de fond pour la page de login.
  static const LinearGradient loginBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF070B12),
      Color(0xFF0A0E17),
      Color(0xFF0D2324),
    ],
  );

  /// Dégradé du header de profil.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerGradientStart, headerGradientEnd],
  );
}

/// Décoration de carte réutilisable : surface sombre, liseré fin, ombre profonde.
class AppCard {
  AppCard._();

  static BoxDecoration decoration({double radius = 14, Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.hairline, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

/// Helpers typographiques : Roboto pour le texte, JetBrains Mono pour
/// les chiffres, logins et badges (esprit terminal 42).
class AppText {
  AppText._();

  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.dark,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.jetBrainsMono(
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
    return GoogleFonts.roboto(
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
    return GoogleFonts.roboto(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.2,
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
      textTheme: GoogleFonts.robotoTextTheme(base.textTheme).apply(
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