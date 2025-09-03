/// Kontrak untuk memanggil fungsi RPC Supabase
/// 
/// Interface ini memisahkan logika bisnis dari implementasi spesifik Supabase
abstract class SupabaseRpcContract {
  /// Memanggil fungsi RPC Supabase dengan nama dan parameter opsional
  Future<dynamic> callRpc(String functionName, {Map<String, dynamic>? params});
}
