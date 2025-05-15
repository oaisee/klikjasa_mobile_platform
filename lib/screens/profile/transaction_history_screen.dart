import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'all'; // 'all', 'topup', 'payment', 'refund'

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    if (userId != null) {
      await Provider.of<TransactionProvider>(context, listen: false)
          .loadUserTransactions(userId);
    }
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    if (_selectedFilter == 'all') {
      return transactions;
    }
    return transactions.where((transaction) => transaction.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Top Up', 'topup'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pembayaran', 'payment'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Refund', 'refund'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Komisi', 'commission'),
                ],
              ),
            ),
          ),

          // Transaction List
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Terjadi kesalahan: ${provider.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTransactions,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredTransactions = _getFilteredTransactions(provider.transactions);

                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all'
                              ? 'Belum ada transaksi'
                              : 'Belum ada transaksi ${_getTransactionTypeName(_selectedFilter)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _TransactionItem(transaction: transaction);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  String _getTransactionTypeName(String type) {
    switch (type) {
      case 'topup':
        return 'top up';
      case 'payment':
        return 'pembayaran';
      case 'refund':
        return 'refund';
      case 'commission':
        return 'komisi';
      default:
        return '';
    }
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTransactionIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTransactionTitle(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormatter.format(transaction.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getAmountText(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _getAmountColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (transaction.description != null) ...[
              const SizedBox(height: 8),
              Text(
                transaction.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon() {
    IconData iconData;
    Color iconColor;

    switch (transaction.type) {
      case 'topup':
        iconData = Icons.add_circle;
        iconColor = Colors.green;
        break;
      case 'payment':
        iconData = Icons.shopping_cart;
        iconColor = Colors.blue;
        break;
      case 'refund':
        iconData = Icons.replay;
        iconColor = Colors.orange;
        break;
      case 'commission':
        iconData = Icons.attach_money;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.receipt;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _getTransactionTitle() {
    switch (transaction.type) {
      case 'topup':
        return 'Top Up Saldo';
      case 'payment':
        return 'Pembayaran Layanan';
      case 'refund':
        return 'Refund';
      case 'commission':
        return 'Komisi';
      default:
        return 'Transaksi';
    }
  }

  String _getAmountText() {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    switch (transaction.type) {
      case 'topup':
      case 'refund':
      case 'commission':
        return '+ ${formatter.format(transaction.amount)}';
      case 'payment':
        return '- ${formatter.format(transaction.amount)}';
      default:
        return formatter.format(transaction.amount);
    }
  }

  Color _getAmountColor() {
    switch (transaction.type) {
      case 'topup':
      case 'refund':
      case 'commission':
        return Colors.green;
      case 'payment':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  String _getStatusText() {
    switch (transaction.status) {
      case 'pending':
        return 'Menunggu';
      case 'success':
        return 'Berhasil';
      case 'failed':
        return 'Gagal';
      default:
        return transaction.status;
    }
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case 'pending':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
