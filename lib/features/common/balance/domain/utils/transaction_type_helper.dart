import 'package:klik_jasa/features/common/balance/domain/enums/transaction_type_enum.dart';
import 'package:klik_jasa/core/utils/logger.dart';

/// Helper class untuk menangani nilai TransactionType yang tidak valid
class TransactionTypeHelper {
  /// Mengkonversi string ke nilai enum TransactionType yang valid
  /// Jika nilai tidak valid, akan mengembalikan nilai default (fee_deduction_user)
  /// dan mencatat log error
  static TransactionType getSafeTransactionType(String? value) {
    // Jika nilai null, gunakan default
    if (value == null) {
      logger.e('TransactionTypeHelper: Nilai transaction_type null, menggunakan default: fee_deduction_user');
      return TransactionType.feeDeductionUser;
    }
    
    // Jika nilai adalah 'deduction' (nilai yang sering menyebabkan error),
    // ganti dengan fee_deduction_user
    if (value.toLowerCase() == 'deduction') {
      logger.e('TransactionTypeHelper: Ditemukan nilai "deduction" yang tidak valid, mengkonversi ke fee_deduction_user');
      return TransactionType.feeDeductionUser;
    }
    
    // Jika nilai adalah 'checkout_fee' yang menyebabkan error enum,
    // ganti dengan fee_deduction_user yang pasti valid
    if (value.toLowerCase() == 'checkout_fee') {
      logger.e('TransactionTypeHelper: Ditemukan nilai "checkout_fee" yang tidak valid di database, mengkonversi ke fee_deduction_user');
      return TransactionType.feeDeductionUser;
    }
    
    // Coba konversi nilai ke enum yang valid
    final transactionType = TransactionType.fromString(value);
    if (transactionType != null) {
      return transactionType;
    }
    
    // Jika tidak valid, gunakan default
    logger.e('TransactionTypeHelper: Nilai transaction_type tidak valid: $value, menggunakan default: fee_deduction_user');
    return TransactionType.feeDeductionUser;
  }
  
  /// Mengecek apakah string adalah nilai enum TransactionType yang valid
  static bool isValid(String? value) {
    return TransactionType.isValid(value);
  }
  
  /// Mendapatkan nilai string dari enum TransactionType yang valid untuk database
  static String getValidValue(String? value) {
    return getSafeTransactionType(value).value;
  }
}
