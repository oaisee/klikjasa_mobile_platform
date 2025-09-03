import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source untuk operasi pencarian yang berkomunikasi dengan Supabase
class SearchRemoteDataSource {
  final SupabaseClient _supabaseClient;

  SearchRemoteDataSource(this._supabaseClient);

  /// Mencari layanan berdasarkan query
  Future<List<ServiceWithLocation>> searchServices(String query) async {
    try {
      final response = await _supabaseClient
          .from('services')
          .select('''
            *,
            provider:profiles!services_provider_id_fkey(
              id,
              full_name,
              avatar_url,
              phone_number,
              provinsi,
              kabupaten_kota,
              kecamatan,
              desa_kelurahan,
              address_detail,
              postal_code,
              created_at,
              updated_at,
              is_provider
            ),
            category:service_categories!inner(*)
          ''')
          .ilike('title', '%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ServiceWithLocation.fromMap(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal melakukan pencarian: $e');
    }
  }
}
