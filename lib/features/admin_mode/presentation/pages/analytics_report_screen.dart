import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsReportScreen extends StatefulWidget {
  const AnalyticsReportScreen({super.key});

  @override
  State<AnalyticsReportScreen> createState() => _AnalyticsReportScreenState();
}

class _AnalyticsReportScreenState extends State<AnalyticsReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  final dateFormat = DateFormat('dd/MM/yyyy');
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Data untuk laporan
  Map<String, dynamic> _summaryData = {};
  List<Map<String, dynamic>> _userRegistrations = [];
  List<Map<String, dynamic>> _orderData = [];
  List<Map<String, dynamic>> _transactionData = [];
  List<Map<String, dynamic>> _categoryData = [];

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _startDateController.text = dateFormat.format(_startDate);
    _endDateController.text = dateFormat.format(_endDate);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await Future.wait([
        _fetchSummaryData(),
        _fetchUserData(),
        _fetchOrderData(),
        _fetchTransactionData(),
        _fetchCategoryData(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _handleError('Error saat mengambil data: $e');
    }
  }

  void _handleError(String message) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _fetchSummaryData() async {
    try {
      // Hitung total pengguna
      final usersResponse = await _supabase
          .from('profiles')
          .select('id, is_provider')
          .gte('created_at', _startDate.toIso8601String())
          .lte(
            'created_at',
            _endDate.add(const Duration(days: 1)).toIso8601String(),
          );

      final totalUsers = usersResponse.length;
      final totalProviders =
          usersResponse.where((user) => user['is_provider'] == true).length;

      // Hitung total pesanan
      final ordersResponse = await _supabase
          .from('orders')
          .select('id, order_status, total_price')
          .gte('created_at', _startDate.toIso8601String())
          .lte(
            'created_at',
            _endDate.add(const Duration(days: 1)).toIso8601String(),
          );

      final totalOrders = ordersResponse.length;
      final completedOrders = ordersResponse
          .where(
            (order) => order['order_status'] == 'completed_by_provider',
          )
          .length;

      // Hitung total pendapatan platform (fee)
      final revenueResponse = await _supabase
          .from('transactions')
          .select('amount')
          .inFilter('transaction_type', [
            'fee_deduction_user',
            'fee_deduction_provider',
          ])
          .gte('transaction_date', _startDate.toIso8601String())
          .lte(
            'transaction_date',
            _endDate.add(const Duration(days: 1)).toIso8601String(),
          );

      double totalRevenue = 0;
      for (var transaction in revenueResponse) {
        totalRevenue += (transaction['amount'] as num).toDouble();
      }

      setState(() {
        _summaryData = {
          'total_users': totalUsers,
          'total_providers': totalProviders,
          'total_orders': totalOrders,
          'completed_orders': completedOrders,
          'total_revenue': totalRevenue,
        };
      });
    } catch (e) {
      _handleError('Error saat mengambil data ringkasan: $e');
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, is_provider, created_at')
          .gte('created_at', _startDate.toIso8601String())
          .lte(
            'created_at',
            _endDate.add(const Duration(days: 1)).toIso8601String(),
          )
          .order('created_at', ascending: false);

      setState(() {
        _userRegistrations = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _handleError('Error saat mengambil data pengguna: $e');
    }
  }

  Future<void> _fetchOrderData() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            id, 
            order_status, 
            total_price, 
            created_at,
            user_id (id, full_name),
            provider_id (id, full_name),
            service_id (id, name)
          ''')
          .gte('created_at', _startDate.toIso8601String())
          .lte(
            'created_at',
            _endDate.add(const Duration(days: 1)).toIso8601String(),
          )
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> formattedOrders = [];

      for (var order in response) {
        formattedOrders.add({
          'id': order['id'],
          'order_status': order['order_status'],
          'total_price': order['total_price'],
          'created_at': order['created_at'],
          'user_name': order['user_id']?['full_name'] ?? 'N/A',
          'provider_name': order['provider_id']?['full_name'] ?? 'N/A',
          'service_name': order['service_id']?['name'] ?? 'N/A',
        });
      }

      setState(() {
        _orderData = formattedOrders;
      });
    } catch (e) {
      _handleError('Error saat mengambil data pesanan: $e');
    }
  }

  Future<void> _fetchTransactionData() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select(
            'id, user_id, amount, transaction_type, transaction_date, order_id',
          )
          .gte('transaction_date', _startDate.toIso8601String())
          .lte(
            'transaction_date',
            _endDate.add(const Duration(days: 1)).toIso8601String(),
          )
          .order('transaction_date', ascending: false);

      setState(() {
        _transactionData = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _handleError('Error saat mengambil data transaksi: $e');
    }
  }

  Future<void> _fetchCategoryData() async {
    try {
      // Ambil data kategori layanan
      final response = await _supabase
          .from('service_categories')
          .select('id, name, description')
          .order('name');

      // Ambil semua layanan aktif
      final servicesResponse = await _supabase
          .from('services')
          .select('id, service_category_id')
          .eq('is_active', true);

      // Hitung jumlah layanan per kategori secara manual
      final Map<String, int> serviceCounts = {};
      for (var service in servicesResponse) {
        final categoryId = service['service_category_id'];
        if (categoryId != null) {
          serviceCounts[categoryId] = (serviceCounts[categoryId] ?? 0) + 1;
        }
      }

      final List<Map<String, dynamic>> formattedCategories = [];

      for (var category in response) {
        final categoryId = category['id'];
        final serviceCount = serviceCounts[categoryId] ?? 0;

        formattedCategories.add({
          'id': categoryId,
          'name': category['name'],
          'description': category['description'],
          'service_count': serviceCount,
        });
      }

      setState(() {
        _categoryData = formattedCategories;
      });
    } catch (e) {
      _handleError('Error saat mengambil data kategori: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = dateFormat.format(_startDate);
        } else {
          _endDate = picked;
          _endDateController.text = dateFormat.format(_endDate);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analitik & Laporan'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Pengguna'),
            Tab(text: 'Pesanan'),
            Tab(text: 'Transaksi'),
            Tab(text: 'Kategori'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDateFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(),
                      _buildUsersTab(),
                      _buildOrdersTab(),
                      _buildTransactionsTab(),
                      _buildCategoriesTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _startDateController,
              decoration: const InputDecoration(
                labelText: 'Tanggal Mulai',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _endDateController,
              decoration: const InputDecoration(
                labelText: 'Tanggal Akhir',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, false),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(onPressed: _fetchData, child: const Text('Terapkan')),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExportButtons(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Platform',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryItem(
                      'Total Pengguna',
                      _summaryData['total_users']?.toString() ?? '0',
                    ),
                    _buildSummaryItem(
                      'Total Penyedia Jasa',
                      _summaryData['total_providers']?.toString() ?? '0',
                    ),
                    _buildSummaryItem(
                      'Total Pesanan',
                      _summaryData['total_orders']?.toString() ?? '0',
                    ),
                    _buildSummaryItem(
                      'Pesanan Selesai',
                      _summaryData['completed_orders']?.toString() ?? '0',
                    ),
                    _buildSummaryItem(
                      'Total Pendapatan Platform',
                      currencyFormat.format(_summaryData['total_revenue'] ?? 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: _exportToPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.table_chart),
            label: const Text('Excel'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _printReport,
            icon: const Icon(Icons.print),
            label: const Text('Cetak'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return _userRegistrations.isEmpty
        ? const Center(child: Text('Tidak ada data pengguna dalam periode ini'))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExportButtons(),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Nama')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Tipe')),
                          DataColumn(label: Text('Tanggal Daftar')),
                        ],
                        rows: _userRegistrations.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(Text(user['id'].toString())),
                              DataCell(Text(user['full_name'] ?? 'N/A')),
                              DataCell(Text(user['email'] ?? 'N/A')),
                              DataCell(
                                Text(
                                  user['is_provider'] == true
                                      ? 'Penyedia Jasa'
                                      : 'Pengguna',
                                ),
                              ),
                              DataCell(
                                Text(
                                  user['created_at'] != null
                                      ? dateFormat.format(
                                          DateTime.parse(user['created_at']),
                                        )
                                      : 'N/A',
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildOrdersTab() {
    return _orderData.isEmpty
        ? const Center(child: Text('Tidak ada data pesanan dalam periode ini'))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExportButtons(),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Pengguna')),
                          DataColumn(label: Text('Penyedia')),
                          DataColumn(label: Text('Layanan')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Tanggal')),
                        ],
                        rows: _orderData.map((order) {
                          return DataRow(
                            cells: [
                              DataCell(Text(order['id'].toString())),
                              DataCell(Text(order['user_name'])),
                              DataCell(Text(order['provider_name'])),
                              DataCell(Text(order['service_name'])),
                              DataCell(
                                Text(
                                  _formatOrderStatus(
                                    order['order_status'] ?? '',
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  currencyFormat.format(order['total_price']),
                                ),
                              ),
                              DataCell(
                                Text(
                                  order['created_at'] != null
                                      ? dateFormat.format(
                                          DateTime.parse(order['created_at']),
                                        )
                                      : 'N/A',
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildTransactionsTab() {
    return _transactionData.isEmpty
        ? const Center(
            child: Text('Tidak ada data transaksi dalam periode ini'),
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExportButtons(),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Tanggal')),
                          DataColumn(label: Text('Tipe')),
                          DataColumn(label: Text('Jumlah')),
                          DataColumn(label: Text('Order ID')),
                        ],
                        rows: _transactionData.map((transaction) {
                          return DataRow(
                            cells: [
                              DataCell(Text(transaction['id'].toString())),
                              DataCell(
                                Text(
                                  transaction['transaction_date'] != null
                                      ? dateFormat.format(
                                          DateTime.parse(
                                            transaction['transaction_date'],
                                          ),
                                        )
                                      : 'N/A',
                                ),
                              ),
                              DataCell(
                                Text(
                                  _getTransactionTypeText(
                                    transaction['transaction_type'] ?? '',
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  currencyFormat.format(transaction['amount']),
                                ),
                              ),
                              DataCell(
                                Text(
                                  transaction['order_id']?.toString() ?? '-',
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildCategoriesTab() {
    return _categoryData.isEmpty
        ? const Center(child: Text('Tidak ada data kategori'))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExportButtons(),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Nama')),
                          DataColumn(label: Text('Deskripsi')),
                          DataColumn(label: Text('Jumlah Layanan')),
                        ],
                        rows: _categoryData.map((category) {
                          return DataRow(
                            cells: [
                              DataCell(Text(category['id'].toString())),
                              DataCell(Text(category['name'] ?? 'N/A')),
                              DataCell(Text(category['description'] ?? 'N/A')),
                              DataCell(
                                Text(category['service_count'].toString()),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  String _formatOrderStatus(String status) {
    switch (status) {
      case 'pending_confirmation':
        return 'Menunggu Konfirmasi';
      case 'accepted_by_provider':
        return 'Diterima Penyedia';
      case 'rejected_by_provider':
        return 'Ditolak Penyedia';
      case 'in_progress':
        return 'Dalam Proses';
      case 'completed_by_provider':
        return 'Diselesaikan Penyedia';
      case 'cancelled_by_user':
        return 'Dibatalkan Pengguna';
      case 'cancelled_by_provider':
        return 'Dibatalkan Penyedia';
      case 'disputed':
        return 'Sengketa';
      default:
        return status;
    }
  }

  String _getTransactionTypeText(String type) {
    switch (type) {
      case 'topup':
        return 'Top Up Saldo';
      case 'withdrawal':
        return 'Penarikan Saldo';
      case 'fee_deduction_user':
        return 'Potongan Fee Pengguna';
      case 'fee_deduction_provider':
        return 'Potongan Fee Penyedia';
      case 'refund':
        return 'Pengembalian Dana';
      case 'adjustment':
        return 'Penyesuaian Saldo';
      default:
        return type;
    }
  }

  Future<void> _exportToPdf() async {
    try {
      final pdf = pw.Document();
      final currentTab = _tabController.index;

      // Judul laporan berdasarkan tab aktif
      String reportTitle = '';
      switch (currentTab) {
        case 0:
          reportTitle = 'Laporan Ringkasan Platform';
          break;
        case 1:
          reportTitle = 'Laporan Pengguna';
          break;
        case 2:
          reportTitle = 'Laporan Pesanan';
          break;
        case 3:
          reportTitle = 'Laporan Transaksi';
          break;
        case 4:
          reportTitle = 'Laporan Kategori';
          break;
      }

      // Header laporan
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final List<pw.Widget> widgets = [];

            // Tambahkan header
            widgets.add(
              pw.Header(
                level: 0,
                child: pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );

            widgets.add(pw.SizedBox(height: 10));

            // Tambahkan periode laporan
            widgets.add(
              pw.Text(
                'Periode: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                style: pw.TextStyle(fontSize: 12),
              ),
            );

            widgets.add(pw.SizedBox(height: 20));

            // Konten berdasarkan tab aktif
            switch (currentTab) {
              case 0: // Ringkasan
                widgets.add(_buildPdfSummary());
                break;
              case 1: // Pengguna
                widgets.add(_buildPdfUsers());
                break;
              case 2: // Pesanan
                widgets.add(_buildPdfOrders());
                break;
              case 3: // Transaksi
                widgets.add(_buildPdfTransactions());
                break;
              case 4: // Kategori
                widgets.add(_buildPdfCategories());
                break;
            }

            return widgets;
          },
        ),
      );

      // Simpan PDF ke file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$reportTitle.pdf');
      await file.writeAsBytes(await pdf.save());

      // Bagikan file
      await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Laporan $reportTitle'));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF berhasil dibuat dan dibagikan')),
        );
      }
    } catch (e) {
      _handleError('Error saat membuat PDF: $e');
    }
  }

  pw.Widget _buildPdfSummary() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Ringkasan Platform',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        _buildPdfSummaryItem(
          'Total Pengguna',
          _summaryData['total_users']?.toString() ?? '0',
        ),
        _buildPdfSummaryItem(
          'Total Penyedia Jasa',
          _summaryData['total_providers']?.toString() ?? '0',
        ),
        _buildPdfSummaryItem(
          'Total Pesanan',
          _summaryData['total_orders']?.toString() ?? '0',
        ),
        _buildPdfSummaryItem(
          'Pesanan Selesai',
          _summaryData['completed_orders']?.toString() ?? '0',
        ),
        _buildPdfSummaryItem(
          'Total Pendapatan Platform',
          currencyFormat.format(_summaryData['total_revenue'] ?? 0),
        ),
      ],
    );
  }

  pw.Widget _buildPdfSummaryItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfUsers() {
    final headers = ['ID', 'Nama', 'Email', 'Tipe', 'Tanggal Daftar'];
    final data = _userRegistrations.map((user) {
      return [
        user['id'].toString(),
        user['full_name'] ?? 'N/A',
        user['email'] ?? 'N/A',
        user['is_provider'] == true ? 'Penyedia Jasa' : 'Pengguna',
        user['created_at'] != null
            ? dateFormat.format(DateTime.parse(user['created_at']))
            : 'N/A',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerLeft,
      },
    );
  }

  pw.Widget _buildPdfOrders() {
    final headers = [
      'ID',
      'Pengguna',
      'Penyedia',
      'Layanan',
      'Status',
      'Total',
      'Tanggal',
    ];
    final data = _orderData.map((order) {
      return [
        order['id'].toString(),
        order['user_name'],
        order['provider_name'],
        order['service_name'],
        _formatOrderStatus(order['order_status'] ?? ''),
        currencyFormat.format(order['total_price']),
        order['created_at'] != null
            ? dateFormat.format(DateTime.parse(order['created_at']))
            : 'N/A',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerLeft,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerLeft,
      },
    );
  }

  pw.Widget _buildPdfTransactions() {
    final headers = ['ID', 'Tanggal', 'Tipe', 'Jumlah', 'Order ID'];
    final data = _transactionData.map((transaction) {
      return [
        transaction['id'].toString(),
        transaction['transaction_date'] != null
            ? dateFormat.format(DateTime.parse(transaction['transaction_date']))
            : 'N/A',
        _getTransactionTypeText(transaction['transaction_type'] ?? ''),
        currencyFormat.format(transaction['amount']),
        transaction['order_id']?.toString() ?? '-',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerLeft,
      },
    );
  }

  pw.Widget _buildPdfCategories() {
    final headers = ['ID', 'Nama', 'Deskripsi', 'Jumlah Layanan'];
    final data = _categoryData.map((category) {
      return [
        category['id'].toString(),
        category['name'] ?? 'N/A',
        category['description'] ?? 'N/A',
        category['service_count'].toString(),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
    );
  }

  Future<void> _exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final currentTab = _tabController.index;

      // Judul laporan berdasarkan tab aktif
      String sheetName = '';
      switch (currentTab) {
        case 0:
          sheetName = 'Ringkasan';
          break;
        case 1:
          sheetName = 'Pengguna';
          break;
        case 2:
          sheetName = 'Pesanan';
          break;
        case 3:
          sheetName = 'Transaksi';
          break;
        case 4:
          sheetName = 'Kategori';
          break;
      }

      // Hapus sheet default
      excel.delete('Sheet1');

      // Buat sheet baru
      final sheet = excel[sheetName];

      // Tambahkan judul laporan
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue(
        'Laporan $sheetName',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = TextCellValue(
        'Periode: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
      );

      // Tambahkan data berdasarkan tab aktif
      switch (currentTab) {
        case 0: // Ringkasan
          _addSummaryToExcel(sheet);
          break;
        case 1: // Pengguna
          _addUsersToExcel(sheet);
          break;
        case 2: // Pesanan
          _addOrdersToExcel(sheet);
          break;
        case 3: // Transaksi
          _addTransactionsToExcel(sheet);
          break;
        case 4: // Kategori
          _addCategoriesToExcel(sheet);
          break;
      }

      // Simpan Excel ke file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/Laporan_$sheetName.xlsx');
      await file.writeAsBytes(excel.encode()!);

      // Bagikan file
      await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)], text: 'Laporan Excel $sheetName'));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel berhasil dibuat dan dibagikan')),
        );
      }
    } catch (e) {
      _handleError('Error saat membuat Excel: $e');
    }
  }

  void _addSummaryToExcel(Sheet sheet) {
    // Tambahkan header
    final int startRow = 3;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow))
        .value = TextCellValue(
      'Metrik',
    );
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow))
        .value = TextCellValue(
      'Nilai',
    );

    // Tambahkan data ringkasan
    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + 1),
        )
        .value = TextCellValue(
      'Total Pengguna',
    );
    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow + 1),
        )
        .value = IntCellValue(
      _summaryData['total_users'] ?? 0,
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + 2),
        )
        .value = TextCellValue(
      'Total Penyedia Jasa',
    );
    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow + 2),
        )
        .value = IntCellValue(
      _summaryData['total_providers'] ?? 0,
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + 3),
        )
        .value = TextCellValue(
      'Total Pesanan',
    );
    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow + 3),
        )
        .value = IntCellValue(
      _summaryData['total_orders'] ?? 0,
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + 4),
        )
        .value = TextCellValue(
      'Pesanan Selesai',
    );
    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow + 4),
        )
        .value = IntCellValue(
      _summaryData['completed_orders'] ?? 0,
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + 5),
        )
        .value = TextCellValue(
      'Total Pendapatan Platform',
    );
    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow + 5),
        )
        .value = DoubleCellValue(
      _summaryData['total_revenue'] ?? 0,
    );
  }

  void _addUsersToExcel(Sheet sheet) {
    // Tambahkan header
    final int startRow = 3;
    final headers = ['ID', 'Nama', 'Email', 'Tipe', 'Tanggal Daftar'];

    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Tambahkan data pengguna
    for (var i = 0; i < _userRegistrations.length; i++) {
      final user = _userRegistrations[i];
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        user['id'].toString(),
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        user['full_name'] ?? 'N/A',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 2,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        user['email'] ?? 'N/A',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 3,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        user['is_provider'] == true ? 'Penyedia Jasa' : 'Pengguna',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 4,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        user['created_at'] != null
            ? dateFormat.format(DateTime.parse(user['created_at']))
            : 'N/A',
      );
    }
  }

  void _addOrdersToExcel(Sheet sheet) {
    // Tambahkan header
    final int startRow = 3;
    final headers = [
      'ID',
      'Pengguna',
      'Penyedia Jasa',
      'Layanan',
      'Status',
      'Total',
      'Fee',
      'Tanggal',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Tambahkan data pesanan
    for (var i = 0; i < _orderData.length; i++) {
      final order = _orderData[i];
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        order['id'].toString(),
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        order['user_name'] ?? 'N/A',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 2,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        order['provider_name'] ?? 'N/A',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 3,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        order['service_name'] ?? 'N/A',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 4,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        order['order_status'] ?? 'N/A',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 5,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        order['total_amount'] != null
            ? 'Rp ${NumberFormat('#,###').format(order['total_amount'])}'
            : 'Rp 0',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 6,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        order['fee_amount'] != null
            ? 'Rp ${NumberFormat('#,###').format(order['fee_amount'])}'
            : 'Rp 0',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 7,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        order['created_at'] != null
            ? dateFormat.format(DateTime.parse(order['created_at']))
            : 'N/A',
      );
    }
  }

  void _addTransactionsToExcel(Sheet sheet) {
    // Tambahkan header
    final int startRow = 3;
    final headers = ['ID', 'Pengguna', 'Tipe', 'Jumlah', 'Tanggal'];

    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow))
          .value = TextCellValue(
        headers[i],
      );
    }

    // Tambahkan data transaksi
    for (var i = 0; i < _transactionData.length; i++) {
      final transaction = _transactionData[i];
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        transaction['id'].toString(),
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        transaction['user_name'] ?? 'N/A',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 2,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        _getTransactionTypeText(transaction['transaction_type'] ?? ''),
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 3,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        transaction['amount'] != null
            ? 'Rp ${NumberFormat('#,###').format(transaction['amount'])}'
            : 'Rp 0',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 4,
              rowIndex: startRow + i + 1,
            ),
          )
          .value = TextCellValue(
        transaction['transaction_date'] != null
            ? dateFormat.format(DateTime.parse(transaction['transaction_date']))
            : 'N/A',
      );
    }
  }

  void _addCategoriesToExcel(Sheet sheet) {
    // Tambahkan header
    final int startRow = 3;
    final headers = ['ID', 'Nama', 'Deskripsi', 'Jumlah Layanan'];

    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow))
          .value = TextCellValue(headers[i]);
    }

    // Tambahkan data kategori
    for (var i = 0; i < _categoryData.length; i++) {
      final category = _categoryData[i];
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: startRow + i + 1))
          .value = TextCellValue(category['id'].toString());
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: startRow + i + 1))
          .value = TextCellValue(category['name'] ?? 'N/A');
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 2, rowIndex: startRow + i + 1))
          .value = TextCellValue(category['description'] ?? 'N/A');
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 3, rowIndex: startRow + i + 1))
          .value = TextCellValue(category['service_count']?.toString() ?? '0');
    }
  }

  Future<void> _printReport() async {
    try {
      final currentTab = _tabController.index;

      // Judul laporan berdasarkan tab aktif
      String reportTitle = '';
      switch (currentTab) {
        case 0:
          reportTitle = 'Ringkasan Platform';
          break;
        case 1:
          reportTitle = 'Data Pengguna';
          break;
        case 2:
          reportTitle = 'Data Pesanan';
          break;
        case 3:
          reportTitle = 'Data Transaksi';
          break;
        case 4:
          reportTitle = 'Data Kategori';
          break;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            final widgets = <pw.Widget>[];

            // Header laporan
            widgets.add(
              pw.Header(
                level: 0,
                child: pw.Text(reportTitle,
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
            );

            widgets.add(
              pw.Text(
                'Periode: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                style: pw.TextStyle(fontSize: 12),
              ),
            );

            widgets.add(pw.SizedBox(height: 20));

            // Konten berdasarkan tab aktif
            switch (currentTab) {
              case 0: // Ringkasan
                widgets.add(_buildPdfSummary());
                break;
              case 1: // Pengguna
                widgets.add(_buildPdfUsers());
                break;
              case 2: // Pesanan
                widgets.add(_buildPdfOrders());
                break;
              case 3: // Transaksi
                widgets.add(_buildPdfTransactions());
                break;
              case 4: // Kategori
                widgets.add(_buildPdfCategories());
                break;
            }

            return widgets;
          },
        ),
      );

      // Cetak PDF langsung
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: reportTitle,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan dikirim ke printer')),
        );
      }
    } catch (e) {
      _handleError('Error saat mencetak laporan: $e');
    }
  }
}
