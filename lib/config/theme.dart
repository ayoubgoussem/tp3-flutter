import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs personnalisées
  static const Color _primaryIndigo = Color(0xFF5E35B1); // Indigo profond
  static const Color _secondaryTeal = Color(0xFF26A69A); // Teal accent
  static const Color _backgroundLight = Color(0xFFF3F4F9); // Gris-bleu clair
  
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryIndigo,
        secondary: _secondaryTeal,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: _backgroundLight,
      
      // AppBar avec fond transparent et titre centré
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _primaryIndigo,
        titleTextStyle: const TextStyle(
          color: _primaryIndigo,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Input fields avec meilleur contraste
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryIndigo, width: 2),
        ),
      ),
      
      // Cards avec ombre douce et coins arrondis
      cardTheme: CardThemeData(
        elevation: 6,
        shadowColor: _primaryIndigo.withValues(alpha: 0.15),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      
      // Boutons élevés avec style moderne
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          shadowColor: _primaryIndigo.withValues(alpha: 0.3),
          backgroundColor: _primaryIndigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Boutons remplis
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 2,
          shadowColor: _secondaryTeal.withValues(alpha: 0.25),
          backgroundColor: _secondaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Boutons outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryIndigo,
          side: const BorderSide(color: _primaryIndigo, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Polices globales améliorées
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _primaryIndigo,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _primaryIndigo,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _primaryIndigo,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }
}
