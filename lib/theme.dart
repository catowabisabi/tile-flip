import 'package:flutter/material.dart';

/// Dark, modern palette for Tile Flip.
///
/// Designed for a calm, premium feel:
///  - deep navy backdrop with a subtle radial gradient
///  - glass surfaces (translucent white with backdrop blur) for stats & dialogs
///  - coral accent for interactive highlights & star ratings
///  - WCAG AA contrast: `ink` on `background` ≈ 14:1, `inkSoft` on glass ≈ 5:1
class AppColors {
  // Background / gradient endpoints.
  static const bg0 = Color(0xFF0A0F1F); // near-black navy (gradient start)
  static const bg1 = Color(0xFF141B36); // slate navy (gradient end)
  static const background = bg0;

  // Surfaces — used with glassmorphism on top of the gradient backdrop.
  static const surface = Color(0xFF1B2340);
  static const surfaceAlt = Color(0xFF242C4D);

  // Text tiers.
  static const ink = Color(0xFFF4F6FC); // primary
  static const inkSoft = Color(0xFFB9C0D9); // secondary
  static const muted = Color(0xFF6C7595); // disabled / locked

  // Accents.
  static const accent = Color(0xFFFF8A65); // coral — CTA / stars
  static const accentSoft = Color(0xFFFFB59E);
  static const secondary = Color(0xFF7FC8FF); // cool cyan for icons

  // Tiles — high-contrast for readability.
  static const tileLight = Color(0xFFEDEFF8);
  static const tileDark = Color(0xFF2B335A);

  // Status.
  static const success = Color(0xFF5DE0A6);
  static const error = Color(0xFFFF7E87);

  /// Translucent white used as the glass fill colour.
  static Color glassFill([double alpha = 0.08]) =>
      Color.fromRGBO(255, 255, 255, alpha);

  /// Subtle border for glass surfaces.
  static Color glassBorder([double alpha = 0.14]) =>
      Color.fromRGBO(255, 255, 255, alpha);
}

/// Reusable gradient used by primary CTAs and the app backdrop.
class AppGradients {
  static const backdrop = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bg0, AppColors.bg1],
  );

  static const accentButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9A76), Color(0xFFFF6B52)],
  );

  static const surfaceCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x22FFFFFF), Color(0x0AFFFFFF)],
  );
}

class AppTheme {
  /// Dark theme — the only theme we ship. Kept a named constructor for API
  /// stability with tests/pre-existing callers that expect `AppTheme.dark()`.
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onPrimary: AppColors.bg0,
        onSecondary: AppColors.bg0,
        onSurface: AppColors.ink,
      ),
      textTheme: base.textTheme
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
          .copyWith(
            displayLarge: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.8,
              color: AppColors.ink,
            ),
            titleLarge: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            bodyMedium: TextStyle(
              fontSize: 15,
              color: AppColors.inkSoft,
              height: 1.45,
              letterSpacing: 0.1,
            ),
            labelLarge: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: 0.3,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.bg0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(color: AppColors.glassBorder(0.35), width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
    );
  }

  /// Legacy alias. The light theme has been retired; this now returns the
  /// dark theme so any stray callers keep rendering correctly.
  static ThemeData light() => dark();
}
