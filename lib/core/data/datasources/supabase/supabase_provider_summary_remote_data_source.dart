import 'dart:async';
import 'dart:developer' as developer;

import 'package:klik_jasa/core/data/contracts/supabase_rpc_contract.dart';
import 'package:klik_jasa/core/data/datasources/supabase_data_source.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/data/datasources/provider_summary_remote_data_source.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/entities/provider_summary_data_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementasi ProviderSummaryRemoteDataSource menggunakan Supabase RPC
/// 
/// Kelas ini menggunakan SupabaseRpcContract untuk memanggil fungsi RPC
/// yang mengembalikan data ringkasan provider

class SupabaseProviderSummaryRemoteDataSource extends SupabaseDataSource implements ProviderSummaryRemoteDataSource {
  final SupabaseRpcContract _rpcContract;

  SupabaseProviderSummaryRemoteDataSource(this._rpcContract, {required super.supabaseClient});

  @override
  Future<ProviderSummaryDataEntity> getProviderSummaryData(String providerId) async {
    if (providerId.isEmpty) {
      developer.log('🚨 ERROR: Provider ID kosong', name: 'ProviderSummary');
      throw ArgumentError('Provider ID tidak boleh kosong.');
    }

    developer.log('📊 Memanggil RPC get_provider_summary untuk provider: $providerId', name: 'ProviderSummary');
    try {
      final dynamic response = await _rpcContract.callRpc(
        'get_provider_summary',
        params: {'p_provider_id': providerId},
      );

      developer.log('📊 Respons RPC diterima: ${response.toString()}', name: 'ProviderSummary');

      if (response == null) {
        developer.log('🚨 ERROR: Respons RPC null', name: 'ProviderSummary');
        throw Exception('Gagal mendapatkan data ringkasan penyedia: respons null dari RPC.');
      }

      // Pastikan respons adalah Map, karena RPC mengembalikan JSONB
      if (response is! Map<String, dynamic>) {
        developer.log('🚨 ERROR: Format respons tidak valid: ${response.runtimeType}', name: 'ProviderSummary');
        throw Exception('Format respons tidak valid dari RPC get_provider_summary.');
      }

      // Log semua field dari respons
      developer.log('📊 Detail respons RPC:', name: 'ProviderSummary');
      response.forEach((key, value) {
        developer.log('   - $key: $value (${value?.runtimeType})', name: 'ProviderSummary');
      });

      final entity = ProviderSummaryDataEntity(
        pesananPerluTindakan: response['pesananPerluTindakan'] is num ? (response['pesananPerluTindakan'] as num).toInt() : 0,
        pendapatanBulanIni: response['pendapatanBulanIni'] is num ? (response['pendapatanBulanIni'] as num).toDouble() : 0.0,
        ratingRataRata: response['ratingRataRata'] is num ? (response['ratingRataRata'] as num).toDouble() : 0.0,
        pesananAktif: response['pesananAktif'] is num ? (response['pesananAktif'] as num).toInt() : 0,
        pesananSelesai30Hari: response['pesananSelesai30Hari'] is num ? (response['pesananSelesai30Hari'] as num).toInt() : 0,
        ulasanBaru: response['ulasanBaru'] is num ? (response['ulasanBaru'] as num).toInt() : 0,
        layananAktif: response['layananAktif'] is num ? (response['layananAktif'] as num).toInt() : 0,
      );
      
      developer.log('📊 Entity berhasil dibuat: $entity', name: 'ProviderSummary');
      return entity;
    } on PostgrestException catch (e) {
      // Tangani error spesifik dari Supabase/PostgREST
      developer.log('🚨 PostgrestException: (${e.code}): ${e.message}', name: 'ProviderSummary');
      throw Exception('Supabase error (${e.code}): ${e.message}');
    } catch (e) {
      // Tangani error lainnya
      developer.log('🚨 Exception: ${e.toString()}', name: 'ProviderSummary');
      throw Exception('Gagal memuat data ringkasan penyedia: ${e.toString()}');
    }
  }

  @override
  Stream<ProviderSummaryDataEntity> watchProviderSummaryData(String providerId) {
    StreamController<ProviderSummaryDataEntity>? controller;
    StreamSubscription? ordersSubscription;
    StreamSubscription? reviewsSubscription;
    StreamSubscription? servicesSubscription;
    
    Future<void> fetchData() async {
      developer.log('🔄 fetchData dipanggil untuk provider: $providerId', name: 'ProviderSummary');
      if (controller?.isClosed ?? true) {
        developer.log('⚠️ Controller sudah ditutup, batal mengambil data', name: 'ProviderSummary');
        return;
      }
      try {
        developer.log('🔄 Memanggil getProviderSummaryData', name: 'ProviderSummary');
        final data = await getProviderSummaryData(providerId);
        developer.log('✅ Data berhasil diambil: $data', name: 'ProviderSummary');
        
        if (!(controller?.isClosed ?? true)) {
          developer.log('📤 Mengirim data ke stream', name: 'ProviderSummary');
          controller?.add(data);
          developer.log('✅ Data berhasil dikirim ke stream', name: 'ProviderSummary');
        } else {
          developer.log('⚠️ Controller sudah ditutup, tidak bisa mengirim data', name: 'ProviderSummary');
        }
      } catch (e) {
        developer.log('🚨 Error saat fetchData: ${e.toString()}', name: 'ProviderSummary');
        if (!(controller?.isClosed ?? true)) {
          developer.log('📤 Mengirim error ke stream', name: 'ProviderSummary');
          controller?.addError(e);
        } else {
          developer.log('⚠️ Controller sudah ditutup, tidak bisa mengirim error', name: 'ProviderSummary');
        }
      }
    }

    void startListening() {
      // Initial fetch
      fetchData();

      // Listen for changes in orders
      final ordersStream = supabaseClient
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('provider_id', providerId);
      ordersSubscription = ordersStream.listen((_) => fetchData());

      // Listen for changes in reviews
      final reviewsStream = supabaseClient
          .from('reviews')
          .stream(primaryKey: ['id'])
          .eq('provider_id', providerId);
      reviewsSubscription = reviewsStream.listen((_) => fetchData());

      // Listen for changes in services
      final servicesStream = supabaseClient
          .from('services')
          .stream(primaryKey: ['id'])
          .eq('provider_id', providerId);
      servicesSubscription = servicesStream.listen((_) => fetchData());
    }

    void stopListening() {
      ordersSubscription?.cancel();
      reviewsSubscription?.cancel();
      servicesSubscription?.cancel();
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
}
