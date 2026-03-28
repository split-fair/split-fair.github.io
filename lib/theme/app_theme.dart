import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF1D9E75);
  static const primaryLight = Color(0xFFE1F5EE);
  static const primaryDark = Color(0xFF0F6E56);
  static const accent = Color(0xFFEF9F27);
  static const accentLight = Color(0xFFFAEEDA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF8F9FA);
  static const border = Color(0xFFE8EAED);
  static const borderMed = Color(0xFFD0D4D9);
  static const textPrimary = Color(0xFF1A1D23);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const error = Color(0xFFE24B4A);
  static const errorLight = Color(0xFFFCEBEB);
  static const roomColors = [
    Color(0xFF1D9E75), // green
    Color(0xFF378ADD), // blue
    Color(0xFFEF9F27), // amber
    Color(0xFFD85A30), // deep orange-red
    Color(0xFFEA4335), // google red
    Color(0xFFD4537E), // pink
    Color(0xFF00897B), // teal
    Color(0xFF34A853), // google green (light)
    Color(0xFF0097A7), // cyan
    Color(0xFF8D6E63), // warm brown
  ];
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light, surface: AppColors.surface),
      scaffoldBackgroundColor: AppColors.surfaceVariant,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2),
        displayMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.6),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface, elevation: 0, centerTitle: false,
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border, width: 1)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
        hintStyle: GoogleFonts.inter(fontSize: 15, color: AppColors.textTertiary),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary, thumbColor: AppColors.primary,
        overlayColor: Color(0x201D9E75), inactiveTrackColor: AppColors.border, trackHeight: 4,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 0),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}