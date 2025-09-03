import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/recommended_services_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:async';

/// Cubit untuk mengelola state layanan yang direkomendasikan
class RecommendedServicesCubit extends Cubit<RecommendedServicesState> {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  RecommendedServicesCubit() : super(RecommendedServicesInitial());
  
  /// Mengambil data layanan yang direkomendasikan berdasarkan lokasi user
  Future<void> fetchRecommendedServicesByLocation() async {
    try {
      // Ambil data lokasi user dari profil
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        // Jika tidak ada user yang login, ambil rekomendasi umum
        return fetchRecommendedServices();
      }
      
      final profileData = await _supabase
          .from('profiles')
          .select('provinsi, kabupaten_kota')
          .eq('id', userId)
          .maybeSingle();
      
      if (profileData != null) {
        final String? provinsi = profileData['provinsi'] as String?;
        final String? kabupatenKota = profileData['kabupaten_kota'] as String?;
        
        // Ambil rekomendasi berdasarkan lokasi dengan fallback ke provinsi
        await fetchRecommendedServicesWithLocationFallback(
          userProvinsi: provinsi,
          userKabupatenKota: kabupatenKota,
        );
      } else {
        // Jika tidak ada data profil, ambil rekomendasi umum
        await fetchRecommendedServices();
      }
    } catch (e) {
      _logger.e('Error fetching user location for recommendations: $e');
      // Fallback ke rekomendasi umum
      await fetchRecommendedServices();
    }
  }

  /// Mengambil data layanan yang direkomendasikan dengan fallback ke provinsi
  /// jika tidak ada layanan di kabupaten
  Future<void> fetchRecommendedServicesWithLocationFallback({
    String? userKabupatenKota, 
    String? userProvinsi
  }) async {
    try {
      emit(RecommendedServicesLoading());

      // Coba ambil layanan berdasarkan kabupaten terlebih dahulu
      if (userKabupatenKota != null && userKabupatenKota.isNotEmpty) {
        final kabupatenServices = await _fetchServicesByLocation(
          locationField: 'profiles.kabupaten_kota',
          locationValue: userKabupatenKota,
        );

        // Jika ada layanan di kabupaten, gunakan itu
        if (kabupatenServices.isNotEmpty) {
          emit(RecommendedServicesLoaded(services: kabupatenServices));
          return;
        }
      }

      // Jika tidak ada layanan di kabupaten atau kabupaten kosong,
      // coba ambil berdasarkan provinsi
      if (userProvinsi != null && userProvinsi.isNotEmpty) {
        final provinsiServices = await _fetchServicesByLocation(
          locationField: 'profiles.provinsi',
          locationValue: userProvinsi,
        );

        emit(RecommendedServicesLoaded(
          services: provinsiServices,
          showEmptyLocationMessage: userKabupatenKota != null && userKabupatenKota.isNotEmpty,
        ));
        return;
      }

      // Jika tidak ada lokasi yang tersedia, ambil rekomendasi umum
      await fetchRecommendedServices();
    } catch (e) {
      _logger.e('Error fetching recommended services with fallback: $e');
      emit(RecommendedServicesError(message: e.toString()));
    }
  }

  /// Mengambil data layanan berdasarkan lokasi spesifik
  Future<List<Map<String, dynamic>>> _fetchServicesByLocation({
    required String locationField,
    required String locationValue,
  }) async {
    final response = await _supabase
        .from('services')
        .select('''
          *,
          profiles!services_provider_id_fkey(full_name, avatar_url, provinsi, kabupaten_kota),
          service_categories!services_category_id_fkey(name)
        ''')
        .eq('is_active', true)
        .eq(locationField, locationValue)
        .order('average_rating', ascending: false)
        .limit(10);

    // Transformasi data untuk memudahkan penggunaan di UI
    final List<Map<String, dynamic>> services = [];
    for (final item in response) {
      final service = Map<String, dynamic>.from(item);
      
      // Tambahkan nama provider dari relasi
      if (service['profiles'] != null) {
        service['provider_name'] = service['profiles']['full_name'];
        service['provider_avatar'] = service['profiles']['avatar_url'];
      }
      
      // Tambahkan nama kategori dari relasi
      if (service['service_categories'] != null) {
        service['category_name'] = service['service_categories']['name'];
      }
      
      services.add(service);
    }

    return services;
  }

  /// Mengambil data layanan yang direkomendasikan tanpa filter lokasi
  /// atau dengan filter lokasi jika parameter disediakan
  Future<void> fetchRecommendedServices({String? userKabupatenKota, String? userProvinsi}) async {
    try {
      emit(RecommendedServicesLoading());

      // Mengambil data layanan yang direkomendasikan
      var query = _supabase
          .from('services')
          .select('''
            *,
            profiles!services_provider_id_fkey(full_name, avatar_url, provinsi, kabupaten_kota),
            service_categories!services_category_id_fkey(name)
          ''')
          .eq('is_active', true);
      
      // Jika kabupaten tersedia, filter berdasarkan kabupaten
      if (userKabupatenKota != null && userKabupatenKota.isNotEmpty) {
        // Ambil layanan dari provider di kabupaten yang sama
        query = query.eq('profiles.kabupaten_kota', userKabupatenKota);
      } 
      // Jika hanya provinsi tersedia, filter berdasarkan provinsi
      else if (userProvinsi != null && userProvinsi.isNotEmpty) {
        // Ambil layanan dari provider di provinsi yang sama
        query = query.eq('profiles.provinsi', userProvinsi);
      }
      
      // Urutkan berdasarkan rating dan batasi jumlah hasil
      final response = await query
          .order('average_rating', ascending: false)
          .limit(10);

      // Transformasi data untuk memudahkan penggunaan di UI
      final List<Map<String, dynamic>> services = [];
      for (final item in response) {
        final service = Map<String, dynamic>.from(item);
        
        // Tambahkan nama provider dari relasi
        if (service['profiles'] != null) {
          service['provider_name'] = service['profiles']['full_name'];
          service['provider_avatar'] = service['profiles']['avatar_url'];
        }
        
        // Tambahkan nama kategori dari relasi
        if (service['service_categories'] != null) {
          service['category_name'] = service['service_categories']['name'];
        }
        
        services.add(service);
      }

      emit(RecommendedServicesLoaded(services: services));
    } catch (e) {
      _logger.e('Error fetching recommended services: $e');
      emit(RecommendedServicesError(message: e.toString()));
    }
  }
}
