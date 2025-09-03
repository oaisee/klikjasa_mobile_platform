import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk mengelola koneksi dan operasi Supabase
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  /// Singleton instance
  static SupabaseService get instance => _instance;
  
  /// Supabase client
  late final SupabaseClient _supabaseClient;
  
  /// Getter untuk supabase client
  SupabaseClient get client => _supabaseClient;
  
  SupabaseService._internal() {
    _supabaseClient = Supabase.instance.client;
  }
  
  /// Inisialisasi Supabase
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
