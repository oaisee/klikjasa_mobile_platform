import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/application/blocs/provider_summary_bloc/provider_summary_bloc.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/entities/provider_summary_data_entity.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';

class ProviderSummaryTab extends StatelessWidget {
  const ProviderSummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Dapatkan ID provider dari user yang sedang login
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      context.read<ProviderSummaryBloc>().add(
        SubscribeToProviderSummary(providerId: authState.user.id),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Lighter, cleaner background
      body: BlocBuilder<ProviderSummaryBloc, ProviderSummaryState>(
        builder: (context, state) {
          if (state is ProviderSummaryLoading) {
            return _buildSummaryLoadingShimmer();
          } else if (state is ProviderSummaryLoaded) {
            return _buildSummaryContent(context, state);
          } else if (state is ProviderSummaryError) {
            return _buildErrorState(context, state.message);
          } else {
            return _buildSummaryLoadingShimmer();
          }
        },
      ),
    );
  }

  Widget _buildSummaryContent(
    BuildContext context,
    ProviderSummaryLoaded state,
  ) {
    // ... (Kode ini tidak berubah)
    final summary = state.summaryData;
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: () {
        final completer = Completer<void>();
        context.read<ProviderSummaryBloc>().add(
          RefreshProviderSummary(completer: completer),
        );
        return completer.future;
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsGrid(context, summary, currencyFormatter),
            const SizedBox(height: 32),
            _buildActivitiesSection(context, summary),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    ProviderSummaryDataEntity summary,
    NumberFormat currencyFormatter,
  ) {
    const spacing = 16.0;

    return Column(
      children: [
        // 1. Layanan Aktif (satu kolom penuh)
        _buildFuturisticMetricCard(
          icon: Icons.business_center_outlined,
          title: 'Layanan Aktif',
          value: summary.layananAktif.toString(),
          color: const Color(0xFF9C27B0),
          isFullWidth: true,
          isHorizontal: true,
          onTap: () => context.pushNamed('providerServices'),
        ),
        const SizedBox(height: spacing),

        // 2. Pesanan Aktif & 3. Pesanan Selesai (dua kolom)
        Row(
          children: [
            Expanded(
              child: _buildFuturisticMetricCard(
                icon: Icons.local_mall_outlined,
                title: 'Pesanan Aktif',
                value: summary.pesananAktif.toString(),
                color: AppColors.primary,
                onTap: () => context.pushNamed('providerOrders', queryParameters: {'tab': 'baru'}),
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: _buildFuturisticMetricCard(
                icon: Icons.check_circle_outline,
                title: 'Pesanan Selesai',
                value: summary.pesananSelesai30Hari.toString(),
                color: const Color(0xFF4CAF50),
                onTap: () => context.pushNamed('providerOrders', queryParameters: {'tab': 'completed'}),
              ),
            ),
          ],
        ),
        const SizedBox(height: spacing),

        // 4. Rating Rata-rata & 5. Total Ulasan (dua kolom)
        Row(
          children: [
            Expanded(
              child: _buildFuturisticMetricCard(
                icon: Icons.star_border_rounded,
                title: 'Rating Rata-rata',
                value: summary.ratingRataRata.toStringAsFixed(1),
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: _buildFuturisticMetricCard(
                icon: Icons.rate_review_outlined,
                title: 'Total Ulasan',
                value: summary.ulasanBaru.toString(),
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: spacing),

        // 6. Total Pendapatan (satu kolom penuh)
        _buildFuturisticMetricCard(
          icon: Icons.monetization_on_outlined,
          title: 'Total Pendapatan',
          value: currencyFormatter
              .format(summary.pendapatanBulanIni)
              .replaceAll(',', '.'),
          color: AppColors.success,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildFuturisticMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isFullWidth = false,
    bool isHorizontal = false,
    VoidCallback? onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        
        // Hitung ukuran font berdasarkan lebar card
        double valueFontSize;
        double titleFontSize;
        double iconSize;
        double padding;
        double borderRadius;

        if (cardWidth < 140) {
          // Layar sangat kecil
          valueFontSize = 18;
          titleFontSize = 11;
          iconSize = 24;
          padding = 6;
          borderRadius = isFullWidth ? 12 : 16;
        } else if (cardWidth < 160) {
          // Layar kecil
          valueFontSize = 20;
          titleFontSize = 12;
          iconSize = 28;
          padding = 8;
          borderRadius = isFullWidth ? 12 : 18;
        } else {
          // Layar normal dan besar
          valueFontSize = 24;
          titleFontSize = 14;
          iconSize = 32;
          padding = 10;
          borderRadius = isFullWidth ? 12 : 20;
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.08).round()),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: color.withAlpha((255 * 0.2).round()),
                width: 1.5,
              ),
            ),
            margin: isFullWidth ? EdgeInsets.zero : null,
            padding: EdgeInsets.all(padding),
          child: isHorizontal
              ? Row(
                  children: [
                    Icon(icon, color: color, size: iconSize),
                    SizedBox(width: padding),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: padding * 0.5),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: iconSize),
                    SizedBox(height: padding * 0.15),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: valueFontSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
        );
      },
    );
  }

  Widget _buildActivitiesSection(
    BuildContext context,
    ProviderSummaryDataEntity summary,
  ) {
    final activities = [
      if (summary.ulasanBaru > 0)
        MapEntry(
          '${summary.ulasanBaru} Ulasan Baru',
          'Lihat ulasan terbaru dari pelanggan',
        ),
      if (summary.pesananPerluTindakan > 0)
        MapEntry(
          '${summary.pesananPerluTindakan} Pesanan Perlu Tindakan',
          'Segera respon pesanan yang masuk',
        ),
      if (summary.pesananSelesai30Hari > 0)
        MapEntry(
          '${summary.pesananSelesai30Hari} Pesanan Selesai',
          'Dalam 30 hari terakhir',
        ),
      if (summary.layananAktif > 0)
        MapEntry(
          '${summary.layananAktif} Layanan Aktif',
          'Kelola layanan yang tersedia',
        ),
    ];

    if (activities.isEmpty) {
      return _buildEmptyState(
        context,
        'Belum ada aktivitas terbaru untuk ditampilkan.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
          child: Text(
            'Aktivitas Terbaru',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.borderLight.withAlpha((255 * 0.5).round()),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              VoidCallback? onTapCallback;
              
              // Tentukan navigasi berdasarkan jenis aktivitas
              if (activity.key.contains('Layanan Aktif')) {
                onTapCallback = () => context.pushNamed('providerServices');
              } else if (activity.key.contains('Ulasan Baru')) {
                onTapCallback = () => context.pushNamed('providerOrders', queryParameters: {'tab': 'completed'});
              } else if (activity.key.contains('Pesanan Perlu Tindakan')) {
                onTapCallback = () => context.pushNamed('providerOrders', queryParameters: {'tab': 'baru'});
              } else if (activity.key.contains('Pesanan Selesai')) {
                onTapCallback = () => context.pushNamed('providerOrders', queryParameters: {'tab': 'completed'});
              } else {
                onTapCallback = () => context.pushNamed('providerOrders');
              }
              
              return _buildActivityTile(
                context: context,
                title: activity.key,
                subtitle: activity.value,
                onTap: onTapCallback,
              );
            },
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: AppColors.borderLight.withAlpha((255 * 0.5).round()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _buildSummaryLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            pinned: true,
            backgroundColor: const Color(0xFFF0F4F8),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              title: Container(
                width: 150,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: List.generate(4, (index) => _buildShimmerCard()),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: 200,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error.withAlpha((255 * 0.7).round()),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Gagal Memuat Data',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              onPressed: () {
                context.read<ProviderSummaryBloc>().add(
                  const RefreshProviderSummary(
                    providerId: '00d9dc58-851f-43b7-92db-3335f27d3c9e',
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
