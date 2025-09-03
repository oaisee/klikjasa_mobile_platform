import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/widgets/custom_button.dart';

/// Widget untuk menampilkan empty state
/// 
/// Widget ini digunakan ketika tidak ada data yang ditampilkan
/// atau ketika terjadi error yang memerlukan aksi dari user.
class EmptyStateWidget extends StatelessWidget {
  /// Ikon yang ditampilkan
  final IconData? icon;
  
  /// Path gambar yang ditampilkan (alternatif dari icon)
  final String? imagePath;
  
  /// Judul empty state
  final String title;
  
  /// Deskripsi empty state
  final String? description;
  
  /// Text untuk button aksi
  final String? actionText;
  
  /// Fungsi yang dipanggil ketika button aksi ditekan
  final VoidCallback? onActionPressed;
  
  /// Apakah button aksi sedang loading
  final bool isLoading;
  
  /// Ukuran ikon/gambar
  final double iconSize;
  
  /// Warna ikon
  final Color? iconColor;

  /// Konstruktor untuk EmptyStateWidget
  const EmptyStateWidget({
    super.key,
    this.icon,
    this.imagePath,
    required this.title,
    this.description,
    this.actionText,
    this.onActionPressed,
    this.isLoading = false,
    this.iconSize = 80.0,
    this.iconColor,
  });

  /// Factory constructor untuk no data state
  factory EmptyStateWidget.noData({
    Key? key,
    String title = 'Tidak Ada Data',
    String? description = 'Belum ada data yang tersedia saat ini.',
    String? actionText,
    VoidCallback? onActionPressed,
    bool isLoading = false,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.inbox_outlined,
      title: title,
      description: description,
      actionText: actionText,
      onActionPressed: onActionPressed,
      isLoading: isLoading,
    );
  }

  /// Factory constructor untuk no search results
  factory EmptyStateWidget.noSearchResults({
    Key? key,
    String title = 'Tidak Ditemukan',
    String? description = 'Tidak ada hasil yang sesuai dengan pencarian Anda.',
    String? actionText = 'Coba Lagi',
    VoidCallback? onActionPressed,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.search_off_outlined,
      title: title,
      description: description,
      actionText: actionText,
      onActionPressed: onActionPressed,
    );
  }

  /// Factory constructor untuk network error
  factory EmptyStateWidget.networkError({
    Key? key,
    String title = 'Koneksi Bermasalah',
    String? description = 'Periksa koneksi internet Anda dan coba lagi.',
    String? actionText = 'Coba Lagi',
    VoidCallback? onActionPressed,
    bool isLoading = false,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.wifi_off_outlined,
      title: title,
      description: description,
      actionText: actionText,
      onActionPressed: onActionPressed,
      isLoading: isLoading,
      iconColor: AppColors.error,
    );
  }

  /// Factory constructor untuk server error
  factory EmptyStateWidget.serverError({
    Key? key,
    String title = 'Terjadi Kesalahan',
    String? description = 'Terjadi kesalahan pada server. Silakan coba lagi.',
    String? actionText = 'Coba Lagi',
    VoidCallback? onActionPressed,
    bool isLoading = false,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.error_outline,
      title: title,
      description: description,
      actionText: actionText,
      onActionPressed: onActionPressed,
      isLoading: isLoading,
      iconColor: AppColors.error,
    );
  }

  /// Factory constructor untuk permission denied
  factory EmptyStateWidget.permissionDenied({
    Key? key,
    String title = 'Akses Ditolak',
    String? description = 'Anda tidak memiliki izin untuk mengakses halaman ini.',
    String? actionText = 'Kembali',
    VoidCallback? onActionPressed,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.lock_outline,
      title: title,
      description: description,
      actionText: actionText,
      onActionPressed: onActionPressed,
      iconColor: AppColors.warning,
    );
  }

  /// Factory constructor untuk maintenance
  factory EmptyStateWidget.maintenance({
    Key? key,
    String title = 'Sedang Maintenance',
    String? description = 'Aplikasi sedang dalam perbaikan. Silakan coba lagi nanti.',
    String? actionText = 'Coba Lagi',
    VoidCallback? onActionPressed,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.build_outlined,
      title: title,
      description: description,
      actionText: actionText,
      onActionPressed: onActionPressed,
      iconColor: AppColors.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or Image
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Icon(
                icon,
                size: iconSize,
                color: iconColor ?? AppColors.textSecondary,
              ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Description
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action Button
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 32),
              CustomButton.primary(
                text: actionText!,
                onPressed: onActionPressed,
                isLoading: isLoading,
                size: ButtonSize.medium,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan empty state dalam list
class EmptyStateListWidget extends StatelessWidget {
  /// Widget empty state yang akan ditampilkan
  final EmptyStateWidget emptyState;
  
  /// Apakah menggunakan sliver (untuk CustomScrollView)
  final bool isSliver;

  /// Konstruktor untuk EmptyStateListWidget
  const EmptyStateListWidget({
    super.key,
    required this.emptyState,
    this.isSliver = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: emptyState,
    );
    
    if (isSliver) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: child,
      );
    }
    
    return child;
  }
}