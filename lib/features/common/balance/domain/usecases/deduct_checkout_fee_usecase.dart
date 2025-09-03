import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/app_config/domain/repositories/app_config_repository.dart';
import 'package:klik_jasa/features/common/balance/domain/repositories/user_balance_repository.dart';
import 'package:logger/logger.dart';

class DeductCheckoutFeeUsecase {
  final UserBalanceRepository repository;
  final AppConfigRepository appConfigRepository;
  final Logger _logger = Logger();

  DeductCheckoutFeeUsecase(this.repository, this.appConfigRepository);

  /// Potong saldo pengguna jasa sebagai biaya aplikasi saat checkout
  /// [userId] - ID pengguna yang melakukan checkout
  /// [servicePrice] - Harga layanan yang dipesan
  /// [providerId] - ID penyedia layanan (hanya untuk pencatatan)
  /// [feePercentage] - Persentase biaya aplikasi yang sudah dihitung sebelumnya
  Future<Either<Failure, bool>> call({
    required String userId,
    required double servicePrice,
    required String providerId,
    required double feePercentage,
  }) async {
    try {
      // Hitung biaya aplikasi berdasarkan persentase yang ditetapkan admin
      final feeAmount = servicePrice * (feePercentage / 100);
      
      _logger.i('Memotong biaya aplikasi sebesar $feeAmount dari pengguna $userId untuk layanan dengan harga $servicePrice');
      _logger.i('Penyedia jasa $providerId TIDAK akan menerima penambahan saldo dari transaksi ini sesuai model bisnis aplikasi');
      
      // Potong saldo dari user sebagai biaya platform
      final userDeductResult = await repository.deductBalance(
        userId,
        feeAmount,
        'Biaya aplikasi ${feePercentage.toStringAsFixed(1)}% untuk layanan',
        'CHECKOUT_FEE',
      );
      
      // Tidak ada lagi penambahan saldo ke provider karena pembayaran dilakukan secara tunai
      // Saldo provider hanya akan dipotong saat mengkonfirmasi pesanan
      
      return userDeductResult;
    } catch (e) {
      _logger.e('Gagal memproses biaya checkout: ${e.toString()}');
      return Left(ServerFailure(message: 'Gagal memproses biaya checkout: ${e.toString()}'));
    }
  }
}
