import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFC9A84C);
  static const primaryLight = Color(0xFFE8C96A);
  static const primaryDark = Color(0xFF8A6F2E);
  static const background = Color(0xFF0A0A0B);
  static const surface = Color(0xFF111114);
  static const surfaceAlt = Color(0xFF18181D);
  static const card = Color(0xFF1C1C22);
  static const border = Color(0xFF2A2A35);
  static const textPrimary = Color(0xFFF0EDE6);
  static const textSecondary = Color(0xFF8A8880);
  static const textMuted = Color(0xFF4A4A55);
  static const income = Color(0xFF4CAF82);
  static const expense = Color(0xFFD95A5A);
  static const transfer = Color(0xFF5A8FD9);
  static const gold = Color(0xFFC9A84C);
  static const cash = Color(0xFF4CAF82);
  static const bank = Color(0xFF5A8FD9);
  static const eWallet = Color(0xFF9B7ED9);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.expense,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Syne',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      fontFamily: 'Instrument Sans',
    );
  }
}
