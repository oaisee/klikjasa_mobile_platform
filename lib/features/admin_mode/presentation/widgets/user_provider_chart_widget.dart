// lib/features/admin_mode/presentation/widgets/user_provider_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/admin_dashboard_stats_bloc.dart';

class UserProviderChartWidget extends StatefulWidget {
  const UserProviderChartWidget({super.key});

  @override
  State<UserProviderChartWidget> createState() =>
      _UserProviderChartWidgetState();
}

class _UserProviderChartWidgetState extends State<UserProviderChartWidget> {
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
      '[UserProviderChart] Memuat data untuk periode: $_selectedPeriod',
    );



    // Emit event untuk memuat data real dari database
    final bloc = context.read<AdminDashboardStatsBloc>();
    bloc.add(LoadUserProvidersByPeriod(period: _selectedPeriod));
  }

  // Fungsi untuk membuat data spots untuk chart
  List<FlSpot> _createSpots(List<String> labels, Map<String, int> data) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < labels.length; i++) {
      final String label = labels[i];
      final int value = data[label] ?? 0;
      spots.add(FlSpot(i.toDouble(), value.toDouble()));
    }
    return spots;
  }

  // Fungsi untuk menghitung nilai Y maksimum pada chart
  double _calculateMaxY(
    Map<String, int> userData,
    Map<String, int> providerData,
  ) {
    int maxUser = userData.values.isEmpty ? 0 : userData.values.reduce((a, b) => a > b ? a : b);
    int maxProvider = providerData.values.isEmpty ? 0 : providerData.values.reduce((a, b) => a > b ? a : b);
    int maxValue = maxUser > maxProvider ? maxUser : maxProvider;
    // Tambahkan margin atas
    return maxValue > 0
        ? (maxValue * 1.2)
        : 100.0; // Default 100 jika tidak ada data
  }
  
  // Fungsi untuk mendapatkan judul periode
  String _getPeriodTitle(String period) {
    switch (period) {
      case 'Minggu':
        return 'Hari dalam Seminggu';
      case 'Bulan':
        return 'Bulan dalam Setahun';
      case 'Tahun':
        return 'Tahun';
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
              'Pertumbuhan Pengguna & Penyedia',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Pengguna', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('Penyedia', Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            // Chart
            BlocBuilder<AdminDashboardStatsBloc, AdminDashboardStatsState>(
              builder: (context, state) {
                // Gunakan CombinedDashboardState untuk mendapatkan data user/provider
                if (state is CombinedDashboardState) {
                  // Tampilkan loading indicator jika sedang memuat data
                  if (state.isUserProviderLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  // Tampilkan error jika ada
                  if (state.userProviderError != null) {
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
                              'Terjadi kesalahan: ${state.userProviderError}',
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
                  if (state.userProviderData != null) {
                    final userProviderData = state.userProviderData!;
                    final List<String> labels = userProviderData.labels;
                    final Map<String, int> userData = userProviderData.userData;
                    final Map<String, int> providerData = userProviderData.providerData;

                    // Buat chart dengan data real
                    return _buildLineChart(
                      labels,
                      userData,
                      providerData,
                      _getPeriodTitle(_selectedPeriod),
                    );
                  }
                }
                
                // Fallback untuk state lama (backward compatibility)
                else if (state is AdminDashboardStatsLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                else if (state is AdminDashboardStatsError) {
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
                            'Terjadi kesalahan: ${state.message}',
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
                else if (state is UserProviderDataLoaded) {
                  // Gunakan data real dari state lama
                  final userProviderState = state;
                  final List<String> labels = userProviderState.labels;
                  final Map<String, int> userData = userProviderState.userData;
                  final Map<String, int> providerData = userProviderState.providerData;

                  // Buat chart dengan data real
                  return _buildLineChart(
                    labels,
                    userData,
                    providerData,
                    _getPeriodTitle(_selectedPeriod),
                  );
                }

                // Default empty state
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bar_chart,
                          color: Colors.grey,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada data statistik',
                          textAlign: TextAlign.center,
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
        backgroundColor: isSelected ? color : color.withAlpha((255 * 0.3).round()),
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

  Widget _buildLineChart(
    List<String> labels,
    Map<String, int> userData,
    Map<String, int> providerData,
    String periodTitle,
  ) {
    // Hitung nilai Y maksimum untuk skala chart
    final double maxY = _calculateMaxY(userData, providerData);

    // Buat spots untuk chart
    final List<FlSpot> userSpots = _createSpots(labels, userData);
    final List<FlSpot> providerSpots = _createSpots(labels, providerData);

    // Gunakan LayoutBuilder untuk membuat chart responsif
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sesuaikan tinggi chart berdasarkan lebar yang tersedia
        // Kurangi tinggi untuk menghindari overflow
        final double chartHeight = constraints.maxWidth * 0.5;
        
        return SizedBox(
          height: chartHeight,
          child: Padding(
            // Kurangi padding untuk menghindari overflow
            padding: const EdgeInsets.only(
              right: 2.0,
              left: 3.0,
              top: 1.0,
              bottom: 5.0,
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxY / 5,
                  verticalInterval: 1,
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                    axisNameWidget: Text(
                      periodTitle,
                      style: const TextStyle(
                        fontSize: 10, // Kurangi ukuran font
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    axisNameSize: 16, // Kurangi ukuran axis name
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20, // Kurangi reserved size
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0), // Kurangi padding
                          child: Text(
                            labels[value.toInt()],
                            style: const TextStyle(
                              fontSize: 10, // Kurangi ukuran font
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30, // Kurangi reserved size
                      interval: maxY / 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10, // Kurangi ukuran font
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                minX: 0,
                maxX: labels.length.toDouble() - 1,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // Line chart untuk pengguna
                  LineChartBarData(
                    spots: userSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withAlpha((255 * 0.2).round()),
                    ),
                  ),
                  // Line chart untuk penyedia
                  LineChartBarData(
                    spots: providerSpots,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withAlpha((255 * 0.2).round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
