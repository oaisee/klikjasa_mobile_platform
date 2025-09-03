import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

/// Tema aplikasi KlikJasa dengan desain modern minimalis
///
/// Kelas ini menyediakan tema terang dan gelap yang konsisten
/// dengan menggunakan AppColors dan font Poppins
class AppTheme {
  /// Tema Terang Aplikasi dengan desain modern minimalis
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Poppins', // Font utama aplikasi
      // Skema warna utama menggunakan AppColors
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.backgroundLight,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimaryLight,
        onError: AppColors.white,
      ),

      // Latar belakang utama aplikasi untuk whitespace yang optimal
      scaffoldBackgroundColor: AppColors.scaffoldBackground,

      // Tema untuk AppBar dengan desain minimalis
      appBarTheme: AppBarTheme(
        elevation: 0.5, // Elevasi minimalis
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      // Tema untuk tombol utama (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2.0,
          shadowColor: AppColors.primary.withAlpha(
            77,
          ), // 0.3 * 255 = 76.5 -> 77
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Sudut lebih modern
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        ),
      ),

      // Tema untuk input field dengan desain modern
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.error),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textSecondaryLight,
          fontSize: 14.0,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textSecondaryLight,
          fontSize: 14.0,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
      ),

      // Tema untuk teks dengan hierarki yang jelas
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryLight,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryLight,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryLight,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryLight,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryLight,
        ),
      ),

      // Tema untuk Card dengan desain modern
      cardTheme: CardThemeData(
        elevation: 1.0,
        shadowColor: AppColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: AppColors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),

      // Tema untuk Divider
      dividerTheme: DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1.0,
        space: 1.0,
      ),

      // Tema untuk BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8.0,
      ),
    );
  }

  /// Tema Gelap Aplikasi dengan kontras tinggi
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',

      // Skema warna untuk mode gelap
      colorScheme: ColorScheme.dark(
        primary: const Color(
          0xFF02A8C2,
        ), // Tetap menggunakan warna primer utama
        secondary: const Color(0xFF00ACC1),
        surface: AppColors.backgroundDark,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimaryDark,
        onError: AppColors.white,
      ),

      // Latar belakang utama untuk mode gelap
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // AppBar theme untuk mode gelap
      appBarTheme: AppBarTheme(
        elevation: 0.5,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: AppColors.transparent,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      ),

      // ElevatedButton theme untuk mode gelap
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2.0,
          shadowColor: AppColors.primary.withAlpha(
            77,
          ), // 0.3 * 255 = 76.5 -> 77
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        ),
      ),

      // Input decoration theme untuk mode gelap
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.error),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textSecondaryDark,
          fontSize: 14.0,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textSecondaryDark,
          fontSize: 14.0,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
      ),

      // Text theme untuk mode gelap
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryDark,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryDark,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryDark,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
        ),
      ),

      // Card theme untuk mode gelap
      cardTheme: CardThemeData(
        elevation: 2.0,
        shadowColor: AppColors.shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: AppColors.surfaceDark,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),

      // Divider theme untuk mode gelap
      dividerTheme: DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1.0,
        space: 1.0,
      ),

      // BottomNavigationBar theme untuk mode gelap
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8.0,
      ),
    );
  }
}
