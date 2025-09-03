// lib/features/admin_mode/presentation/widgets/admin_summary_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/admin_dashboard_stats_bloc.dart';
import 'package:go_router/go_router.dart'; // Untuk navigasi
import 'package:klik_jasa/routes/app_router.dart'; // Untuk route names
import 'package:klik_jasa/features/admin_mode/presentation/widgets/user_provider_chart_widget.dart';
import 'package:klik_jasa/features/admin_mode/presentation/widgets/order_history_chart_widget.dart';

// Class untuk menyimpan data summary yang dibutuhkan oleh BlocSelector
class _SummaryData {
  final String pendingVerifications;
  final String totalActiveServices;

  const _SummaryData({
    required this.pendingVerifications,
    required this.totalActiveServices,
  });
}

class AdminSummaryWidget extends StatelessWidget {
  const AdminSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Struktur utama widget tidak perlu di-rebuild saat state berubah
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Chart user/provider dengan widget terpisah yang memiliki BlocBuilder sendiri
              const UserProviderChartWidget(),
              const SizedBox(height: 10),
              // Chart histori order dengan widget terpisah yang memiliki BlocBuilder sendiri
              const OrderHistoryChartWidget(),
              const SizedBox(height: 10),
              // Hanya summary card yang perlu BlocSelector untuk performa lebih baik
              _buildSummaryCards(context),
              // Padding bawah
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // Memisahkan summary cards ke widget terpisah dengan BlocSelector
  Widget _buildSummaryCards(BuildContext context) {
    return BlocSelector<
      AdminDashboardStatsBloc,
      AdminDashboardStatsState,
      _SummaryData
    >(
      // Selector hanya memilih data yang diperlukan dan hanya rebuild saat data tersebut berubah
      selector: (state) {
        String pendingVerifications = "-";
        String totalActiveServicesText = "-";
        bool isLoading = false;
        String? errorMessage;

        // Gunakan CombinedDashboardState untuk mendapatkan data summary
        if (state is CombinedDashboardState) {
          isLoading = state.isSummaryLoading;
          errorMessage = state.summaryError;

          if (state.summaryStats != null) {
            pendingVerifications = state.summaryStats!.pendingVerifications
                .toString();
            totalActiveServicesText = state.summaryStats!.totalActiveServices
                .toString();
          } else if (isLoading) {
            pendingVerifications = "Memuat...";
            totalActiveServicesText = "Memuat...";
          } else if (errorMessage != null) {
            pendingVerifications = "Error";
            totalActiveServicesText = "Error";
          }
        } else if (state is AdminDashboardStatsLoading) {
          pendingVerifications = "Memuat...";
          totalActiveServicesText = "Memuat...";
        } else if (state is AdminDashboardStatsLoaded) {
          pendingVerifications = state.stats.pendingVerifications.toString();
          totalActiveServicesText = state.stats.totalActiveServices.toString();
        } else if (state is AdminDashboardStatsError) {
          pendingVerifications = "Error";
          totalActiveServicesText = "Error";
        }

        return _SummaryData(
          pendingVerifications: pendingVerifications,
          totalActiveServices: totalActiveServicesText,
        );
      },
      builder: (context, summaryData) {
        return Column(
          children: [
            _buildSummaryCard(
              context: context,
              icon: Icons.verified_user_outlined,
              title: 'Penyedia Menunggu Verifikasi',
              value: summaryData.pendingVerifications,
              color: Colors.orange,
              onTap: () {
                // Navigasi ke halaman manajemen pengguna dengan tab verifikasi penyedia
                context.go(
                  '${AppRouter.adminBaseRoute}/${AppRouter.adminUserManagementRoute}',
                );
              },
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              context: context,
              icon: Icons.design_services_outlined,
              title: 'Total Layanan Aktif',
              value: summaryData.totalActiveServices,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final bool isLoading = value == "Memuat...";
    final bool isError = value == "Error";

    return Card(
      elevation: 4.0, // Sedikit lebih menonjol
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha((255 * 0.1).round()),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Menampilkan indikator loading atau error sesuai dengan state
                    if (isLoading)
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Memuat...",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      )
                    else if (isError)
                      Text(
                        "Error",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      )
                    else
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isError ? Colors.red.shade700 : Colors.black87,
                        ),
                      ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
