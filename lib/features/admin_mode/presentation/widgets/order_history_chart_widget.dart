// lib/features/admin_mode/presentation/widgets/order_history_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/admin_dashboard_stats_bloc.dart';

class OrderHistoryChartWidget extends StatefulWidget {
  const OrderHistoryChartWidget({super.key});

  @override
  State<OrderHistoryChartWidget> createState() => _OrderHistoryChartWidgetState();
}

// Helper class untuk state chart
class _OrderHistoryChartState {
  final bool isLoading;
  final String? error;
  final OrderHistoryChartData? data;

  const _OrderHistoryChartState({
    required this.isLoading,
    required this.error,
    required this.data,
  });
}

class _OrderHistoryChartWidgetState extends State<OrderHistoryChartWidget> {
  String _selectedPeriod = 'Minggu'; // Default periode adalah Minggu

  @override
  void initState() {
    super.initState();
    // Muat data awal saat widget pertama kali dibuat
    _loadData();
  }

  void _loadData() {
    // Tambahkan log untuk debugging alur data
    debugPrint(
      '[OrderHistoryChart] Memuat data untuk periode: $_selectedPeriod',
    );

    // Emit event untuk memuat data real dari database
    final bloc = context.read<AdminDashboardStatsBloc>();
    bloc.add(LoadOrderHistoryByPeriod(period: _selectedPeriod));
  }

  // Fungsi untuk membuat spots untuk line chart
  List<FlSpot> _createSpots(List<String> labels, Map<String, int> data) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < labels.length; i++) {
      final String label = labels[i];
      final int value = data[label] ?? 0;
      spots.add(FlSpot(i.toDouble(), value.toDouble()));
    }
    return spots;
  }

  // Fungsi untuk membuat LineChartBarData
  LineChartBarData _createLineChartBarData(
    List<String> labels,
    Map<String, int> data,
    Color color,
  ) {
    return LineChartBarData(
      spots: _createSpots(labels, data),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withAlpha(50), // Menggunakan withAlpha untuk menghindari deprecated withOpacity
      ),
    );
  }

  // Fungsi untuk menghitung nilai Y maksimum pada chart
  double _calculateMaxY(
    Map<String, int> pendingOrdersData,
    Map<String, int> confirmedOrdersData,
    Map<String, int> inProgressOrdersData,
    Map<String, int> completedOrdersData,
    Map<String, int> cancelledOrdersData,
  ) {
    int maxPending = pendingOrdersData.values.isEmpty ? 0 : pendingOrdersData.values.reduce((a, b) => a > b ? a : b);
    int maxConfirmed = confirmedOrdersData.values.isEmpty ? 0 : confirmedOrdersData.values.reduce((a, b) => a > b ? a : b);
    int maxInProgress = inProgressOrdersData.values.isEmpty ? 0 : inProgressOrdersData.values.reduce((a, b) => a > b ? a : b);
    int maxCompleted = completedOrdersData.values.isEmpty ? 0 : completedOrdersData.values.reduce((a, b) => a > b ? a : b);
    int maxCancelled = cancelledOrdersData.values.isEmpty ? 0 : cancelledOrdersData.values.reduce((a, b) => a > b ? a : b);
    
    // Cari nilai maksimum dari semua kategori
    int maxValue = [maxPending, maxConfirmed, maxInProgress, maxCompleted, maxCancelled].reduce((a, b) => a > b ? a : b);
    
    // Tambahkan margin atas
    return maxValue > 0
        ? (maxValue * 1.2)
        : 100.0; // Default 100 jika tidak ada data
  }
  
  // Fungsi untuk mendapatkan judul periode
  String _getPeriodTitle(String period) {
    switch (period) {
      case 'Minggu':
        return 'Histori Transaksi per Hari';
      case 'Bulan':
        return 'Histori Transaksi per Bulan';
      case 'Tahun':
        return 'Histori Transaksi per Tahun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Penting: Gunakan MainAxisSize.min
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul chart
            const Text(
              'Histori Transaksi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Filter periode - Diposisikan di tengah
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol filter periode berjejer dengan warna berbeda
                  _buildPeriodButton('Minggu', Colors.blue.shade300),
                  const SizedBox(width: 8),
                  _buildPeriodButton('Bulan', Colors.green.shade300),
                  const SizedBox(width: 8),
                  _buildPeriodButton('Tahun', Colors.orange.shade300),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legenda
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                _buildLegendItem('Menunggu', Colors.blue),
                _buildLegendItem('Dikonfirmasi', Colors.purple),
                _buildLegendItem('Dikerjakan', Colors.amber),
                _buildLegendItem('Selesai', Colors.green),
                _buildLegendItem('Dibatalkan', Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            // Chart - Gunakan BlocSelector untuk efisiensi rebuild
            BlocSelector<AdminDashboardStatsBloc, AdminDashboardStatsState, _OrderHistoryChartState>(
              selector: (state) {
                if (state is CombinedDashboardState) {
                  return _OrderHistoryChartState(
                    isLoading: state.isOrderHistoryLoading,
                    error: state.orderHistoryError,
                    data: state.orderHistoryData,
                  );
                }
                return const _OrderHistoryChartState(
                  isLoading: false,
                  error: null,
                  data: null,
                );
              },
              builder: (context, chartState) {
                // Tampilkan loading indicator jika sedang memuat data
                if (chartState.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                // Tampilkan error jika ada
                if (chartState.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Terjadi kesalahan: ${chartState.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Tampilkan chart jika data tersedia
                if (chartState.data != null) {
                  final orderHistoryData = chartState.data!;
                  final List<String> labels = orderHistoryData.labels;
                  final Map<String, int> pendingOrdersData = orderHistoryData.pendingOrdersData;
                  final Map<String, int> confirmedOrdersData = orderHistoryData.confirmedOrdersData;
                  final Map<String, int> inProgressOrdersData = orderHistoryData.inProgressOrdersData;
                  final Map<String, int> completedOrdersData = orderHistoryData.completedOrdersData;
                  final Map<String, int> cancelledOrdersData = orderHistoryData.cancelledOrdersData;
                  final String periodTitle = _getPeriodTitle(_selectedPeriod);

                  return _buildLineChart(
                    labels,
                    pendingOrdersData,
                    confirmedOrdersData,
                    inProgressOrdersData,
                    completedOrdersData,
                    cancelledOrdersData,
                    periodTitle,
                  );
                }

                // Default empty state
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Tidak ada data tersedia'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Muat Data'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Membuat tombol periode dengan warna yang berbeda
  Widget _buildPeriodButton(String period, Color color) {
    final bool isSelected = _selectedPeriod == period;
    
    return ElevatedButton(
      onPressed: () {
        if (_selectedPeriod != period) {
          setState(() {
            _selectedPeriod = period;
          });
          _loadData();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withAlpha(75), // Menggunakan withAlpha untuk menghindari deprecated withOpacity
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(60, 28),
      ),
      child: Text(period),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(title),
      ],
    );
  }

  // Widget untuk menampilkan item summary
  Widget _buildSummaryItem(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25), // Menggunakan withAlpha untuk menghindari deprecated withOpacity
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(75)), // Menggunakan withAlpha untuk menghindari deprecated withOpacity
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<String> labels,
    Map<String, int> pendingOrdersData,
    Map<String, int> confirmedOrdersData,
    Map<String, int> inProgressOrdersData,
    Map<String, int> completedOrdersData,
    Map<String, int> cancelledOrdersData,
    String periodTitle,
  ) {
    // Hitung nilai Y maksimum untuk skala chart
    final double maxY = _calculateMaxY(
      pendingOrdersData,
      confirmedOrdersData,
      inProgressOrdersData,
      completedOrdersData,
      cancelledOrdersData,
    );

    // Hitung total untuk setiap status
    int totalPending = 0;
    int totalConfirmed = 0;
    int totalInProgress = 0;
    int totalCompleted = 0;
    int totalCancelled = 0;

    for (String label in labels) {
      totalPending += pendingOrdersData[label] ?? 0;
      totalConfirmed += confirmedOrdersData[label] ?? 0;
      totalInProgress += inProgressOrdersData[label] ?? 0;
      totalCompleted += completedOrdersData[label] ?? 0;
      totalCancelled += cancelledOrdersData[label] ?? 0;
    }

    // Widget untuk menampilkan summary jumlah order
    Widget summaryWidget = Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildSummaryItem('Menunggu', totalPending, Colors.blue),
          _buildSummaryItem('Dikonfirmasi', totalConfirmed, Colors.purple),
          _buildSummaryItem('Dikerjakan', totalInProgress, Colors.amber),
          _buildSummaryItem('Selesai', totalCompleted, Colors.green),
          _buildSummaryItem('Dibatalkan', totalCancelled, Colors.red),
        ],
      ),
    );

    // Gunakan LayoutBuilder untuk membuat chart responsif
    return Column(
      children: [
        summaryWidget,
        LayoutBuilder(
          builder: (context, constraints) {
            // Sesuaikan tinggi chart berdasarkan lebar yang tersedia
            final double chartHeight = constraints.maxWidth * 0.5;
            
            return SizedBox(
              height: chartHeight,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          String status;
                          switch (touchedSpot.barIndex) {
                            case 0:
                              status = 'Menunggu';
                              break;
                            case 1:
                              status = 'Dikonfirmasi';
                              break;
                            case 2:
                              status = 'Dikerjakan';
                              break;
                            case 3:
                              status = 'Selesai';
                              break;
                            case 4:
                              status = 'Dibatalkan';
                              break;
                            default:
                              status = 'Unknown';
                          }
                          return LineTooltipItem(
                            '$status: ${touchedSpot.y.toInt()}',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: const SideTitles(showTitles: false),
                      axisNameWidget: Text(
                        periodTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      axisNameSize: 20,
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: 0,
                  maxX: (labels.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    // Line untuk Menunggu
                    _createLineChartBarData(
                      labels, 
                      pendingOrdersData, 
                      Colors.blue,
                    ),
                    // Line untuk Dikonfirmasi
                    _createLineChartBarData(
                      labels, 
                      confirmedOrdersData, 
                      Colors.purple,
                    ),
                    // Line untuk Dikerjakan
                    _createLineChartBarData(
                      labels, 
                      inProgressOrdersData, 
                      Colors.amber,
                    ),
                    // Line untuk Selesai
                    _createLineChartBarData(
                      labels, 
                      completedOrdersData, 
                      Colors.green,
                    ),
                    // Line untuk Dibatalkan
                    _createLineChartBarData(
                      labels, 
                      cancelledOrdersData, 
                      Colors.red,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
