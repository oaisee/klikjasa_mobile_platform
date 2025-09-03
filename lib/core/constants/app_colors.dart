import 'package:flutter/material.dart';

// Kelas ini berisi definisi warna yang digunakan di seluruh aplikasi KlikJasa.
// Penggunaan konstanta warna membantu menjaga konsistensi UI dan memudahkan perubahan tema.

class AppColors {
  // Warna Primer (Netral, sesuai arahan desain)
  static const Color primary = Color(0xFF02A8C2); // Contoh: Abu-abu tua netral
  static const Color primaryLight = Color(0xFF757575);
  static const Color primaryDark = Color(0xFF212121);

  // Warna Aksen (Cerah, untuk menarik perhatian)
  static const Color accent = Color(0xFF00ACC1); // Contoh: Cyan cerah
  static const Color accentLight = Color(0xFF5DDEF4);
  static const Color accentDark = Color(0xFF007C91);

  // Warna Latar Belakang
  static const Color backgroundLight = Color(0xFFFFFFFF); // Putih bersih
  static const Color backgroundDark = Color(0xFF121212); // Abu-abu sangat gelap untuk dark mode
  static const Color scaffoldBackground = Color(0xFFF5F5F5); // Abu-abu muda untuk latar belakang scaffold

  // Warna Teks
  static const Color textPrimaryLight = Color(0xFF212121); // Hitam untuk teks di tema terang
  static const Color textSecondaryLight = Color(0xFF757575); // Abu-abu untuk teks sekunder di tema terang
  static const Color textPrimaryDark = Color(0xFFFFFFFF);   // Putih untuk teks di tema gelap
  static const Color textSecondaryDark = Color(0xFFBDBDBD);  // Abu-abu muda untuk teks sekunder di tema gelap
  static const Color textHintLight = Color(0xFFAAAAAA); // Abu-abu lebih muda untuk hint di tema terang

  // Alias untuk penggunaan umum (asumsi tema terang untuk saat ini)
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;

  // Warna Status & Notifikasi
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Warna Surface (untuk card, dialog, dll)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Warna Border & Divider
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  // Warna Shadow
  static const Color shadowLight = Color(0x1A000000); // 10% opacity black
  static const Color shadowDark = Color(0x1AFFFFFF);   // 10% opacity white

  // Warna Umum
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF424242);
  static const Color transparent = Colors.transparent;

  // Warna untuk komponen khusus
  static const Color cardBackground = white;
  static const Color inputBackground = Color(0xFFFAFAFA);
  static const Color disabledColor = Color(0xFFBDBDBD);
  static const Color focusColor = Color(0x1F02A8C2); // 12% opacity primary

  // Getter untuk kompatibilitas dengan kode yang ada
  static Color get background => backgroundLight;
  static Color get border => borderLight;
  static Color get secondary => textSecondaryLight;
  static Color get surface => surfaceLight;
  static Color get divider => dividerLight;
}