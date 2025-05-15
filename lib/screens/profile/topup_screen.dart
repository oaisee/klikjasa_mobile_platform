import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/custom_button.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  final int _minAmount = 50000; // Minimal top up Rp 50.000
  
  // Daftar nominal top up yang disarankan
  final List<int> _suggestedAmounts = [
    50000,
    100000,
    200000,
    500000,
    1000000,
  ];

  // Metode pembayaran yang tersedia
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'bank_transfer',
      'name': 'Transfer Bank',
      'icon': Icons.account_balance,
      'banks': ['BCA', 'Mandiri', 'BNI', 'BRI'],
    },
    {
      'id': 'e_wallet',
      'name': 'E-Wallet',
      'icon': Icons.account_balance_wallet,
      'providers': ['GoPay', 'OVO', 'DANA', 'LinkAja'],
    },
    {
      'id': 'virtual_account',
      'name': 'Virtual Account',
      'icon': Icons.credit_card,
      'banks': ['BCA', 'Mandiri', 'BNI', 'BRI', 'Permata'],
    },
  ];

  String _selectedPaymentMethod = 'bank_transfer';
  String _selectedBank = 'BCA';

  void _selectAmount(int amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }

  Future<void> _processTopUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final amount = int.parse(_amountController.text.replaceAll('.', ''));
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        
        if (authProvider.user == null) {
          throw Exception('User tidak ditemukan');
        }
        
        // Proses top-up menggunakan TransactionProvider
        await transactionProvider.processTopUp(
          userId: authProvider.user!.id,
          amount: amount.toDouble(),
          paymentMethod: _getPaymentMethodName(),
        );

        if (mounted) {
          // Tampilkan halaman sukses
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TopUpSuccessScreen(
                amount: amount,
                paymentMethod: _getPaymentMethodName(),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal melakukan top up: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _getPaymentMethodName() {
    final method = _paymentMethods.firstWhere(
      (method) => method['id'] == _selectedPaymentMethod,
    );
    
    if (_selectedPaymentMethod == 'bank_transfer' || _selectedPaymentMethod == 'virtual_account') {
      return '${method['name']} $_selectedBank';
    } else {
      return '${method['name']} $_selectedBank';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up Saldo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saldo saat ini
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final user = authProvider.user;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Saldo Anda:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        Text(
                          'Rp ${user?.saldo.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Nominal top up
              const Text(
                'Nominal Top Up',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nominal tidak boleh kosong';
                  }
                  final amount = int.tryParse(value.replaceAll('.', ''));
                  if (amount == null) {
                    return 'Nominal tidak valid';
                  }
                  if (amount < _minAmount) {
                    return 'Minimal top up Rp $_minAmount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nominal yang disarankan
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedAmounts.map((amount) {
                  return InkWell(
                    onTap: () => _selectAmount(amount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        'Rp ${amount.toString()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Metode pembayaran
              const Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  return RadioListTile(
                    title: Row(
                      children: [
                        Icon(method['icon']),
                        const SizedBox(width: 8),
                        Text(method['name']),
                      ],
                    ),
                    value: method['id'],
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value.toString();
                        if (method['banks'] != null && method['banks'].isNotEmpty) {
                          _selectedBank = method['banks'][0];
                        } else if (method['providers'] != null && method['providers'].isNotEmpty) {
                          _selectedBank = method['providers'][0];
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Sub-opsi metode pembayaran
              if (_selectedPaymentMethod == 'bank_transfer')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Bank',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _paymentMethods
                          .firstWhere((method) => method['id'] == 'bank_transfer')['banks']
                          .map<Widget>((bank) {
                        return ChoiceChip(
                          label: Text(bank),
                          selected: _selectedBank == bank,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedBank = bank;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                )
              else if (_selectedPaymentMethod == 'e_wallet')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih E-Wallet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _paymentMethods
                          .firstWhere((method) => method['id'] == 'e_wallet')['providers']
                          .map<Widget>((provider) {
                        return ChoiceChip(
                          label: Text(provider),
                          selected: _selectedBank == provider,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedBank = provider;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                )
              else if (_selectedPaymentMethod == 'virtual_account')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Bank',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _paymentMethods
                          .firstWhere((method) => method['id'] == 'virtual_account')['banks']
                          .map<Widget>((bank) {
                        return ChoiceChip(
                          label: Text(bank),
                          selected: _selectedBank == bank,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedBank = bank;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              const SizedBox(height: 32),

              // Tombol top up
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoading ? 'Memproses...' : 'Top Up Sekarang',
                  onPressed: _isLoading ? null : _processTopUp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

class TopUpSuccessScreen extends StatelessWidget {
  final int amount;
  final String paymentMethod;

  const TopUpSuccessScreen({
    super.key,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up Berhasil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Top Up Berhasil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rp ${amount.toString()}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'via $paymentMethod',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Saldo Anda telah berhasil ditambahkan. Silakan gunakan untuk memesan layanan atau menjadi penyedia jasa.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: CustomButton(
                  text: 'Kembali ke Profil',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
