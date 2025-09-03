import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class ProviderStatisticsScreen extends StatefulWidget {
  const ProviderStatisticsScreen({super.key});

  @override
  State<ProviderStatisticsScreen> createState() => _ProviderStatisticsScreenState();
}

class _ProviderStatisticsScreenState extends State<ProviderStatisticsScreen> {
  final List<String> _timeRanges = ['7 Hari', '30 Hari', '90 Hari'];
  String _selectedTimeRange = '30 Hari';
  bool _isLoading = true;
  late String _providerId;
  
  // Data statistik dari database
  Map<String, dynamic> _statisticsData = {
    'totalPesanan': 0,
    'pesananSelesai': 0,
    'pesananDibatalkan': 0,
    'ratingRataRata': '0.0',
    'pendapatanBulanIni': 0,
    'pendapatanBulanLalu': 0,
    'chartData': <Map<String, dynamic>>[],
  };
  
  final _supabase = Supabase.instance.client;
  
  @override
  void initState() {
    super.initState();
    _getCurrentProviderId();
  }
  
  Future<void> _getCurrentProviderId() async {
    try {
      // Mendapatkan ID user saat ini dari Supabase Auth
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        _providerId = currentUser.id;
        await _fetchStatisticsData();
      } else {
        developer.log('User tidak terautentikasi', name: 'ProviderStatistics');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error mendapatkan provider ID: $e', name: 'ProviderStatistics');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fetchStatisticsData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Menentukan rentang waktu berdasarkan _selectedTimeRange
      int days;
      switch (_selectedTimeRange) {
        case '7 Hari':
          days = 7;
          break;
        case '90 Hari':
          days = 90;
          break;
        case '30 Hari':
        default:
          days = 30;
          break;
      }
      
      final DateTime now = DateTime.now();
      final DateTime startDate = now.subtract(Duration(days: days));
      final DateTime startDateLastMonth = now.subtract(Duration(days: days + 30));
      
      // Format tanggal untuk query
      final String formattedStartDate = startDate.toIso8601String();
      final String formattedStartDateLastMonth = startDateLastMonth.toIso8601String();
      
      // 1. Mendapatkan total pesanan
      final totalOrdersResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('provider_id', _providerId)
          .gte('order_date', formattedStartDate)
          .count();
      
      // 2. Mendapatkan pesanan selesai
      final completedOrdersResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('provider_id', _providerId)
          .eq('order_status', 'completed')
          .gte('order_date', formattedStartDate)
          .count();
      
      // 3. Mendapatkan pesanan dibatalkan
      final cancelledOrdersResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('provider_id', _providerId)
          .eq('order_status', 'cancelled')
          .gte('order_date', formattedStartDate)
          .count();
      
      // 4. Mendapatkan rating rata-rata
      final ratingResponse = await _supabase
          .from('reviews')
          .select('rating')
          .eq('provider_id', _providerId)
          .gte('review_date', formattedStartDate);
      
      double averageRating = 0.0;
      if (ratingResponse.isNotEmpty) {
        final List<dynamic> ratings = ratingResponse;
        final double totalRating = ratings.fold(0.0, (sum, item) => sum + (item['rating'] as num));
        averageRating = totalRating / ratings.length;
      }
      
      // 5. Mendapatkan pendapatan bulan ini
      final currentMonthRevenueResponse = await _supabase
          .from('transactions')
          .select('amount')
          .eq('user_id', _providerId)
          .eq('transaction_type', 'income')
          .gte('transaction_date', formattedStartDate);
      
      double currentMonthRevenue = 0.0;
      if (currentMonthRevenueResponse.isNotEmpty) {
        final List<dynamic> transactions = currentMonthRevenueResponse;
        currentMonthRevenue = transactions.fold(0.0, (sum, item) => sum + (item['amount'] as num));
      }
      
      // 6. Mendapatkan pendapatan bulan lalu
      final lastMonthRevenueResponse = await _supabase
          .from('transactions')
          .select('amount')
          .eq('user_id', _providerId)
          .eq('transaction_type', 'income')
          .gte('transaction_date', formattedStartDateLastMonth)
          .lt('transaction_date', formattedStartDate);
      
      double lastMonthRevenue = 0.0;
      if (lastMonthRevenueResponse.isNotEmpty) {
        final List<dynamic> transactions = lastMonthRevenueResponse;
        lastMonthRevenue = transactions.fold(0.0, (sum, item) => sum + (item['amount'] as num));
      }
      
      // 7. Mendapatkan data chart pendapatan harian
      final List<Map<String, dynamic>> chartData = [];
      
      for (int i = 0; i < days; i++) {
        final DateTime date = now.subtract(Duration(days: days - i - 1));
        final DateTime nextDate = date.add(const Duration(days: 1));
        
        final String formattedDate = DateFormat('dd/MM').format(date);
        final String queryStartDate = date.toIso8601String();
        final String queryEndDate = nextDate.toIso8601String();
        
        final dailyRevenueResponse = await _supabase
            .from('transactions')
            .select('amount')
            .eq('user_id', _providerId)
            .eq('transaction_type', 'income')
            .gte('transaction_date', queryStartDate)
            .lt('transaction_date', queryEndDate);
        
        double dailyRevenue = 0.0;
        if (dailyRevenueResponse.isNotEmpty) {
          final List<dynamic> transactions = dailyRevenueResponse;
          dailyRevenue = transactions.fold(0.0, (sum, item) => sum + (item['amount'] as num));
        }
        
        chartData.add({
          'tanggal': formattedDate,
          'pendapatan': dailyRevenue,
        });
      }
      
      // Update state dengan data dari database
      setState(() {
        _statisticsData = {
          'totalPesanan': totalOrdersResponse,
          'pesananSelesai': completedOrdersResponse,
          'pesananDibatalkan': cancelledOrdersResponse,
          'ratingRataRata': averageRating.toStringAsFixed(1),
          'pendapatanBulanIni': currentMonthRevenue,
          'pendapatanBulanLalu': lastMonthRevenue,
          'chartData': chartData,
        };
        _isLoading = false;
      });
      
    } catch (e) {
      developer.log('Error mengambil data statistik: $e', name: 'ProviderStatistics');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Statistik Kinerja'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeRangeSelector(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildRevenueChart(),
                  const SizedBox(height: 24),
                  _buildOrderStatistics(),
                  const SizedBox(height: 24),
                  _buildRatingStatistics(),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _timeRanges.map((range) {
          final bool isSelected = range == _selectedTimeRange;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeRange = range;
                });
                // Memuat ulang data saat rentang waktu berubah
                _fetchStatisticsData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    range,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Pesanan',
                _statisticsData['totalPesanan'].toString(),
                Icons.shopping_bag_outlined,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildSummaryCard(
                'Pesanan Selesai',
                _statisticsData['pesananSelesai'].toString(),
                Icons.check_circle_outline,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Rating Rata-rata',
                _statisticsData['ratingRataRata'].toString(),
                Icons.star_outline,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildSummaryCard(
                'Pesanan Dibatalkan',
                _statisticsData['pesananDibatalkan'].toString(),
                Icons.cancel_outlined,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(6), // Mengurangi padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18), // Ukuran icon lebih kecil
                const SizedBox(width: 6), // Jarak lebih kecil
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith( // Font lebih kecil
                          color: Colors.grey[700],
                        ),
                    overflow: TextOverflow.ellipsis, // Mengatasi overflow dengan ellipsis
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6), // Jarak lebih kecil
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith( // Font lebih kecil
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pendapatan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Text(
              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                  .format(_statisticsData['pendapatanBulanIni']).replaceAll(',', '.'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            if (_statisticsData['pendapatanBulanLalu'] > 0)
              Text(
                _statisticsData['pendapatanBulanIni'] > _statisticsData['pendapatanBulanLalu']
                    ? '+${((_statisticsData['pendapatanBulanIni'] - _statisticsData['pendapatanBulanLalu']) / _statisticsData['pendapatanBulanLalu'] * 100).toStringAsFixed(1)}%'
                    : '${((_statisticsData['pendapatanBulanIni'] - _statisticsData['pendapatanBulanLalu']) / _statisticsData['pendapatanBulanLalu'] * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _statisticsData['pendapatanBulanIni'] >= _statisticsData['pendapatanBulanLalu']
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _statisticsData['chartData'].isEmpty
              ? const Center(child: Text('Tidak ada data pendapatan'))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 55,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                NumberFormat.compact(locale: 'id_ID').format(value).replaceAll(',', '.'),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value % 5 != 0 && value != 0 && value != (_statisticsData['chartData'].length - 1)) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                _statisticsData['chartData'][value.toInt()]['tanggal'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    minX: 0,
                    maxX: (_statisticsData['chartData'].length - 1).toDouble(),
                    minY: 0,
                    maxY: _statisticsData['chartData'].isEmpty
                        ? 100000
                        : (_statisticsData['chartData']
                                .map<double>((item) => (item['pendapatan'] as double))
                                .reduce((a, b) => a > b ? a : b) *
                            1.2),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          _statisticsData['chartData'].length,
                          (index) => FlSpot(
                            index.toDouble(),
                            (_statisticsData['chartData'][index]['pendapatan'] as double),
                          ),
                        ),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withAlpha(25),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik Pesanan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatisticRow(
                  'Total Pesanan',
                  _statisticsData['totalPesanan'].toString(),
                  Icons.shopping_bag_outlined,
                  AppColors.primary,
                ),
                const Divider(),
                _buildStatisticRow(
                  'Pesanan Selesai',
                  _statisticsData['pesananSelesai'].toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                const Divider(),
                _buildStatisticRow(
                  'Pesanan Dibatalkan',
                  _statisticsData['pesananDibatalkan'].toString(),
                  Icons.cancel_outlined,
                  Colors.red,
                ),
                const Divider(),
                _buildStatisticRow(
                  'Tingkat Penyelesaian',
                  _statisticsData['totalPesanan'] > 0
                      ? '${(_statisticsData['pesananSelesai'] / _statisticsData['totalPesanan'] * 100).toStringAsFixed(1)}%'
                      : '0%',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating & Ulasan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _statisticsData['ratingRataRata'].toString(),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Rating Rata-rata',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticRow(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
