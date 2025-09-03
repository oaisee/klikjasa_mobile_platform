import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';

abstract class ServiceRepository {
  /// Mendapatkan layanan berdasarkan lokasi pengguna
  /// 
  /// [userProvinsi], [userKabupatenKota], [userKecamatan], [userDesaKelurahan] adalah parameter lokasi pengguna
  /// [limit] adalah jumlah maksimal layanan yang dikembalikan
  /// [offset] adalah jumlah layanan yang dilewati (untuk pagination)
  /// 
  /// Return Either[Failure, List[ServiceWithLocation]]
  Future<Either<Failure, List<ServiceWithLocation>>> getServicesByLocation({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
    int limit = 10,
    int offset = 0,
  });

  /// Mendapatkan layanan yang dipromosikan
  /// 
  /// [limit] adalah jumlah maksimal layanan yang dikembalikan
  /// [offset] adalah jumlah layanan yang dilewati (untuk pagination)
  /// 
  /// Return Either[Failure, List[ServiceWithLocation]]
  Future<Either<Failure, List<ServiceWithLocation>>> getPromotedServices({
    int limit = 10,
    int offset = 0,
  });

  /// Mendapatkan layanan berdasarkan rating tertinggi
  /// 
  /// [limit] adalah jumlah maksimal layanan yang dikembalikan
  /// [offset] adalah jumlah layanan yang dilewati (untuk pagination)
  /// 
  /// Return Either[Failure, List[ServiceWithLocation]]
  Future<Either<Failure, List<ServiceWithLocation>>> getServicesByHighestRating({
    int limit = 10,
    int offset = 0,
  });

  Future<Either<Failure, ServiceWithLocation>> getServiceById(int serviceId);
  
  /// Mendapatkan stream layanan berdasarkan lokasi untuk update realtime
  /// 
  /// [userProvinsi], [userKabupatenKota], [userKecamatan], [userDesaKelurahan] adalah parameter lokasi pengguna
  /// 
  /// Return Stream of Either[Failure, List[ServiceWithLocation]]
  Stream<Either<Failure, List<ServiceWithLocation>>> getServicesByLocationStream({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
  });
  
  /// Mendapatkan stream layanan yang dipromosikan untuk update realtime
  /// 
  /// Return Stream of Either[Failure, List[ServiceWithLocation]]
  Stream<Either<Failure, List<ServiceWithLocation>>> getPromotedServicesStream();
  
  /// Mendapatkan stream layanan berdasarkan rating tertinggi untuk update realtime
  /// 
  /// Return Stream of Either[Failure, List[ServiceWithLocation]]
  Stream<Either<Failure, List<ServiceWithLocation>>> getServicesByHighestRatingStream();
  
  /// Membersihkan resources yang digunakan oleh repository
  void dispose();
}
