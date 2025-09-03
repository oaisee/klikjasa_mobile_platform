import 'package:flutter/foundation.dart';

/// Konfigurasi environment untuk aplikasi KlikJasa
/// 
/// Kelas ini mengelola konfigurasi berdasarkan environment (development, staging, production)
/// dan menyediakan akses aman ke kredensial tanpa hardcoding
class EnvironmentConfig {
  // CATATAN KEAMANAN: Nilai default ini hanya untuk development lokal.
  // Untuk production, gunakan environment variable yang sebenarnya.
  // Nilai ini akan diganti dengan nilai dari environment variable jika tersedia.
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xsieocenvcpmflishoaj.supabase.co',
  );
  
  // CATATAN KEAMANAN: Nilai default ini hanya untuk development lokal.
  // Untuk production, gunakan environment variable yang sebenarnya.
  // Nilai ini akan diganti dengan nilai dari environment variable jika tersedia.
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzaWVvY2VudmNwbWZsaXNob2FqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxODQ5MjUsImV4cCI6MjA2NDc2MDkyNX0.lQC4fuLoF_NkSgH2HIw3_qk_JaRhA6CCP5-l0nm1eA0',
  );
  
  static const String _supabaseServiceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: '',
  );

  /// Environment saat ini (development, staging, production)
  static Environment get currentEnvironment {
    if (kDebugMode) {
      return Environment.development;
    } else if (kProfileMode) {
      return Environment.staging;
    } else {
      return Environment.production;
    }
  }

  /// URL Supabase berdasarkan environment
  static String get supabaseUrl {
    // Untuk production, pastikan menggunakan environment variable
    if (currentEnvironment == Environment.production && _supabaseUrl == 'https://xsieocenvcpmflishoaj.supabase.co') {
      throw Exception('SUPABASE_URL tidak dikonfigurasi untuk production. Gunakan environment variable yang sebenarnya.');
    }
    return _supabaseUrl;
  }

  /// Anon key Supabase untuk client-side operations
  static String get supabaseAnonKey {
    // Untuk production, pastikan menggunakan environment variable
    if (currentEnvironment == Environment.production && 
        _supabaseAnonKey.startsWith('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')) {
      throw Exception('SUPABASE_ANON_KEY tidak dikonfigurasi untuk production. Gunakan environment variable yang sebenarnya.');
    }
    return _supabaseAnonKey;
  }

  /// Service role key Supabase untuk admin operations (hanya untuk server-side)
  /// PERINGATAN: Jangan gunakan di client-side!
  static String get supabaseServiceRoleKey {
    if (currentEnvironment == Environment.production) {
      throw UnsupportedError(
        'Service role key tidak boleh digunakan di production client-side!'
      );
    }
    return _supabaseServiceRoleKey;
  }

  /// Konfigurasi logging berdasarkan environment
  static bool get enableLogging {
    return currentEnvironment != Environment.production;
  }

  /// Konfigurasi debug mode
  static bool get isDebugMode {
    return currentEnvironment == Environment.development;
  }

  /// Base URL untuk API eksternal (jika ada)
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'https://dev-api.klikjasa.com';
      case Environment.staging:
        return 'https://staging-api.klikjasa.com';
      case Environment.production:
        return 'https://api.klikjasa.com';
    }
  }

  /// Timeout untuk HTTP requests (dalam detik)
  static int get httpTimeoutSeconds {
    switch (currentEnvironment) {
      case Environment.development:
        return 30;
      case Environment.staging:
        return 20;
      case Environment.production:
        return 15;
    }
  }
}

/// Enum untuk environment aplikasi
enum Environment {
  development,
  staging,
  production,
}

/// Extension untuk Environment enum
extension EnvironmentExtension on Environment {
  String get name {
    switch (this) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  String get value {
    switch (this) {
      case Environment.development:
        return 'dev';
      case Environment.staging:
        return 'staging';
      case Environment.production:
        return 'prod';
    }
  }
}