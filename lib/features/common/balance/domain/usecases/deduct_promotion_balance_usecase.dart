import 'package:klik_jasa/features/common/balance/domain/repositories/user_balance_repository.dart';

class DeductPromotionBalanceUsecase {
  final UserBalanceRepository repository;

  DeductPromotionBalanceUsecase(this.repository);

  Future<bool> call(String userId, double promotionCost, String serviceTitle) async {
    final description = 'Biaya promosi layanan: $serviceTitle';
    
    try {
      // Cek saldo terlebih dahulu
      final currentBalanceResult = await repository.getUserBalance(userId);
      
      return currentBalanceResult.fold(
        (failure) => throw Exception('Gagal mendapatkan saldo: ${failure.message}'),
        (userBalance) async {
          if (userBalance.balance < promotionCost) {
            throw Exception('Saldo tidak mencukupi untuk biaya promosi. Saldo saat ini: Rp ${userBalance.balance.toStringAsFixed(0)}');
          }
          
          // Potong saldo
          final deductResult = await repository.deductBalance(userId, promotionCost, description, 'PROMOTION_FEE');
          return deductResult.fold(
            (failure) => throw Exception('Gagal memotong saldo: ${failure.message}'),
            (success) => success,
          );
        },
      );
    } catch (e) {
      throw Exception('Gagal memotong saldo promosi: ${e.toString()}');
    }
  }
}
