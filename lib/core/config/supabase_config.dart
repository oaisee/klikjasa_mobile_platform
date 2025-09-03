import 'package:klik_jasa/core/config/environment_config.dart';

/// Konfigurasi Supabase untuk aplikasi KlikJasa
/// 
/// Kelas ini menyediakan akses ke konfigurasi Supabase yang aman
/// dengan menggunakan EnvironmentConfig untuk mengelola kredensial
/// berdasarkan environment yang sedang berjalan.
class SupabaseConfig {
  /// URL instance Supabase berdasarkan environment
  static String get supabaseUrl => EnvironmentConfig.supabaseUrl;

  /// Kunci Anon (public) Supabase berdasarkan environment
  /// Kunci ini aman untuk diekspos di sisi klien karena adanya Row Level Security (RLS)
  static String get supabaseAnonKey => EnvironmentConfig.supabaseAnonKey;

  /// Konfigurasi timeout untuk operasi Supabase (dalam detik)
  static int get timeoutSeconds => EnvironmentConfig.httpTimeoutSeconds;

  /// Apakah logging Supabase diaktifkan
  static bool get enableLogging => EnvironmentConfig.enableLogging;

  /// Validasi konfigurasi Supabase
  static bool get isConfigValid {
    return supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty &&
           supabaseUrl.startsWith('https://');
  }

  /// Mendapatkan informasi environment saat ini
  static String get environmentInfo {
    return 'Environment: ${EnvironmentConfig.currentEnvironment.name} '
           '(${EnvironmentConfig.currentEnvironment.value})';
  }
}
