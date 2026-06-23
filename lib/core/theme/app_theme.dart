import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.gold,
        secondary: AppColors.terracotta,
        surface: AppColors.lightBg,
        error: Color(0xFFBA1A1A),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.deepEarth),
        titleTextStyle: TextStyle(
          color: AppColors.deepEarth,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.deepEarth.withOpacity(0.08),
      fontFamily: 'sans-serif',
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.terracotta,
        surface: AppColors.darkBg,
        error: Color(0xFFFFB4AB),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardColor: AppColors.darkCard,
      dividerColor: Colors.white.withOpacity(0.08),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
        bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
        titleLarge: TextStyle(color: AppColors.gold, fontFamily: 'serif'),
      ),
      fontFamily: 'sans-serif',
    );
  }
}