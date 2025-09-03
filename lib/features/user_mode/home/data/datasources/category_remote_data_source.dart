import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service_category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interface untuk remote data source kategori layanan
abstract class CategoryRemoteDataSource {
  /// Mengambil semua kategori layanan yang aktif dari Supabase
  Future<List<ServiceCategory>> getActiveCategories();
  
  /// Mengambil kategori layanan berdasarkan ID dari Supabase
  Future<ServiceCategory> getCategoryById(int id);
}

/// Implementasi remote data source kategori layanan menggunakan Supabase
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final SupabaseClient supabaseClient;

  CategoryRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<ServiceCategory>> getActiveCategories() async {
    try {
      // Debug: Cetak query yang dijalankan
      logger.i('Mengambil kategori aktif dari Supabase');
      
      final response = await supabaseClient
          .from('service_categories')
          .select()
          .eq('is_active', true)
          .order('name');

      // Debug: Cetak jumlah kategori yang ditemukan
      logger.i('Ditemukan ${response.length} kategori aktif');
      
      // Debug: Cetak data mentah untuk kategori pertama (jika ada)
      if (response.isNotEmpty) {
        logger.d('Contoh data kategori pertama: ${response[0]}');
        logger.d('icon_name pada kategori pertama: ${response[0]['icon_name']}');
      }
      
      return (response as List)
          .map((item) => ServiceCategory.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e('Error saat mengambil kategori: $e');
      throw ServerException(message: 'Gagal mengambil data kategori: ${e.toString()}');
    }
  }

  @override
  Future<ServiceCategory> getCategoryById(int id) async {
    try {
      // Debug: Cetak query yang dijalankan
      logger.i('Mengambil kategori dengan ID: $id');
      
      final response = await supabaseClient
          .from('service_categories')
          .select()
          .eq('id', id)
          .single();

      // Debug: Cetak data mentah kategori
      logger.d('Data kategori: $response');
      logger.d('icon_name pada kategori: ${response['icon_name']}');
      
      return ServiceCategory.fromMap(response);
    } catch (e) {
      throw ServerException(message: 'Gagal mengambil data kategori: ${e.toString()}');
    }
  }
}
