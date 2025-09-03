import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/repositories/service_provider_repository.dart';
import 'package:klik_jasa/features/common/balance/domain/usecases/deduct_promotion_balance_usecase.dart';

class ToggleServicePromotionUsecase {
  final ServiceProviderRepository serviceProviderRepository;
  final DeductPromotionBalanceUsecase deductPromotionBalanceUsecase;

  ToggleServicePromotionUsecase({
    required this.serviceProviderRepository,
    required this.deductPromotionBalanceUsecase,
  });

  Future<Either<Failure, Service>> call({
    required String serviceId,
    required String providerId,
    required bool isPromoted,
    required String serviceTitle,
  }) async {
    try {
      // Jika mengaktifkan promosi, potong saldo terlebih dahulu
      if (isPromoted) {
        const double promotionCost = 1000.0; // Biaya promosi Rp 1000/hari
        await deductPromotionBalanceUsecase(providerId, promotionCost, serviceTitle);
      }

      // Update status promosi layanan
      final updatedServiceEither = await serviceProviderRepository.updateServicePromotion(
        serviceId: serviceId,
        isPromoted: isPromoted,
        promotionStartDate: isPromoted ? DateTime.now() : null,
        promotionEndDate: isPromoted ? DateTime.now().add(const Duration(days: 1)) : null,
      );

      return updatedServiceEither;
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
