import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/balance/data/datasources/user_balance_remote_data_source.dart';
import 'package:klik_jasa/features/common/balance/domain/usecases/create_top_up_usecase.dart';
import 'package:klik_jasa/features/common/balance/domain/usecases/process_successful_top_up_usecase.dart';
import 'package:klik_jasa/injection_container.dart' as di; // Import dependency injection
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Untuk formatting angka

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _selectedQuickAmount;
  late final UserBalanceRemoteDataSource _balanceDataSource;
  late final CreateTopUpUseCase _createTopUpUseCase;
  late final ProcessSuccessfulTopUpUseCase _processSuccessfulTopUpUseCase;

  final List<int> _quickAmounts = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    // Mendapatkan instance dari dependency injection
    _balanceDataSource = di.sl<UserBalanceRemoteDataSource>();
    _createTopUpUseCase = di.sl<CreateTopUpUseCase>();
    _processSuccessfulTopUpUseCase = di.sl<ProcessSuccessfulTopUpUseCase>();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(price.round());
  }

  Future<void> _performTopUp() async {
    if (!(_formKey.currentState?.validate() ?? false) && _selectedQuickAmount == null) {
      if (_amountController.text.isEmpty && _selectedQuickAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih atau masukkan jumlah top up.'), backgroundColor: AppColors.error),
        );
        return;
      }
      // Jika form tidak valid karena input manual kosong tapi ada quick amount terpilih, itu valid
      if (_amountController.text.isNotEmpty && !(_formKey.currentState?.validate() ?? false)){
        return; // Biarkan validasi form standar menangani ini
      }
    }

    final amountString = _selectedQuickAmount ?? _amountController.text.replaceAll('.', '');
    final amount = int.tryParse(amountString);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah top up tidak valid.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Pengguna tidak terautentikasi.');
      }

      logger.i('TopUpScreen: Membuat histori top up untuk user $userId sebesar $amount');
      
      // 1. Buat entri di top_up_history dengan status PENDING
      final topUpResult = await _createTopUpUseCase(CreateTopUpParams(
        userId: userId,
        amount: amount.toDouble(),
        description: 'Top up manual via aplikasi',
        paymentMethod: 'manual',
      ));
      
      final topUpHistory = topUpResult.fold(
        (failure) => throw Exception(failure.message),
        (history) => history,
      );
      
      logger.i('TopUpScreen: Berhasil membuat histori top up dengan ID ${topUpHistory.id}');
      
      // 2. Proses top up berhasil (update status menjadi COMPLETED dan buat entri di transactions)
      final processResult = await _processSuccessfulTopUpUseCase(ProcessSuccessfulTopUpParams(
        topUpId: topUpHistory.id,
        paymentDetails: {'method': 'manual', 'confirmed_by': 'user'},
      ));
      
      final success = processResult.fold(
        (failure) => throw Exception(failure.message),
        (result) => result,
      );

      if (success && mounted) {
        // 3. Ambil saldo terbaru untuk ditampilkan
        final updatedBalance = await _balanceDataSource.getUserBalance(userId);

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top up Rp ${_formatPrice(amount.toDouble())} berhasil! Saldo baru Anda Rp ${_formatPrice(updatedBalance.balance)}'), 
            backgroundColor: AppColors.success
          ),
        );
        logger.i('TopUpScreen: Top up berhasil. Saldo baru: ${updatedBalance.balance}');
        Navigator.pop(context, true); // Kembali dan kirim sinyal sukses
      }
    } catch (e) {
      logger.e('TopUpScreen: Error saat melakukan top up: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal melakukan top up: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onQuickAmountSelected(int amount) {
    setState(() {
      _selectedQuickAmount = amount.toString();
      _amountController.clear(); // Kosongkan input manual jika memilih dari tombol cepat
       // Hapus fokus dari TextFormField jika ada
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.isiSaldo),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Pilih Nominal Top Up:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5, // Sesuaikan rasio aspek agar tombol tidak terlalu tinggi
                ),
                itemCount: _quickAmounts.length,
                itemBuilder: (context, index) {
                  final quickAmount = _quickAmounts[index];
                  final isSelected = _selectedQuickAmount == quickAmount.toString();
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? AppColors.accent : AppColors.lightGrey,
                      foregroundColor: isSelected ? AppColors.white : AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12), // Padding vertikal untuk tombol
                    ),
                    onPressed: () => _onQuickAmountSelected(quickAmount),
                    child: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(quickAmount)),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Atau Masukkan Nominal Lain:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Jumlah Top Up (Rp)',
                  hintText: 'Contoh: 50000',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  // Class untuk format ribuan saat input
                  ThousandsSeparatorInputFormatter(),
                ],
                validator: (value) {
                  if (_selectedQuickAmount != null) return null; // Tidak perlu validasi jika tombol cepat dipilih
                  if (value == null || value.isEmpty) {
                    return 'Masukkan jumlah top up';
                  }
                  final cleanValue = value.replaceAll('.', '');
                  if (int.tryParse(cleanValue) == null) {
                    return 'Format angka tidak valid';
                  }
                  if (int.parse(cleanValue) <= 0) {
                    return 'Jumlah harus lebih dari 0';
                  }
                  if (int.parse(cleanValue) < 10000) { // Contoh validasi minimal top up manual
                    return 'Minimal top up Rp 10.000';
                  }
                  return null;
                },
                onTap: () {
                  // Jika input manual diklik, hapus pilihan tombol cepat
                  if (_selectedQuickAmount != null) {
                    setState(() {
                      _selectedQuickAmount = null;
                    });
                  }
                },
                onChanged: (value) {
                  // Jika ada input manual, pastikan _selectedQuickAmount null
                  if (value.isNotEmpty && _selectedQuickAmount != null) {
                     setState(() {
                       _selectedQuickAmount = null;
                     });
                  }
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.account_balance_wallet, color: AppColors.white),
                      label: Text(AppStrings.konfirmasiTopUp, style: const TextStyle(fontSize: 16, color: AppColors.white)),
                      onPressed: _performTopUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper class untuk format ribuan saat input
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final intN = int.tryParse(newValue.text.replaceAll('.', ''));
    if (intN == null) {
      return oldValue; // Jika tidak bisa parse, kembalikan nilai lama
    }
    final formatter = NumberFormat('#,###', 'id_ID');
    String newText = formatter.format(intN);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
