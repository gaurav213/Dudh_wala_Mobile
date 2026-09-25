import 'package:flutter/material.dart';

/// Outdoor-friendly dairy palette — teal/cream, not purple AI defaults.
///
/// Prefer [Dk.of] / [BuildContext] helpers for surfaces & text so Dark mode
/// works. The static consts below are the **light** brand tokens and must stay
/// unchanged (default Light theme).
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

/// Theme-aware dairy surfaces. Light values == historic [AppColors].
@immutable
class DkPalette extends ThemeExtension<DkPalette> {
  const DkPalette({
    required this.cream,
    required this.milkWhite,
    required this.foam,
    required this.ink,
    required this.muted,
  });

  final Color cream;
  final Color milkWhite;
  final Color foam;
  final Color ink;
  final Color muted;

  static const light = DkPalette(
    cream: AppColors.cream,
    milkWhite: AppColors.milkWhite,
    foam: AppColors.foam,
    ink: AppColors.ink,
    muted: AppColors.muted,
  );

  static const dark = DkPalette(
    cream: Color(0xFF14201E),
    milkWhite: Color(0xFF1C2B2A),
    foam: Color(0xFF243634),
    ink: Color(0xFFE8F0EE),
    muted: Color(0xFF9BB0AC),
  );

  @override
  DkPalette copyWith({
    Color? cream,
    Color? milkWhite,
    Color? foam,
    Color? ink,
    Color? muted,
  }) {
    return DkPalette(
      cream: cream ?? this.cream,
      milkWhite: milkWhite ?? this.milkWhite,
      foam: foam ?? this.foam,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
    );
  }

  @override
  DkPalette lerp(ThemeExtension<DkPalette>? other, double t) {
    if (other is! DkPalette) return this;
    return DkPalette(
      cream: Color.lerp(cream, other.cream, t)!,
      milkWhite: Color.lerp(milkWhite, other.milkWhite, t)!,
      foam: Color.lerp(foam, other.foam, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

/// Shortcut: `Dk.of(context).cream`
class Dk {
  static DkPalette of(BuildContext context) {
    return Theme.of(context).extension<DkPalette>() ?? DkPalette.light;
  }
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
      extensions: const [DkPalette.light],
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
          side: BorderSide(color: AppColors.leaf.withValues(alpha: 0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.milkWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.3)),
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
          // Finite width: Size.fromHeight(∞) crashes buttons in horizontal Rows.
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.leafDark,
          // Finite width: Size.fromHeight(∞) crashes buttons in horizontal Rows.
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: AppColors.leaf),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.foam,
        selectedColor: AppColors.teal.withValues(alpha: 0.25),
        labelStyle: const TextStyle(color: AppColors.ink),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.milkWhite,
        indicatorColor: AppColors.foam,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Additive dark theme — does not alter [light] tokens.
  static ThemeData dark() {
    const surface = Color(0xFF14201E);
    const surfaceHigh = Color(0xFF1C2B2A);
    const onSurface = Color(0xFFE8F0EE);
    const muted = Color(0xFF9BB0AC);

    final base = ColorScheme.fromSeed(
      seedColor: AppColors.leaf,
      brightness: Brightness.dark,
      primary: AppColors.teal,
      secondary: AppColors.leaf,
      surface: surfaceHigh,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: surface,
      extensions: const [DkPalette.dark],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.leafDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.teal.withValues(alpha: 0.2)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: muted.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          // Finite width: Size.fromHeight(∞) crashes buttons in horizontal Rows.
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          // Finite width: Size.fromHeight(∞) crashes buttons in horizontal Rows.
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: AppColors.teal),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.leafDark.withValues(alpha: 0.45),
        selectedColor: AppColors.teal.withValues(alpha: 0.35),
        labelStyle: const TextStyle(color: onSurface),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceHigh,
        indicatorColor: AppColors.leafDark.withValues(alpha: 0.7),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: surfaceHigh),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
