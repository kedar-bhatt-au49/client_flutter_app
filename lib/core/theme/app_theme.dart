import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Central theme for the Global Solar 2.0 client app.
abstract class GSTheme {
  static ThemeData get light {
    final cs = ColorScheme(
      brightness: Brightness.light,
      primary: GSColors.navy700,
      onPrimary: GSColors.white,
      secondary: GSColors.gold500,
      onSecondary: GSColors.ink,
      error: Colors.red,
      onError: GSColors.white,
      surface: GSColors.white,
      onSurface: GSColors.ink,
      surfaceContainerHighest: GSColors.sky100,
      outline: GSColors.navy900.withValues(alpha: 0.3),
    );

    return ThemeData(
      colorScheme: cs,
      fontFamily: 'Inter',
      brightness: Brightness.light,
      scaffoldBackgroundColor: GSColors.whiteBg,
      appBarTheme: AppBarTheme(
        backgroundColor: GSColors.navy900,
        foregroundColor: GSColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GSTextStyles.headlineMedium.copyWith(color: GSColors.white),
        iconTheme: const IconThemeData(color: GSColors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: GSColors.glassWhite,
        selectedItemColor: GSColors.gold500,
        unselectedItemColor: GSColors.ink.withValues(alpha: 0.5),
        selectedLabelStyle: GSTextStyles.labelMedium.copyWith(fontSize: 12),
        unselectedLabelStyle: GSTextStyles.labelMedium.copyWith(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GSColors.gold500,
          foregroundColor: GSColors.ink,
          elevation: 4,
          shadowColor: GSColors.gold500.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GSTextStyles.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GSColors.navy900,
          side: const BorderSide(color: GSColors.gold500),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GSColors.gold500,
        foregroundColor: GSColors.navy900,
        elevation: 6,
        iconSize: 28,
      ),
      cardTheme: CardThemeData(
        color: GSColors.white,
        elevation: 4,
        shadowColor: GSColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GSColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: GSColors.navy900.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GSColors.gold500, width: 2),
        ),
        labelStyle: GSTextStyles.bodyMedium.copyWith(color: GSColors.ink.withValues(alpha: 0.7)),
        hintStyle: GSTextStyles.bodyMedium.copyWith(color: GSColors.ink.withValues(alpha: 0.4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GSColors.navy900,
        contentTextStyle: GSTextStyles.bodyMedium.copyWith(color: GSColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GSTextStyles.displayLarge,
        displayMedium: GSTextStyles.displayMedium,
        displaySmall: GSTextStyles.displaySmall,
        headlineLarge: GSTextStyles.headlineLarge,
        headlineMedium: GSTextStyles.headlineMedium,
        headlineSmall: GSTextStyles.headlineSmall,
        bodyLarge: GSTextStyles.bodyLarge,
        bodyMedium: GSTextStyles.bodyMedium,
        bodySmall: GSTextStyles.bodySmall,
        labelLarge: GSTextStyles.labelLarge,
        labelMedium: GSTextStyles.labelMedium,
      ),
    );
  }
}
