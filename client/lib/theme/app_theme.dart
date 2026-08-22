import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Royal Sapphire Healthcare Tech Palette (Base: #1244A2)
  static const Color primaryTeal = Color(0xFF1244A2); // Royal Sapphire Blue #1244A2
  static const Color primaryDark = Color(0xFF0C2D6F); // Deep Oceanic Navy
  static const Color primaryLight = Color(0xFFEBF2FF); // Soft Blue Tint
  static const Color electricMint = Color(0xFF00D2FF); // Vibrant Electric Cyan Active Accent
  static const Color accentNavy = Color(0xFF0B192C); // Deep Midnight Blue
  static const Color accentMint = Color(0xFF2563EB); // Bright Sapphire Glow

  // Canvas & Surface Backgrounds
  static const Color bgSlate = Color(0xFFF4F7FC); // Soft Ice-Blue Gray Canvas
  static const Color cardBg = Colors.white; // Pure White Card Surfaces
  static const Color surfaceMuted = Color(0xFFF8FAFC); // Subtle Inset Background
  static const Color sidebarBg = Color(0xFF0B192C); // Midnight Navy Sidebar

  // Text Hierarchy
  static const Color textDark = Color(0xFF0B192C); // Midnight Slate Primary
  static const Color textMuted = Color(0xFF64748B); // Slate Muted Subtitles
  static const Color textLight = Color(0xFF94A3B8); // Slate Subtle Footnotes

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE2E8F0); // Crisp Hairline Separator
  static const Color metallicBorder = Color(0x1A1244A2); // Subtle 10% Sapphire Micro-Stroke
  static const Color metallicBorderHover = Color(0x3D1244A2); // 24% Sapphire Hover Stroke

  // Semantic Status Tints
  static const Color successGreen = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successText = Color(0xFF047857);

  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningText = Color(0xFFB45309);

  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerText = Color(0xFFB91C1C);

  static const Color infoBlue = Color(0xFF1244A2);
  static const Color infoBg = Color(0xFFEBF2FF);
  static const Color infoText = Color(0xFF0C2D6F);

  static const Color purpleBg = Color(0xFFF5F3FF);
  static const Color purpleText = Color(0xFF6D28D9);

  // Healthcare Jewel Tone Palette for Data & Analytics
  static const Color jewelTechCyan = Color(0xFF00D2FF); // Primary Data Series
  static const Color jewelViolet = Color(0xFF7C3AED); // Secondary Metric
  static const Color jewelAmber = Color(0xFFF59E0B); // Risk & Warning Metrics
  static const Color jewelCoral = Color(0xFFEF4444); // Critical Non-Adherent Flags
  static const Color jewelEmerald = Color(0xFF10B981); // Optimal Compliance Target
  static const Color jewelSapphire = Color(0xFF1244A2); // Royal Sapphire #1244A2
  static const Color jewelWarmAmber = Color(0xFFF59E0B); // Warm Amber
  static const Color jewelSoftCoral = Color(0xFFF87171); // Soft Coral
  static const Color jewelVividMint = Color(0xFF06B6D4); // Vivid Cyan Tint

  // Royal Sapphire Gradients (#1244A2)
  static const List<Color> gradientBrand = [
    Color(0xFF0B192C), // Deep Midnight Slate
    Color(0xFF0C2D6F), // Deep Oceanic Navy
    Color(0xFF1244A2), // Royal Sapphire Blue (#1244A2)
  ];

  static const List<Color> gradientCanvas = [
    Color(0xFF071426),
    Color(0xFF0C2D6F),
    Color(0xFF1244A2),
    Color(0xFF2563EB),
  ];

  static const List<Color> gradientPill = [
    Color(0xFF1244A2), // Royal Sapphire Blue (#1244A2)
    Color(0xFF2563EB), // Vivid Electric Blue
  ];

  static const List<Color> gradientShimmer = [
    Color(0xFFE2E8F0),
    Color(0xFFF1F5F9),
    Color(0xFFE2E8F0),
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
        secondary: AppColors.electricMint,
        surface: AppColors.cardBg,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          letterSpacing: -0.8,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          letterSpacing: -0.6,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          letterSpacing: -0.4,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20.0)),
          side: BorderSide(color: AppColors.metallicBorder, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: GoogleFonts.urbanist(
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryTeal,
          side: BorderSide(
            color: AppColors.primaryTeal.withValues(alpha: 0.3),
            width: 1.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: GoogleFonts.urbanist(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSlate,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        hintStyle: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelStyle: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
        floatingLabelStyle: GoogleFonts.urbanist(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryTeal,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.metallicBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.metallicBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: AppColors.primaryTeal,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
