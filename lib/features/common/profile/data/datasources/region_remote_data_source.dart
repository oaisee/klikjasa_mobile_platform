// lib/features/common/profile/data/datasources/region_remote_data_source.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/provinsi.dart';
import '../../domain/entities/kabupaten_kota.dart';
import '../../domain/entities/kecamatan.dart';
import '../../domain/entities/desa_kelurahan.dart';
import '../../../../../core/error/exceptions.dart'; // Ditambahkan untuk ServerException
import 'package:logger/logger.dart'; // Ditambahkan untuk Logger

// Abstract class sebagai kontrak
abstract class RegionRemoteDataSource {
  Future<List<Provinsi>> getProvinces();
  Future<List<KabupatenKota>> getKabupatenKota(String provinceId);
  Future<List<Kecamatan>> getKecamatan(String kabupatenKotaId);
  Future<List<DesaKelurahan>> getDesaKelurahan(String kecamatanId);
}

// Implementasi
class RegionRemoteDataSourceImpl implements RegionRemoteDataSource {
  final SupabaseClient supabaseClient;
  final Logger _logger = Logger();

  RegionRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<Provinsi>> getProvinces() async {
    try {
      // Mengambil semua data dari tabel 'provinsi'
      // Mengurutkan berdasarkan nama untuk tampilan yang lebih baik di dropdown
      final List<Map<String, dynamic>> response = await supabaseClient
          .from('provinsi')
          .select()
          .order('nama', ascending: true);

      // Tambahkan log di sini untuk melihat respons mentah
      _logger.d('RESPONS MENTAH SUPABASE UNTUK PROVINSI: $response');

      final provinces = response
          .map((data) => Provinsi.fromJson(data)) // Cast dihilangkan
          .toList();
      return provinces;
    } catch (e) {
      // Tangani error, misalnya log atau throw custom exception
      _logger.e('Error fetching provinces', error: e, stackTrace: StackTrace.current);
      throw ServerException(message: 'Failed to load provinces: ${e.toString()}'); // Menggunakan ServerException
    }
  }

  @override
  Future<List<KabupatenKota>> getKabupatenKota(String provinceId) async {
    try {
      final List<Map<String, dynamic>> response = await supabaseClient
          .from('kabupaten_kota') // Sesuaikan nama tabel jika berbeda
          .select()
          .eq('provinsi_id', provinceId) // Filter berdasarkan provinsi_id
          .order('nama', ascending: true);

      // Tambahkan log di sini untuk melihat respons mentah
      _logger.d('RESPONS MENTAH SUPABASE UNTUK KABUPATEN/KOTA (provinsi_id: $provinceId): $response');
      _logger.d('JUMLAH KABUPATEN/KOTA DITERIMA: ${response.length}');

      final kabupatenKotaList = response
          .map((data) => KabupatenKota.fromJson(data))
          .toList();
      return kabupatenKotaList;
    } catch (e) {
      _logger.e('Error fetching kabupaten_kota', error: e, stackTrace: StackTrace.current);
      throw ServerException(message: 'Failed to load kabupaten_kota: ${e.toString()}');
    }
  }

  @override
  Future<List<Kecamatan>> getKecamatan(String kabupatenKotaId) async {
    try {
      final List<Map<String, dynamic>> response = await supabaseClient
          .from('kecamatan') // Sesuaikan nama tabel jika berbeda
          .select()
          .eq('kabupaten_kota_id', kabupatenKotaId) // Filter berdasarkan kabupaten_kota_id
          .order('nama', ascending: true);

      // Tambahkan log di sini untuk melihat respons mentah
      _logger.d('RESPONS MENTAH SUPABASE UNTUK KECAMATAN (kabupaten_kota_id: $kabupatenKotaId): $response');
      _logger.d('JUMLAH KECAMATAN DITERIMA: ${response.length}');

      final kecamatanList = response
          .map((data) => Kecamatan.fromJson(data))
          .toList();
      return kecamatanList;
    } catch (e) {
      _logger.e('Error fetching kecamatan', error: e, stackTrace: StackTrace.current);
      throw ServerException(message: 'Failed to load kecamatan: ${e.toString()}');
    }
  }

  @override
  Future<List<DesaKelurahan>> getDesaKelurahan(String kecamatanId) async {
    try {
      final List<Map<String, dynamic>> response = await supabaseClient
          .from('kelurahan_desa') // Sesuaikan nama tabel jika berbeda
          .select()
          .eq('kecamatan_id', kecamatanId) // Filter berdasarkan kecamatan_id
          .order('nama', ascending: true);

      // Tambahkan log di sini untuk melihat respons mentah
      // Logger untuk debugging - hapus di production
      _logger.d('RESPONS MENTAH SUPABASE UNTUK DESA/KELURAHAN (kecamatan_id: $kecamatanId): $response');
      _logger.d('JUMLAH DESA/KELURAHAN DITERIMA: ${response.length}');

      final desaKelurahanList = response
          .map((data) => DesaKelurahan.fromJson(data))
          .toList();
      return desaKelurahanList;
    } catch (e) {
      _logger.e('Error fetching desa_kelurahan', error: e, stackTrace: StackTrace.current);
      throw ServerException(message: 'Failed to load desa_kelurahan: ${e.toString()}');
    }
  }
}
