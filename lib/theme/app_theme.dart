import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const deepNight = Color(0xFF061A16);
  static const forest = Color(0xFF0C2F28);
  static const emerald = Color(0xFF1A5C4A);
  static const softLeaf = Color(0xFF2D8A6E);
  static const mint = Color(0xFF7BC4A8);
  static const sand = Color(0xFFD4B88A);
  static const gold = Color(0xFFC9A05A);
  static const cream = Color(0xFFF3EDE2);
  static const mist = Color(0xFFB8C9C2);
  static const card = Color(0xFF0F2A24);
  static const cardBorder = Color(0xFF1E4A3E);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deepNight,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.softLeaf,
        secondary: AppColors.gold,
        surface: AppColors.forest,
        onPrimary: AppColors.cream,
        onSecondary: AppColors.deepNight,
        onSurface: AppColors.cream,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: AppColors.cream,
        displayColor: AppColors.cream,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.cream,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.cream),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.deepNight,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.mist),
        hintStyle: TextStyle(color: AppColors.mist.withValues(alpha: 0.6)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.emerald,
        contentTextStyle: GoogleFonts.outfit(color: AppColors.cream),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextStyle arabic({
    double fontSize = 32,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.cream,
    double height = 1.6,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }
}
