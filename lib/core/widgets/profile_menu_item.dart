import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

/// Widget untuk menampilkan item menu di halaman profil
/// 
/// Widget ini menampilkan item menu dengan ikon, judul, dan aksi
/// yang dapat dikustomisasi sesuai kebutuhan.
class ProfileMenuItem extends StatelessWidget {
  /// Ikon yang ditampilkan di sebelah kiri item menu
  final IconData icon;
  
  /// Warna ikon, default menggunakan warna primary dari aplikasi
  final Color? iconColor;
  
  /// Judul item menu
  final String title;
  
  /// Subtitle/deskripsi item menu (opsional)
  final String? subtitle;
  
  /// Fungsi yang dipanggil ketika item menu ditekan
  final VoidCallback onTap;
  
  /// Widget tambahan yang ditampilkan di sebelah kanan item menu (opsional)
  /// Default-nya adalah ikon chevron_right
  final Widget? trailing;
  
  /// Apakah item menu ini dinonaktifkan
  final bool isDisabled;

  /// Konstruktor untuk ProfileMenuItem
  const ProfileMenuItem({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDisabled
            ? Colors.grey
            : iconColor ?? AppColors.primary,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDisabled ? Colors.grey : null,
            ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDisabled ? Colors.grey[400] : Colors.grey[600],
                  ),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: isDisabled ? null : onTap,
      enabled: !isDisabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}