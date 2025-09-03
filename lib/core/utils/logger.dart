import 'package:flutter/foundation.dart';

/// Kelas Logger sederhana untuk aplikasi Klik Jasa
/// Digunakan untuk mencatat log dengan berbagai level kepentingan
class Logger {
  /// Log informasi debug (hanya ditampilkan di mode debug)
  void d(String message) {
    if (kDebugMode) {
      print('🔍 DEBUG: $message');
    }
  }

  /// Log informasi umum
  void i(String message) {
    if (kDebugMode) {
      print('ℹ️ INFO: $message');
    }
  }

  /// Log peringatan
  void w(String message) {
    if (kDebugMode) {
      print('⚠️ WARN: $message');
    }
  }

  /// Log error
  void e(String message) {
    if (kDebugMode) {
      print('❌ ERROR: $message');
    }
  }

  /// Log error fatal
  void wtf(String message) {
    if (kDebugMode) {
      print('💥 FATAL: $message');
    }
  }
}

/// Instance global dari Logger untuk digunakan di seluruh aplikasi
final Logger logger = Logger();
