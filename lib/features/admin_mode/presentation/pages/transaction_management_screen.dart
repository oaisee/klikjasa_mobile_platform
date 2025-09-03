import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/injection_container.dart' as di;

class TransactionManagementScreen extends StatefulWidget {
  const TransactionManagementScreen({super.key});

  @override
  State<TransactionManagementScreen> createState() => _TransactionManagementScreenState();
}

class _TransactionManagementScreenState extends State<TransactionManagementScreen> {
  final SupabaseClient _supabase = di.sl<SupabaseClient>();
  final List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Ambil data transaksi dari Supabase
      final response = await _supabase
          .from('transactions')
          .select('*, profiles(full_name), orders(service_id, provider_id, user_id)')
          .order('transaction_date', ascending: false)
          .limit(50);

      setState(() {
        _transactions.clear();
        _transactions.addAll(List<Map<String, dynamic>>.from(response));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat transaksi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBody(),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBody() {
    return _buildTransactionList();
  }
  
  Widget _buildTransactionList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTransactions,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada transaksi yang ditemukan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Transaksi akan muncul saat pengguna melakukan pembayaran',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        itemCount: _transactions.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          // Gunakan transaction_date bukan created_at
          final transactionDate = transaction['transaction_date'] != null 
              ? DateTime.parse(transaction['transaction_date']) 
              : DateTime.now();
          final amount = transaction['amount'] ?? 0;
          final type = transaction['transaction_type'] ?? 'unknown';
          final userName = transaction['profiles']?['full_name'] ?? 'Pengguna';
          
          // Tentukan warna dan ikon berdasarkan tipe transaksi
          Color transactionColor;
          IconData transactionIcon;
          String typeLabel;
          
          switch (type) {
            case 'platform_fee':
              transactionColor = Colors.orange;
              transactionIcon = Icons.account_balance;
              typeLabel = 'Biaya Platform';
              break;
            case 'topup':
              transactionColor = Colors.green;
              transactionIcon = Icons.add_circle;
              typeLabel = 'Top Up';
              break;
            case 'fee_deduction_user':
              transactionColor = Colors.red;
              transactionIcon = Icons.remove_circle;
              typeLabel = 'Potongan Biaya (User)';
              break;
            case 'fee_deduction_provider':
              transactionColor = Colors.red;
              transactionIcon = Icons.remove_circle;
              typeLabel = 'Potongan Biaya (Provider)';
              break;
            default:
              transactionColor = Colors.blue;
              transactionIcon = Icons.swap_horiz;
              typeLabel = 'Transaksi';
          }
          
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(
                            (transactionColor.r * 255.0).round(),
                            (transactionColor.g * 255.0).round(),
                            (transactionColor.b * 255.0).round(),
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(transactionIcon, color: transactionColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: transactionColor,
                              ),
                            ),
                            Text(
                              'ID: ${transaction['id']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _dateFormat.format(transactionDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengguna',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Jumlah',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: amount >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (transaction['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Keterangan: ${transaction['description']}'),
                  ],
                  const SizedBox(height: 16),
                  // Indikator perubahan
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(
                        (Colors.purple.r * 255.0).round(),
                        (Colors.purple.g * 255.0).round(),
                        (Colors.purple.b * 255.0).round(),
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Fungsi _getTransactionTypeLabel dan _getTransactionTypeColor dihapus karena tidak digunakan
}

