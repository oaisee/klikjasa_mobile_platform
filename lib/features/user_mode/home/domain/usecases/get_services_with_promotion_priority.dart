import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/service_repository.dart';
import 'package:klik_jasa/features/user_mode/home/domain/usecases/get_promoted_services.dart';

/// Use case untuk mendapatkan layanan dengan prioritas promosi
/// Algoritma urutan:
/// 1. Layanan promosi di urutan teratas
/// 2. Di antara layanan promosi, urutkan berdasarkan rating tertinggi
/// 3. Bila rating sama, acak urutannya
/// 4. Layanan non-promosi di bawah layanan promosi, diurutkan berdasarkan rating
class GetServicesWithPromotionPriority implements UseCase<List<ServiceWithLocation>, ServicePriorityParams> {
  final ServiceRepository repository;

  GetServicesWithPromotionPriority(this.repository);

  @override
  Future<Either<Failure, List<ServiceWithLocation>>> call(ServicePriorityParams params) async {
    try {
      // Ambil layanan promosi
      final promotedResult = await repository.getPromotedServices(
        limit: params.promotedLimit,
        offset: 0,
      );

      // Ambil layanan berdasarting rating tertinggi
      final ratedResult = await repository.getServicesByHighestRating(
        limit: params.regularLimit,
        offset: 0,
      );

      // Ambil layanan berdasarkan lokasi jika diperlukan
      final locationResult = await repository.getServicesByLocation(
        userProvinsi: params.userProvinsi,
        userKabupatenKota: params.userKabupatenKota,
        userKecamatan: params.userKecamatan,
        userDesaKelurahan: params.userDesaKelurahan,
        limit: params.locationLimit,
        offset: 0,
      );

      return promotedResult.fold(
        (failure) => Left(failure),
        (promotedServices) {
          return ratedResult.fold(
            (failure) => Left(failure),
            (ratedServices) {
              return locationResult.fold(
                (failure) => Left(failure),
                (locationServices) {
                  final sortedServices = _sortServicesWithPromotionPriority(
                    promotedServices,
                    ratedServices,
                    locationServices,
                    params.totalLimit,
                  );
                  return Right(sortedServices);
                },
              );
            },
          );
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal mengambil layanan: ${e.toString()}'));
    }
  }

  /// Mengurutkan layanan dengan prioritas promosi
  List<ServiceWithLocation> _sortServicesWithPromotionPriority(
    List<ServiceWithLocation> promotedServices,
    List<ServiceWithLocation> ratedServices,
    List<ServiceWithLocation> locationServices,
    int totalLimit,
  ) {
    final random = Random();
    final result = <ServiceWithLocation>[];
    final addedIds = <int>{};

    // 1. Tambahkan layanan promosi terlebih dahulu
    final sortedPromoted = List<ServiceWithLocation>.from(promotedServices);
    
    // Urutkan layanan promosi berdasarkan rating, acak jika rating sama
    sortedPromoted.sort((a, b) {
      final ratingComparison = b.averageRating.compareTo(a.averageRating);
      if (ratingComparison == 0) {
        // Jika rating sama, acak urutan
        return random.nextBool() ? 1 : -1;
      }
      return ratingComparison;
    });

    // Tambahkan layanan promosi ke hasil
    for (final service in sortedPromoted) {
      if (result.length >= totalLimit) break;
      result.add(service);
      addedIds.add(service.id);
    }

    // 2. Gabungkan layanan berdasarkan rating dan lokasi, hindari duplikasi
    final combinedServices = <ServiceWithLocation>[];
    
    // Tambahkan layanan berdasarkan rating yang belum ada
    for (final service in ratedServices) {
      if (!addedIds.contains(service.id)) {
        combinedServices.add(service);
        addedIds.add(service.id);
      }
    }

    // Tambahkan layanan berdasarkan lokasi yang belum ada
    for (final service in locationServices) {
      if (!addedIds.contains(service.id)) {
        combinedServices.add(service);
        addedIds.add(service.id);
      }
    }

    // Urutkan layanan non-promosi berdasarkan rating
    combinedServices.sort((a, b) {
      final ratingComparison = b.averageRating.compareTo(a.averageRating);
      if (ratingComparison == 0) {
        // Jika rating sama, acak urutan
        return random.nextBool() ? 1 : -1;
      }
      return ratingComparison;
    });

    // 3. Tambahkan layanan non-promosi ke hasil
    for (final service in combinedServices) {
      if (result.length >= totalLimit) break;
      result.add(service);
    }

    return result;
  }
}

class ServicePriorityParams extends PaginationParams {
  final String? userProvinsi;
  final String? userKabupatenKota;
  final String? userKecamatan;
  final String? userDesaKelurahan;
  final int promotedLimit;
  final int regularLimit;
  final int locationLimit;
  final int totalLimit;

  const ServicePriorityParams({
    this.userProvinsi,
    this.userKabupatenKota,
    this.userKecamatan,
    this.userDesaKelurahan,
    this.promotedLimit = 5,
    this.regularLimit = 10,
    this.locationLimit = 10,
    this.totalLimit = 20,
    super.limit = 20,
    super.offset = 0,
  });

  @override
  List<Object?> get props => [
        userProvinsi,
        userKabupatenKota,
        userKecamatan,
        userDesaKelurahan,
        promotedLimit,
        regularLimit,
        locationLimit,
        totalLimit,
        ...super.props,
      ];
}
