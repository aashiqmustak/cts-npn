import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ======================================================================
/// "Vivara Health" palette — a complete departure from the teal system.
/// Field NAMES are preserved so existing screens that reference
/// AppColors.primaryTeal / textDark / borderLight / etc. keep compiling —
/// only the VALUES change, to a premium magenta → purple → warm-orange
/// healthcare identity. New semantic constants are appended at the end
/// for the auth screen's illustration and gradients.
/// ======================================================================
class AppColors {
  // Primary identity — vivid magenta replaces teal as the brand accent.
  static const Color primaryTeal = Color(0xFFE31C7A); // hot magenta (primary)
  static const Color primaryDark = Color(0xFFB0135F); // deep magenta
  static const Color primaryLight = Color(0xFFFDE8F3); // soft pink tint

  static const Color accentNavy = Color(0xFF2A1B4D); // deep plum-indigo
  static const Color textDark = Color(0xFF1B1229); // near-black plum ink
  static const Color textMuted = Color(0xFF7C7390); // muted mauve-gray

  static const Color bgSlate = Color(0xFFFAF6FB); // soft lavender-white canvas
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFF0E4EE); // soft pink-gray border

  // Status Badge Colors (Soft Chips) — kept semantically standard
  static const Color successBg = Color(0xFFE5F7EC);
  static const Color successText = Color(0xFF158A4B);

  static const Color warningBg = Color(0xFFFFF2DF);
  static const Color warningText = Color(0xFFB35A00);

  static const Color dangerBg = Color(0xFFFCE7EE);
  static const Color dangerText = Color(0xFFC4184F);
  static const Color dangerRed = Color(0xFFE22C5B);
  static const Color successGreen = Color(0xFF1DA35E);
  static const Color warningOrange = Color(0xFFE07A1F);

  static const Color infoBg = Color(0xFFEFE7FD);
  static const Color infoText = Color(0xFF6B21C7);

  static const Color purpleBg = Color(0xFFF1E7FD);
  static const Color purpleText = Color(0xFF6B21C7);

  // --------------------------------------------------------------
  // New accents for the "Vivara" identity — gradients & illustration
  // --------------------------------------------------------------
  static const Color accentMagenta = Color(0xFFFF3D9A);
  static const Color accentPurple = Color(0xFF8B2FD6);
  static const Color accentOrange = Color(0xFFFF8A3D);
  static const Color inkDeep = Color(0xFF150C29);

  static const List<Color> gradientBrand = [
    Color(0xFF1A0F33), // deep plum-black
    Color(0xFF3B1466), // rich violet
    Color(0xFFB0135F), // deep magenta
  ];

  static const List<Color> gradientCanvas = [
    Color(0xFFFF3D9A),
    Color(0xFF9B2FD6),
    Color(0xFFFF8A3D),
  ];

  static const List<Color> gradientPill = [
    Color(0xFFE31C7A),
    Color(0xFFB0135F),
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryTeal,
      scaffoldBackgroundColor: AppColors.bgSlate,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryTeal,
        primary: AppColors.primaryTeal,
        secondary: AppColors.accentNavy,
        surface: AppColors.cardBg,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      cardTheme: const CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
          side: BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryTeal,
          side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSlate,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide:
              const BorderSide(color: AppColors.primaryTeal, width: 1.5),
        ),
      ),
    );
  }
}