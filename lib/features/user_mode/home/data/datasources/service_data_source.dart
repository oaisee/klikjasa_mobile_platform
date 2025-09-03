import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ServiceDataSource {
  Future<ServiceWithLocation> getServiceById(int serviceId);
  Future<List<ServiceWithLocation>> getServicesByLocation({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
    int limit = 10,
    int offset = 0,
  });

  Future<List<ServiceWithLocation>> getPromotedServices({
    int limit = 10,
    int offset = 0,
  });

  Future<List<ServiceWithLocation>> getServicesByHighestRating({
    int limit = 10,
    int offset = 0,
  });
  
  // Metode baru untuk subscription realtime
  Stream<List<ServiceWithLocation>> getServicesByLocationStream({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
  });
  
  Stream<List<ServiceWithLocation>> getPromotedServicesStream();
  
  Stream<List<ServiceWithLocation>> getServicesByHighestRatingStream();
  
  // Metode untuk cleanup subscription
  void disposeSubscriptions();
}

class ServiceDataSourceImpl implements ServiceDataSource {
  final SupabaseClient supabaseClient;
  
  // Stream controller untuk tiap tipe data
  final StreamController<List<ServiceWithLocation>> _locationServicesController = 
      StreamController<List<ServiceWithLocation>>.broadcast();
  final StreamController<List<ServiceWithLocation>> _promotedServicesController = 
      StreamController<List<ServiceWithLocation>>.broadcast();
  final StreamController<List<ServiceWithLocation>> _highestRatedServicesController = 
      StreamController<List<ServiceWithLocation>>.broadcast();
  
  // Menyimpan subscription untuk bisa dibersihkan nanti
  final List<StreamSubscription> _subscriptions = [];

  ServiceDataSourceImpl({required this.supabaseClient}) {
    _initializeRealtimeSubscriptions();
  }
  
  void _initializeRealtimeSubscriptions() {
    try {
      // Subscribe ke perubahan tabel services
      final subscription = supabaseClient
          .from('services')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> data) {
        // Ketika ada perubahan data, refresh semua stream controller
        _refreshAllStreams();
      });
      
      _subscriptions.add(subscription);
    } catch (e) {
      debugPrint('Error initializing realtime subscriptions: $e');
    }
  }
  
  // Memperbarui semua stream ketika ada perubahan data
  Future<void> _refreshAllStreams() async {
    try {
      // Menggunakan parameter kosong untuk mendapatkan data terbaru
      await _refreshLocationServicesStream();
      await _refreshPromotedServicesStream();
      await _refreshHighestRatedServicesStream();
    } catch (e) {
      debugPrint('Error refreshing streams: $e');
    }
  }
  
  Future<void> _refreshLocationServicesStream({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
  }) async {
    try {
      final services = await getServicesByLocation(
        userProvinsi: userProvinsi,
        userKabupatenKota: userKabupatenKota,
        userKecamatan: userKecamatan,
        userDesaKelurahan: userDesaKelurahan,
        limit: 20, // Mengambil data lebih banyak untuk stream
      );
      
      if (!_locationServicesController.isClosed) {
        _locationServicesController.add(services);
      }
    } catch (e) {
      if (!_locationServicesController.isClosed) {
        _locationServicesController.addError(e);
      }
    }
  }
  
  Future<void> _refreshPromotedServicesStream() async {
    try {
      final services = await getPromotedServices(limit: 20);
      
      if (!_promotedServicesController.isClosed) {
        _promotedServicesController.add(services);
      }
    } catch (e) {
      if (!_promotedServicesController.isClosed) {
        _promotedServicesController.addError(e);
      }
    }
  }
  
  Future<void> _refreshHighestRatedServicesStream() async {
    try {
      final services = await getServicesByHighestRating(limit: 20);
      
      if (!_highestRatedServicesController.isClosed) {
        _highestRatedServicesController.add(services);
      }
    } catch (e) {
      if (!_highestRatedServicesController.isClosed) {
        _highestRatedServicesController.addError(e);
      }
    }
  }
  
  @override
  void disposeSubscriptions() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    _locationServicesController.close();
    _promotedServicesController.close();
    _highestRatedServicesController.close();
  }
  
  @override
  Stream<List<ServiceWithLocation>> getServicesByLocationStream({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
  }) {
    // Refresh data saat stream pertama kali diakses
    _refreshLocationServicesStream(
      userProvinsi: userProvinsi,
      userKabupatenKota: userKabupatenKota,
      userKecamatan: userKecamatan,
      userDesaKelurahan: userDesaKelurahan,
    );
    
    return _locationServicesController.stream;
  }
  
  @override
  Stream<List<ServiceWithLocation>> getPromotedServicesStream() {
    _refreshPromotedServicesStream();
    return _promotedServicesController.stream;
  }
  
  @override
  Stream<List<ServiceWithLocation>> getServicesByHighestRatingStream() {
    _refreshHighestRatedServicesStream();
    return _highestRatedServicesController.stream;
  }

  @override
  Future<ServiceWithLocation> getServiceById(int serviceId) async {
    try {
      final response = await supabaseClient
          .from('services')
          .select('*, profiles(*)')
          .eq('id', serviceId)
          .single();

      return ServiceWithLocation.fromMap(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Layanan dengan ID $serviceId tidak ditemukan');
      }
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      debugPrint('Unexpected error in getServiceById: $e');
      throw ServerException(message: 'Terjadi kesalahan tak terduga: ${e.toString()}');
    }
  }

  @override
  Future<List<ServiceWithLocation>> getServicesByLocation({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      var query = supabaseClient
          .from('services')
          .select('*, profiles!inner(*)');

      if (userProvinsi != null) query = query.eq('profiles.provinsi', userProvinsi);
      if (userKabupatenKota != null) query = query.eq('profiles.kabupaten_kota', userKabupatenKota);
      if (userKecamatan != null) query = query.eq('profiles.kecamatan', userKecamatan);
      if (userDesaKelurahan != null) query = query.eq('profiles.desa_kelurahan', userDesaKelurahan);

      final response = await query.limit(limit).range(offset, offset + limit - 1);

      return response.map((item) => ServiceWithLocation.fromMap(item)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      debugPrint('Unexpected error in getServicesByLocation: $e');
      throw ServerException(message: 'Terjadi kesalahan tak terduga: ${e.toString()}');
    }
  }

  @override
  Future<List<ServiceWithLocation>> getPromotedServices({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await supabaseClient
          .from('services')
          .select('*, profiles(*)')
          .eq('is_promoted', true)
          .limit(limit)
          .range(offset, offset + limit - 1);
      return response.map((item) => ServiceWithLocation.fromMap(item)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      debugPrint('Unexpected error in getPromotedServices: $e');
      throw ServerException(message: 'Terjadi kesalahan tak terduga: ${e.toString()}');
    }
  }

  @override
  Future<List<ServiceWithLocation>> getServicesByHighestRating({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await supabaseClient
          .from('services')
          .select('*, profiles(*)')
          .order('average_rating', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);
      return response.map((item) => ServiceWithLocation.fromMap(item)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      debugPrint('Unexpected error in getServicesByHighestRating: $e');
      throw ServerException(message: 'Terjadi kesalahan tak terduga: ${e.toString()}');
    }
  }
}
