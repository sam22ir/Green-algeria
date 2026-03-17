import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.linenWhite,
    primaryColor: AppColors.oliveGrove,
    colorScheme: ColorScheme.light(
      primary: AppColors.oliveGrove,
      secondary: AppColors.mossForest,
      surface: Colors.white,
      onSurface: AppColors.oliveGrey,
      onPrimary: Colors.white,
      error: AppColors.alertRed,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.slateCharcoal),
      titleTextStyle: TextStyle(
        color: AppColors.slateCharcoal,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.oliveGrey.withValues(alpha: 0.1)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.oliveGrey.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.oliveGrey.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.oliveGrove),
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      expansionAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 200),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBgPrimary,
    primaryColor: AppColors.darkBrand,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkBrand,
      onPrimary: AppColors.darkBgPrimary,
      surface: AppColors.darkBgSecondary,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainer: AppColors.darkBgWidget,
      surfaceContainerLow: AppColors.darkBgWidget,
      surfaceContainerHigh: AppColors.darkSurface,
      surfaceContainerHighest: AppColors.darkBgInput,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      secondary: AppColors.darkBorder,
      onSecondary: AppColors.darkTextSecondary,
      tertiary: AppColors.darkSurface,
      error: AppColors.alertRed,
      onError: Colors.white,
    ),
    cardColor: AppColors.darkBgSecondary,
    dividerColor: AppColors.darkDivider,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.darkBgInput,
      filled: true,
      hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkBrand),
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      expansionAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 200),
      ),
    ),
  );
}

