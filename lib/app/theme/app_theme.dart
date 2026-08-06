import 'package:flutter/material.dart';

/// Outdoor-friendly dairy palette — teal/cream, not purple AI defaults.
class AppColors {
  static const Color cream = Color(0xFFF7F3E9);
  static const Color milkWhite = Color(0xFFFFFDF8);
  static const Color leaf = Color(0xFF1F6F5B);
  static const Color leafDark = Color(0xFF145544);
  static const Color teal = Color(0xFF2A9D8F);
  static const Color foam = Color(0xFFE8F5F1);
  static const Color ink = Color(0xFF1C2B2A);
  static const Color muted = Color(0xFF5C6B69);
  static const Color warning = Color(0xFFC47D2B);
  static const Color danger = Color(0xFFB42318);
  static const Color success = Color(0xFF1B7A4E);
}

class AppTheme {
  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.leaf,
      brightness: Brightness.light,
      primary: AppColors.leaf,
      secondary: AppColors.teal,
      surface: AppColors.milkWhite,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.leaf,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.milkWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.leaf.withOpacity(0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.milkWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.muted.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.leaf, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.leaf,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.leafDark,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.leaf),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.foam,
        selectedColor: AppColors.teal.withOpacity(0.25),
        labelStyle: const TextStyle(color: AppColors.ink),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.milkWhite,
        indicatorColor: AppColors.foam,
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
