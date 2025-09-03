/// Enum untuk tipe transaksi yang sesuai dengan nilai enum di database Supabase
/// 
/// Nilai-nilai enum ini harus selalu sesuai dengan nilai enum transaction_type_enum
/// di database Supabase untuk menghindari error constraint.
enum TransactionType {
  /// Top up saldo pengguna
  topUp('top_up'),
  
  /// Pembayaran layanan (debit dari user)
  servicePaymentDebit('service_payment_debit'),
  
  /// Pembayaran layanan (credit ke provider)
  servicePaymentCreditProvider('service_payment_credit_provider'),
  
  /// Pengurangan biaya untuk pengguna
  feeDeductionUser('fee_deduction_user'),
  
  /// Pengurangan biaya untuk penyedia jasa
  feeDeductionProvider('fee_deduction_provider'),
  
  /// Pembayaran ke penyedia jasa
  payoutToProvider('payout_to_provider'),
  
  /// Pengembalian dana ke pengguna
  refundToUser('refund_to_user'),
  
  /// Top up (alias untuk topUp)
  topup('topup'),
  
  /// Biaya untuk pengguna
  feeUser('fee_user'),
  
  /// Biaya untuk penyedia jasa
  feeProvider('fee_provider'),
  
  /// Penarikan dana
  withdrawal('withdrawal'),
  
  /// Pengembalian dana
  refund('refund'),
  
  /// Penyesuaian saldo
  adjustment('adjustment'),
  
  /// Biaya checkout
  checkoutFee('checkout_fee'),
  
  /// Biaya platform
  platformFee('platform_fee');

  /// Nilai string yang sesuai dengan enum di database
  final String value;
  
  /// Constructor
  const TransactionType(this.value);
  
  /// Konversi dari string ke enum
  /// Mengembalikan null jika string tidak valid
  static TransactionType? fromString(String? value) {
    if (value == null) return null;
    
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.adjustment, // Default jika tidak ditemukan
    );
  }
  
  /// Validasi apakah string adalah nilai enum yang valid
  static bool isValid(String? value) {
    if (value == null) return false;
    
    return TransactionType.values.any((type) => type.value == value);
  }
}
