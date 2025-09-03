import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Class untuk menambahkan logging pada perubahan pengaturan penting
class AppConfigChangeLogger {
  final Logger _logger;
  final SupabaseClient _supabaseClient;
  
  // Daftar key pengaturan penting yang perlu dilog perubahan nilainya
  final List<String> _importantKeys = [
    'user_fee_percentage',
    'provider_fee_percentage',
    'min_topup_amount',
    'otp_expiry_minutes',
    'max_login_attempts',
    'session_timeout_minutes',
    'two_factor_auth_enabled',
  ];
  
  AppConfigChangeLogger({
    required Logger logger,
    required SupabaseClient supabaseClient,
  }) : _logger = logger, _supabaseClient = supabaseClient;
  
  /// Mencatat perubahan nilai pengaturan penting
  Future<void> logConfigChange({
    required String key,
    required String oldValue,
    required String newValue,
    required String changedBy,
  }) async {
    // Cek apakah key termasuk dalam daftar pengaturan penting
    if (_importantKeys.contains(key)) {
      // Log perubahan ke logger
      _logger.i('PENGATURAN PENTING DIUBAH: $key dari "$oldValue" menjadi "$newValue" oleh $changedBy');
      
      // Simpan log perubahan ke database
      try {
        await _supabaseClient.from('app_config_change_logs').insert({
          'key': key,
          'old_value': oldValue,
          'new_value': newValue,
          'changed_by': changedBy,
          'changed_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        _logger.e('Gagal menyimpan log perubahan pengaturan: $e');
      }
    }
  }
  
  /// Mendapatkan riwayat perubahan pengaturan penting
  Future<List<Map<String, dynamic>>> getConfigChangeLogs({
    String? key,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _supabaseClient.from('app_config_change_logs').select();
      
      // Filter berdasarkan key jika disediakan
      if (key != null) {
        query = query.eq('key', key);
      }
      
      // Filter berdasarkan tanggal jika disediakan
      if (startDate != null) {
        query = query.gte('changed_at', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('changed_at', endDate.toIso8601String());
      }
      
      // Urutkan berdasarkan waktu perubahan terbaru
      final orderedQuery = query.order('changed_at', ascending: false);
      
      // Batasi jumlah hasil
      final limitedQuery = orderedQuery.limit(limit);
      
      final result = await limitedQuery;
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      _logger.e('Gagal mendapatkan log perubahan pengaturan: $e');
      return [];
    }
  }
}
