import 'package:flutter/material.dart';

class AppTheme {
  static const Color gold = Color(0xFFD4AF37);
  static const Color deepEarth = Color(0xFF2A1508);
  static const Color darkBg = Color(0xFF120A05);
  static const Color darkCard = Color(0xFF1C120C);
  static const Color terracotta = Color(0xFFC05E3D);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.light,
        surface: const Color(0xFFFDFBF7),
      ),
      scaffoldBackgroundColor: const Color(0xFFFDFBF7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardColor: Colors.white,
      dividerColor: Colors.black.withOpacity(0.05),
      fontFamily: 'sans-serif',
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.dark,
        surface: darkBg,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      cardColor: darkCard,
      dividerColor: Colors.white.withOpacity(0.05),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: gold, fontFamily: 'serif'),
      ),
      fontFamily: 'sans-serif',
    );
  }
}
