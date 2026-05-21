import 'package:flutter/material.dart';

class NTKColors {
  // Primary - Refined Emerald Palette
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald900 = Color(0xFF064E3B);

  // Secondary - Refined Slate Palette
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate900 = Color(0xFF0F172A);

  // Accent/Alert
  static const amber500 = Color(0xFFF59E0B);
  static const red500 = Color(0xFFEF4444);

  // Semantic mappings
  static const primary = emerald600;
  static const primaryDark = emerald700;
  static const secondary = slate600;
  static const background = slate50;
  static const surface = Colors.white;
  static const error = red500;
  
  static const textPrimary = slate900;
  static const textSecondary = slate500;
  static const textTertiary = slate400;
  static const border = slate200;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: NTKColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NTKColors.primary,
        primary: NTKColors.primary,
        onPrimary: Colors.white,
        secondary: NTKColors.amber500,
        surface: NTKColors.surface,
        error: NTKColors.error,
        onSurface: NTKColors.textPrimary,
        outline: NTKColors.border,
      ),

      // Typography - Using a modern scale
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: NTKColors.textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: NTKColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: NTKColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: NTKColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: NTKColors.textSecondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: NTKColors.primary,
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: NTKColors.surface,
        foregroundColor: NTKColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: NTKColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: NTKColors.textPrimary),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NTKColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          elevation: ButtonStyleButton.allOrNull(0.0),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NTKColors.primary,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: NTKColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NTKColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NTKColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NTKColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NTKColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NTKColors.error),
        ),
        hintStyle: const TextStyle(color: NTKColors.textTertiary, fontSize: 14),
        prefixIconColor: NTKColors.textSecondary,
        suffixIconColor: NTKColors.textSecondary,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: NTKColors.surface,
        elevation: 2,
        shadowColor: NTKColors.slate900.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: NTKColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
