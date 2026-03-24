import 'package:flutter/material.dart';

/// DUONET design-language color palette
///
/// Each color is mapped to a purpose and emotion:
/// • Electric Blue  #1B8EF8  — primary / trust / technology
/// • Deep Indigo    #4C5FD5  — secondary / depth / time
/// • Cyan/Teal      #00E5CC  — discovery / freshness / search
/// • Emerald        #00D68F  — success / online / growth
/// • Amber          #F59E0B  — vehicles / energy / movement
/// • Coral          #FF6B6B  — error / offline / alert
/// • Purple         #7C6FF7  — analytics / premium / wisdom
/// • Pink           #FF4081  — aesthetics / highlight / excitement
class AppColors {
  const AppColors._();

  static const electricBlue = Color(0xFF1B8EF8);
  static const deepIndigo = Color(0xFF4C5FD5);
  static const teal = Color(0xFF00E5CC);
  static const emerald = Color(0xFF00D68F);
  static const amber = Color(0xFFF59E0B);
  static const coral = Color(0xFFFF6B6B);
  static const purple = Color(0xFF7C6FF7);
  static const pink = Color(0xFFFF4081);

  // ── Dark palette ──
  static const darkBg = Color(0xFF060A1A);
  static const darkSurface = Color(0xFF0D1225);
  static const darkCard = Color(0xFF111729);
  static const darkElevated = Color(0xFF1A2038);

  // ── Light palette ──
  static const lightBg = Color(0xFFF4F6FB);
  static const lightSurface = Colors.white;
  static const lightCard = Colors.white;
  static const lightBorder = Color(0xFFE8EBF3);
}

class ThemeConfig {
  const ThemeConfig._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.electricBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.electricBlue,
          secondary: AppColors.deepIndigo,
          tertiary: AppColors.teal,
          error: AppColors.coral,
          surface: AppColors.lightSurface,
          surfaceContainerHighest: AppColors.lightBg,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: AppColors.lightCard,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F1629),
          ),
          iconTheme: IconThemeData(color: Color(0xFF0F1629)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide:
                BorderSide(color: AppColors.electricBlue, width: 1.5),
          ),
          hintStyle: TextStyle(
            color: Color(0xFFADB5CC),
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
        textTheme: _textTheme(isLight: true),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightBorder,
          thickness: 1,
          space: 1,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.electricBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.electricBlue,
          secondary: AppColors.deepIndigo,
          tertiary: AppColors.teal,
          error: AppColors.coral,
          surface: AppColors.darkSurface,
          surfaceContainerHighest: AppColors.darkCard,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: AppColors.darkCard,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide:
                BorderSide(color: AppColors.electricBlue, width: 1.5),
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF4A5270),
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
        textTheme: _textTheme(isLight: false),
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.08),
          thickness: 1,
          space: 1,
        ),
      );

  static TextTheme _textTheme({required bool isLight}) {
    final base = isLight ? const Color(0xFF0F1629) : Colors.white;
    final secondary =
        isLight ? const Color(0xFF4A5270) : const Color(0xFFB0B8D0);
    final hint = isLight ? const Color(0xFFADB5CC) : const Color(0xFF4A5270);

    return TextTheme(
      // Display
      displayLarge: TextStyle(
          fontSize: 36, fontWeight: FontWeight.w800, color: base, height: 1.2),
      displayMedium: TextStyle(
          fontSize: 30, fontWeight: FontWeight.w800, color: base, height: 1.2),
      displaySmall: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: base, height: 1.3),

      // Headlines
      headlineLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: base),
      headlineMedium: TextStyle(
          fontSize: 19, fontWeight: FontWeight.w700, color: base),
      headlineSmall: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w700, color: base),

      // Titles
      titleLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: base),
      titleMedium: TextStyle(
          fontSize: 14.5, fontWeight: FontWeight.w600, color: base),
      titleSmall: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: secondary),

      // Body
      bodyLarge: TextStyle(fontSize: 15, color: base, height: 1.6),
      bodyMedium: TextStyle(fontSize: 14, color: base, height: 1.6),
      bodySmall: TextStyle(fontSize: 12.5, color: secondary, height: 1.5),

      // Labels
      labelLarge: TextStyle(
          fontSize: 13.5, fontWeight: FontWeight.w600, color: base),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: secondary),
      labelSmall: TextStyle(
          fontSize: 10.5, fontWeight: FontWeight.w600, color: hint,
          letterSpacing: 0.3),
    );
  }
}