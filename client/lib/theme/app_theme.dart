import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Clinical Health Tech Palette (Linear / Stripe inspired)
  static const Color primaryTeal = Color(0xFF008080); // Surgical Teal Accent
  static const Color primaryDark = Color(0xFF005353); // Deep Surgical Teal
  static const Color primaryLight = Color(0xFFE6F4F4); // Pale Mint/Teal Tint
  static const Color electricMint = Color(0xFF00C9A7); // Energetic Mint Active Accent
  static const Color accentNavy = Color(0xFF0A1128); // Deep Midnight Slate (Primary text)
  static const Color accentMint = Color(0xFF00C9A7); // Vibrant Emerald Mint

  // Canvas & Surface Backgrounds
  static const Color bgSlate = Color(0xFFF4F7FA); // Soft Ice-Blue Gray Canvas
  static const Color cardBg = Colors.white; // Pure White Card Surfaces
  static const Color surfaceMuted = Color(0xFFF8FAFC); // Subtle Inset Background
  static const Color sidebarBg = Color(0xFF0A1128); // Deep Midnight Obsidian

  // Text Hierarchy
  static const Color textDark = Color(0xFF0A1128); // Midnight Slate Primary
  static const Color textMuted = Color(0xFF64748B); // Slate Muted Subtitles
  static const Color textLight = Color(0xFF94A3B8); // Slate Subtle Footnotes

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE2E8F0); // Crisp Hairline Separator
  static const Color metallicBorder = Color(0x14008080); // Subtle 8% Teal Micro-Stroke
  static const Color metallicBorderHover = Color(0x33008080); // 20% Teal Hover Stroke

  // Semantic Status Tints
  static const Color successGreen = Color(0xFF00C9A7);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successText = Color(0xFF065F46);

  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningText = Color(0xFF92400E);

  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerText = Color(0xFF991B1B);

  static const Color infoBlue = Color(0xFF0EA5E9);
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color infoText = Color(0xFF0369A1);

  static const Color purpleBg = Color(0xFFF5F3FF);
  static const Color purpleText = Color(0xFF5B21B6);

  // Healthcare Jewel Tone Palette for Data & Analytics
  static const Color jewelTechCyan = Color(0xFF00B4D8); // Primary Data Series
  static const Color jewelViolet = Color(0xFF7209B7); // Secondary Metric
  static const Color jewelAmber = Color(0xFFF77F00); // Risk & Warning Metrics
  static const Color jewelCoral = Color(0xFFE63946); // Critical Non-Adherent Flags
  static const Color jewelEmerald = Color(0xFF059669); // Optimal Compliance Target
  static const Color jewelSapphire = Color(0xFF0077B6); // Clinical Sapphire
  static const Color jewelWarmAmber = Color(0xFFF77F00); // Warm Amber
  static const Color jewelSoftCoral = Color(0xFFE63946); // Soft Coral
  static const Color jewelVividMint = Color(0xFF00C9A7); // Vivid Mint

  // Linear / Stripe-Grade Gradients
  static const List<Color> gradientBrand = [
    Color(0xFF0A1128), // Deep Midnight Slate
    Color(0xFF005353), // Deep Surgical Teal
    Color(0xFF008080), // Polished Surgical Teal
  ];

  static const List<Color> gradientCanvas = [
    Color(0xFF003838),
    Color(0xFF006666),
    Color(0xFF008080),
    Color(0xFF00C9A7),
  ];

  static const List<Color> gradientPill = [
    Color(0xFF008080), // Surgical Teal
    Color(0xFF00C9A7), // Electric Mint
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
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          letterSpacing: -0.8,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          letterSpacing: -0.6,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          letterSpacing: -0.4,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
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
          textStyle: GoogleFonts.plusJakartaSans(
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
          textStyle: GoogleFonts.plusJakartaSans(
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
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
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