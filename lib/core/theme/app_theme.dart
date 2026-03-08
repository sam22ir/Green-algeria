import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.linenWhite,
      colorScheme: const ColorScheme.light(
        primary: AppColors.mossForest,
        secondary: AppColors.oliveGrove,
        surface: AppColors.ivorySand,
        onSurface: AppColors.slateCharcoal,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.cairoTextTheme().apply(
        bodyColor: AppColors.slateCharcoal,
        displayColor: AppColors.slateCharcoal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.linenWhite,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.mossForest),
        titleTextStyle: TextStyle(
          color: AppColors.slateCharcoal,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mossForest,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.linenWhite,
        selectedItemColor: AppColors.mossForest,
        unselectedItemColor: AppColors.oliveGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // We will adjust these dark mode colors later according to the Dark Mode spec docs
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.mossForest,
        secondary: AppColors.oliveGrove,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.cairoTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.mossForest),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mossForest,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: AppColors.mossForest,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
