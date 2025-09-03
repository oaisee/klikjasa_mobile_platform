import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/entities/store_settings_entity.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class StoreSettingsRepositoryImpl implements StoreSettingsRepository {
  final SupabaseClient supabase;

  StoreSettingsRepositoryImpl({required this.supabase});

  @override
  Future<Either<Failure, StoreSettingsEntity>> getStoreSettings(String providerId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('provider_details, address, latitude, longitude')
          .eq('id', providerId)
          .single();

      Map<String, dynamic> providerDetails = response['provider_details'] ?? {};
      
      // Jika provider_details kosong atau tidak memiliki pengaturan toko,
      // gunakan pengaturan default
      if (providerDetails.isEmpty || providerDetails['store_settings'] == null) {
        final defaultSettings = StoreSettingsEntity.defaultSettings().copyWith(
          storeAddress: response['address'] ?? '',
          latitude: response['latitude']?.toDouble(),
          longitude: response['longitude']?.toDouble(),
        );
        
        // Simpan pengaturan default ke database
        await _saveStoreSettingsToDatabase(providerId, defaultSettings);
        
        return Right(defaultSettings);
      }

      // Jika provider_details memiliki pengaturan toko, gunakan pengaturan tersebut
      final storeSettings = StoreSettingsEntity.fromJson(providerDetails['store_settings']);
      
      // Update alamat dan koordinat dari profil
      return Right(storeSettings.copyWith(
        storeAddress: response['address'] ?? storeSettings.storeAddress,
        latitude: response['latitude']?.toDouble() ?? storeSettings.latitude,
        longitude: response['longitude']?.toDouble() ?? storeSettings.longitude,
      ));
    } catch (e) {
      developer.log('Error getting store settings: $e');
      return Left(ServerFailure(message: 'Gagal memuat pengaturan toko: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateStoreSettings(String providerId, StoreSettingsEntity settings) async {
    try {
      await _saveStoreSettingsToDatabase(providerId, settings);
      return const Right(true);
    } catch (e) {
      developer.log('Error updating store settings: $e');
      return Left(ServerFailure(message: 'Gagal menyimpan pengaturan toko: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateStoreStatus(String providerId, bool isActive) async {
    try {
      // Ambil pengaturan toko saat ini
      final settingsResult = await getStoreSettings(providerId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (currentSettings) async {
          // Update status toko
          final updatedSettings = currentSettings.copyWith(isStoreActive: isActive);
          
          // Simpan pengaturan yang diperbarui
          return updateStoreSettings(providerId, updatedSettings);
        }
      );
    } catch (e) {
      developer.log('Error updating store status: $e');
      return Left(ServerFailure(message: 'Gagal memperbarui status toko: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateStoreLocation(String providerId, String address, double latitude, double longitude) async {
    try {
      // Update alamat dan koordinat di tabel profiles
      await supabase.from('profiles').update({
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      }).eq('id', providerId);
      
      // Ambil pengaturan toko saat ini
      final settingsResult = await getStoreSettings(providerId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (currentSettings) async {
          // Update alamat dan koordinat di pengaturan toko
          final updatedSettings = currentSettings.copyWith(
            storeAddress: address,
            latitude: latitude,
            longitude: longitude,
          );
          
          // Simpan pengaturan yang diperbarui
          return updateStoreSettings(providerId, updatedSettings);
        }
      );
    } catch (e) {
      developer.log('Error updating store location: $e');
      return Left(ServerFailure(message: 'Gagal memperbarui lokasi toko: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateServiceRadius(String providerId, double radius) async {
    try {
      // Ambil pengaturan toko saat ini
      final settingsResult = await getStoreSettings(providerId);
      
      return settingsResult.fold(
        (failure) => Left(failure),
        (currentSettings) async {
          // Update radius layanan
          final updatedSettings = currentSettings.copyWith(serviceRadius: radius);
          
          // Simpan pengaturan yang diperbarui
          return updateStoreSettings(providerId, updatedSettings);
        }
      );
    } catch (e) {
      developer.log('Error updating service radius: $e');
      return Left(ServerFailure(message: 'Gagal memperbarui radius layanan: ${e.toString()}'));
    }
  }

  // Helper method untuk menyimpan pengaturan toko ke database
  Future<void> _saveStoreSettingsToDatabase(String providerId, StoreSettingsEntity settings) async {
    // Ambil provider_details saat ini
    final response = await supabase
        .from('profiles')
        .select('provider_details')
        .eq('id', providerId)
        .single();
    
    Map<String, dynamic> providerDetails = response['provider_details'] ?? {};
    
    // Update pengaturan toko dalam provider_details
    providerDetails['store_settings'] = settings.toJson();
    
    // Simpan provider_details yang diperbarui ke database
    await supabase.from('profiles').update({
      'provider_details': providerDetails,
    }).eq('id', providerId);
  }
}
