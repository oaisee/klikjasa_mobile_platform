import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/repositories/service_provider_repository.dart';

/// Use case untuk mengaktifkan/menonaktifkan layanan (toggle is_active).
/// Mengimplementasikan [UseCase] dengan parameter [ToggleServiceActiveParams] dan
/// mengembalikan [Either<Failure, Service>].
class ToggleServiceActiveUseCase implements UseCase<Service, ToggleServiceActiveParams> {
  final ServiceProviderRepository repository;

  ToggleServiceActiveUseCase(this.repository);

  @override
  Future<Either<Failure, Service>> call(ToggleServiceActiveParams params) async {
    // Ambil detail layanan terlebih dahulu
    final serviceResult = await repository.getServiceDetail(params.serviceId);
    
    return serviceResult.fold(
      (failure) => Left(failure),
      (service) {
        // Buat salinan layanan dengan status is_active yang dibalik
        final updatedService = Service(
          id: service.id,
          providerId: service.providerId,
          categoryId: service.categoryId,
          categoryName: service.categoryName,
          title: service.title,
          description: service.description,
          price: service.price,
          priceUnit: service.priceUnit,
          locationText: service.locationText,
          imagesUrls: service.imagesUrls,
          isActive: !service.isActive, // Toggle status aktif
          averageRating: service.averageRating,
          ratingCount: service.ratingCount,
          createdAt: service.createdAt,
          updatedAt: service.updatedAt,
          isPromoted: service.isPromoted,
          promotionStartDate: service.promotionStartDate,
          promotionEndDate: service.promotionEndDate,
          serviceAreas: service.serviceAreas,
        );
        
        // Update layanan dengan status baru
        return repository.updateService(updatedService);
      },
    );
  }
}

/// Parameter untuk [ToggleServiceActiveUseCase].
/// Berisi ID layanan yang akan diaktifkan/dinonaktifkan.
class ToggleServiceActiveParams extends Equatable {
  final String serviceId;

  const ToggleServiceActiveParams({
    required this.serviceId,
  });

  @override
  List<Object?> get props => [serviceId];
}
