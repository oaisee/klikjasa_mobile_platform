import 'package:klik_jasa/core/data/contracts/supabase_rpc_contract.dart';
import 'package:klik_jasa/core/data/datasources/supabase_data_source.dart';
import 'package:logger/logger.dart';

/// Adapter untuk memanggil fungsi RPC Supabase
/// 
/// Kelas ini mengimplementasikan SupabaseRpcContract dan mewarisi SupabaseDataSource
/// untuk memanfaatkan fungsionalitas penanganan error yang konsisten
class SupabaseRpcAdapter extends SupabaseDataSource implements SupabaseRpcContract {
  final Logger _logger = Logger();

  SupabaseRpcAdapter({required super.supabaseClient});

  @override
  Future<dynamic> callRpc(String functionName, {Map<String, dynamic>? params}) async {
    try {
      _logger.i('📊 Memanggil RPC $functionName dengan params: $params');
      
      // Validasi parameter UUID jika ada
      if (params != null) {
        for (var entry in params.entries) {
          if (entry.key.toLowerCase().contains('id') && entry.value is String) {
            final idValue = entry.value as String;
            if (idValue.isEmpty) {
              _logger.w('🚨 Parameter ${entry.key} tidak boleh kosong');
              throw ArgumentError('Parameter ${entry.key} tidak boleh kosong');
            }
            
            // Validasi format UUID jika terlihat seperti UUID
            if (idValue.contains('-') && idValue.length > 30) {
              final uuidRegex = RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
                caseSensitive: false
              );
              if (!uuidRegex.hasMatch(idValue)) {
                _logger.w('🚨 Parameter ${entry.key} tidak dalam format UUID yang valid: $idValue');
                throw ArgumentError('Parameter ${entry.key} tidak dalam format UUID yang valid');
              } else {
                _logger.i('✅ Parameter ${entry.key} valid: $idValue');
              }
            }
          }
        }
      } else {
        _logger.w('⚠️ Tidak ada parameter yang diberikan untuk RPC $functionName');
      }
      
      _logger.i('🔄 Menjalankan RPC $functionName...');
      // Tambahkan timeout 10 detik untuk mencegah permintaan menggantung terlalu lama
      final result = await handleSupabaseOperation(
        operation: () => supabaseClient.rpc(functionName, params: params)
            .timeout(const Duration(seconds: 10)),
        context: 'memanggil fungsi RPC: $functionName',
      );
      
      if (result == null) {
        _logger.w('⚠️ RPC $functionName mengembalikan null');
      } else {
        _logger.i('✅ RPC $functionName berhasil dipanggil');
        _logger.d('📊 Hasil: ${result.toString().substring(0, result.toString().length > 100 ? 100 : result.toString().length)}${result.toString().length > 100 ? "..." : ""}');
      }
      
      return result;
    } catch (e) {
      _logger.e('🚨 Error saat memanggil RPC $functionName', error: e);
      rethrow;
    }
  }
}
