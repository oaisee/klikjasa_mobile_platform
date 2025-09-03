import 'dart:async';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/entities/provider_summary_data_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:klik_jasa/core/data/contracts/supabase_rpc_contract.dart';

abstract class ProviderSummaryRemoteDataSource {
  Future<ProviderSummaryDataEntity> getProviderSummaryData(String providerId);
  Stream<ProviderSummaryDataEntity> watchProviderSummaryData(String providerId);
}

class ProviderSummaryRemoteDataSourceImpl implements ProviderSummaryRemoteDataSource {
  final Logger _logger = Logger();
  final SupabaseRpcContract _rpcContract;
  final SupabaseClient _supabaseClient;

  ProviderSummaryRemoteDataSourceImpl(this._rpcContract, this._supabaseClient);

  @override
  Stream<ProviderSummaryDataEntity> watchProviderSummaryData(String providerId) {
    _logger.i('Memulai watchProviderSummaryData untuk provider_id: $providerId');
    
    if (providerId.isEmpty) {
      _logger.e('Error: Provider ID kosong di watchProviderSummaryData');
      // Buat stream yang langsung mengembalikan error
      return Stream.error(ServerException(message: 'Provider ID tidak boleh kosong.'));
    }
    
    StreamController<ProviderSummaryDataEntity>? controller;
    StreamSubscription? ordersSubscription;
    StreamSubscription? reviewsSubscription;
    StreamSubscription? servicesSubscription;

    Future<void> fetchData() async {
      if (controller?.isClosed ?? true) {
        _logger.w('Controller sudah ditutup, batal mengambil data');
        return;
      }
      try {
        _logger.d('Mengambil data terbaru untuk provider_id: $providerId');
        final data = await getProviderSummaryData(providerId);
        if (!(controller?.isClosed ?? true)) {
          _logger.d('Mengirim data baru ke stream: $data');
          controller?.add(data);
          _logger.d('Data berhasil dikirim ke stream');
        } else {
          _logger.w('Controller sudah ditutup, tidak bisa mengirim data');
        }
      } catch (e) {
        _logger.e('Error saat mengambil data', error: e, stackTrace: StackTrace.current);
        if (!(controller?.isClosed ?? true)) {
          _logger.e('Mengirim error ke stream', error: e);
          controller?.addError(e);
        } else {
          _logger.w('Controller sudah ditutup, tidak bisa mengirim error');
        }
      }
    }

    void startListening() {
      _logger.i('Memulai listening untuk perubahan data');
      // Initial fetch
      _logger.d('Mengambil data awal untuk provider_id: $providerId');
      fetchData();

      // Listen for changes in orders
      try {
        _logger.d('Memulai pemantauan tabel orders untuk provider_id: $providerId');
        final ordersStream = _supabaseClient
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('provider_id', providerId);
        ordersSubscription = ordersStream.listen(
          (data) {
            _logger.d('Perubahan terdeteksi pada tabel orders: ${data.length} item');
            fetchData();
          },
          onError: (error) {
            _logger.e('Error pada subscription orders', error: error);
            if (!(controller?.isClosed ?? true)) {
              _logger.e('Mengirim error subscription orders ke stream');
              controller?.addError(ServerException(message: 'Gagal memantau perubahan pesanan: ${error.toString()}'));
            }
          },
        );

        // Listen for changes in reviews
        _logger.d('Memulai pemantauan tabel reviews untuk provider_id: $providerId');
        final reviewsStream = _supabaseClient
            .from('reviews')
            .stream(primaryKey: ['id'])
            .eq('provider_id', providerId);
        reviewsSubscription = reviewsStream.listen(
          (data) {
            _logger.d('Perubahan terdeteksi pada tabel reviews: ${data.length} item');
            fetchData();
          },
          onError: (error) {
            _logger.e('Error pada subscription reviews', error: error);
            if (!(controller?.isClosed ?? true)) {
              _logger.e('Mengirim error subscription reviews ke stream');
              controller?.addError(ServerException(message: 'Gagal memantau perubahan ulasan: ${error.toString()}'));
            }
          },
        );
        
        // Listen for changes in services
        _logger.d('Memulai pemantauan tabel services untuk provider_id: $providerId');
        final servicesStream = _supabaseClient
            .from('services')
            .stream(primaryKey: ['id'])
            .eq('provider_id', providerId);
        servicesSubscription = servicesStream.listen(
          (data) {
            _logger.d('Perubahan terdeteksi pada tabel services: ${data.length} item');
            fetchData();
          },
          onError: (error) {
            _logger.e('Error pada subscription services', error: error);
            if (!(controller?.isClosed ?? true)) {
              _logger.e('Mengirim error subscription services ke stream');
              controller?.addError(ServerException(message: 'Gagal memantau perubahan layanan: ${error.toString()}'));
            }
          },
        );
      } catch (e) {
        _logger.e('Error saat setup stream', error: e, stackTrace: StackTrace.current);
        if (!(controller?.isClosed ?? true)) {
          controller?.addError(e);
        }
      }
    }

    void stopListening() {
      _logger.i('Menghentikan listening untuk provider_id: $providerId');
      
      if (ordersSubscription != null) {
        _logger.d('Membatalkan subscription orders');
        ordersSubscription?.cancel();
      }
      
      if (reviewsSubscription != null) {
        _logger.d('Membatalkan subscription reviews');
        reviewsSubscription?.cancel();
      }
      
      if (servicesSubscription != null) {
        _logger.d('Membatalkan subscription services');
        servicesSubscription?.cancel();
      }
      
      _logger.i('Semua subscription berhasil dibatalkan');
      ordersSubscription = null;
      reviewsSubscription = null;
      servicesSubscription = null;
    }

    controller = StreamController<ProviderSummaryDataEntity>(
      onListen: startListening,
      onPause: stopListening,
      onResume: startListening,
      onCancel: stopListening,
    );

    return controller.stream;
  }

  @override
  Future<ProviderSummaryDataEntity> getProviderSummaryData(String providerId) async {
    try {
      _logger.i('Mengambil data ringkasan untuk provider_id: $providerId');
      
      // Validasi providerId
      if (providerId.isEmpty) {
        _logger.e('Error: Provider ID kosong di getProviderSummaryData');
        throw ServerException(message: 'Provider ID tidak boleh kosong');
      }
      
      // Validasi format UUID
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false
      );
      if (!uuidRegex.hasMatch(providerId)) {
        _logger.e('Error: Provider ID tidak dalam format UUID yang valid: $providerId');
        throw ServerException(message: 'Format Provider ID tidak valid');
      }
      
      _logger.d('Memanggil RPC get_provider_summary dengan provider_id: $providerId');
      final response = await _rpcContract.callRpc(
        'get_provider_summary',
        params: {'p_provider_id': providerId},
      );
      
      if (response == null) {
        _logger.e('Error: Respons RPC null');
        throw ServerException(message: 'Gagal mendapatkan data ringkasan provider: respons kosong');
      }
      
      if (response is! Map<String, dynamic>) {
        _logger.e('Error: Format respons tidak valid: $response');
        throw ServerException(message: 'Format data ringkasan provider tidak valid');
      }
      
      _logger.d('Respons RPC diterima dengan ${response.length} field');
      
      // Log detail setiap field untuk debugging
      _logger.d('Detail respons RPC:');
      response.forEach((key, value) {
        _logger.t('   - $key: $value (${value?.runtimeType})');
      });
      
      final entity = ProviderSummaryDataEntity(
        providerId: providerId,
        pesananPerluTindakan: response['pesananPerluTindakan'] is num ? (response['pesananPerluTindakan'] as num).toInt() : 0,
        pendapatanBulanIni: response['pendapatanBulanIni'] is num ? (response['pendapatanBulanIni'] as num).toDouble() : 0.0,
        ratingRataRata: response['ratingRataRata'] is num ? (response['ratingRataRata'] as num).toDouble() : 0.0,
        pesananAktif: response['pesananAktif'] is num ? (response['pesananAktif'] as num).toInt() : 0,
        pesananSelesai30Hari: response['pesananSelesai30Hari'] is num ? (response['pesananSelesai30Hari'] as num).toInt() : 0,
        ulasanBaru: response['ulasanBaru'] is num ? (response['ulasanBaru'] as num).toInt() : 0,
        layananAktif: response['layananAktif'] is num ? (response['layananAktif'] as num).toInt() : 0,
      );
      
      _logger.i('Entity ProviderSummaryDataEntity berhasil dibuat dengan providerId: $providerId');
      return entity;
    } on PostgrestException catch (e) {
      // Tangani error spesifik dari Supabase/PostgREST
      _logger.e('PostgrestException: (${e.code}): ${e.message}', error: e, stackTrace: StackTrace.current);
      throw ServerException(message: 'Supabase error (${e.code}): ${e.message}');
    } catch (e) {
      // Tangani error lainnya
      _logger.e('Error saat mengambil data ringkasan', error: e, stackTrace: StackTrace.current);
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(message: 'Gagal mendapatkan data ringkasan provider: ${e.toString()}');
    }
  }
}