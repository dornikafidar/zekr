import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Calm night-mosque palette: deep jade, warm gold, soft parchment.
class AppColors {
  static const deepNight = Color(0xFF041411);
  static const abyss = Color(0xFF020C0A);
  static const forest = Color(0xFF0B2822);
  static const emerald = Color(0xFF176B55);
  static const softLeaf = Color(0xFF2F9A78);
  static const mint = Color(0xFF8FD4B8);
  static const gold = Color(0xFFD4AF6A);
  static const goldDeep = Color(0xFFA8843E);
  static const cream = Color(0xFFF6F0E4);
  static const mist = Color(0xFFA9BDB4);
  static const card = Color(0xFF0D251F);
  static const cardElevated = Color(0xFF12332B);
  static const cardBorder = Color(0xFF255447);
  static const danger = Color(0xFFE07A6A);
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
        error: AppColors.danger,
      ),
    );

    final body = GoogleFonts.vazirmatnTextTheme(base.textTheme).apply(
      bodyColor: AppColors.cream,
      displayColor: AppColors.cream,
    );

    return base.copyWith(
      textTheme: body,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.vazirmatn(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.cream,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.cream),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.deepNight,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.deepNight,
          textStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card.withValues(alpha: 0.75),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.7),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
        labelStyle: GoogleFonts.vazirmatn(color: AppColors.mist, fontSize: 13),
        hintStyle: GoogleFonts.vazirmatn(
          color: AppColors.mist.withValues(alpha: 0.55),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.emerald,
        contentTextStyle: GoogleFonts.vazirmatn(color: AppColors.cream),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.forest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: AppColors.cardBorder,
        thumbColor: AppColors.gold,
        overlayColor: AppColors.gold.withValues(alpha: 0.15),
      ),
    );
  }

  static TextStyle arabic({
    double fontSize = 32,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.cream,
    double height = 1.65,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  /// UI text (Persian / Latin labels).
  static TextStyle latin({
    double fontSize = 15,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.cream,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.vazirmatn(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
