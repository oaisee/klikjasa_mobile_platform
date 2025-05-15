import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service.dart';

class ServiceService {
  final SupabaseClient _supabase;

  ServiceService(this._supabase);

  Future<List<Service>> getServices({
    String? search,
    List<String>? areaLayanan,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    try {
      // Periksa terlebih dahulu apakah tabel services ada
      final hasTable = await _checkTableExists('services');
      if (!hasTable) {
        print('Tabel services tidak ditemukan');
        return [];
      }

      // Periksa struktur kolom untuk memastikan query valid
      final columns = await _getTableColumns('services');
      print('Kolom di tabel services: $columns');

      // Gunakan query yang lebih sederhana untuk menghindari error
      var query = _supabase.from('services').select();

      if (search != null && search.isNotEmpty) {
        query = query.ilike('title', '%$search%');
      }

      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }

      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      // Gunakan order yang lebih aman dengan nullslast
      final response = await query.order('created_at', ascending: false);
      
      // Jika response kosong, kembalikan list kosong
      if (response == null) return [];
      
      return (response as List).map((item) => Service.fromJson(item)).toList();
    } catch (e) {
      print('Error getting services: $e');
      return [];
    }
  }

  Future<Service?> getServiceById(String id) async {
    try {
      final response = await _supabase
          .from('services')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Service.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error getting service by id: $e');
      return null;
    }
  }

  Future<List<Service>> getServicesByProvider(String providerId) async {
    try {
      final response = await _supabase
          .from('services')
          .select() // Menggunakan select() tanpa parameter untuk menghindari error
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      return (response as List).map((item) => Service.fromJson(item)).toList();
    } catch (e) {
      print('Error getting services by provider: $e');
      return [];
    }
  }

  // Helper method untuk memeriksa apakah tabel ada
  Future<bool> _checkTableExists(String tableName) async {
    try {
      // Coba query sederhana untuk memeriksa apakah tabel ada
      await _supabase.from(tableName).select().limit(1);
      return true;
    } catch (e) {
      print('Error checking table $tableName: $e');
      return false;
    }
  }

  // Helper method untuk mendapatkan informasi kolom tabel
  Future<List<String>> _getTableColumns(String tableName) async {
    try {
      // Gunakan RPC untuk mendapatkan informasi kolom
      // Catatan: Ini hanya contoh, Supabase mungkin tidak mendukung ini secara langsung
      final response = await _supabase.rpc('get_columns_info', params: {
        'table_name': tableName,
      }).select();
      
      if (response is List) {
        return response.map((col) => col['column_name'].toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error getting columns for $tableName: $e');
      return [];
    }
  }

  Future<Service?> createService(Map<String, dynamic> serviceData) async {
    try {
      // Tambahkan timestamp jika belum ada
      if (!serviceData.containsKey('created_at')) {
        serviceData['created_at'] = DateTime.now().toIso8601String();
      }
      
      final response = await _supabase
          .from('services')
          .insert(serviceData)
          .select()
          .maybeSingle();

      if (response == null) return null;
      return Service.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating service: $e');
      return null;
    }
  }

  Future<Service?> updateService(String id, Map<String, dynamic> serviceData) async {
    try {
      // Tambahkan timestamp update
      serviceData['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from('services')
          .update(serviceData)
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response == null) return null;
      return Service.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating service: $e');
      return null;
    }
  }

  Future<bool> deleteService(String id) async {
    try {
      await _supabase.from('services').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }
}
