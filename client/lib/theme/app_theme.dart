import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFE6F7F5);
  static const Color accentNavy = Color(0xFF1E293B);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color bgSlate = Color(0xFFF4F7F9);
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Status Badge Colors (Soft Chips)
  static const Color successBg = Color(0xFFE6F4EA);
  static const Color successText = Color(0xFF137333);

  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFFB45309);

  static const Color dangerBg = Color(0xFFFCE8E6);
  static const Color dangerText = Color(0xFFC5221F);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color warningOrange = Color(0xFFD97706);

  static const Color infoBg = Color(0xFFE0F2FE);
  static const Color infoText = Color(0xFF0369A1);

  static const Color purpleBg = Color(0xFFF3E8FF);
  static const Color purpleText = Color(0xFF6B21A8);
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
