import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/constants/app_strings.dart'; // Asumsi Anda punya file ini
import 'package:klik_jasa/core/constants/app_colors.dart';   // Asumsi Anda punya file ini

class ProviderStatusScreen extends StatelessWidget {
  final String providerStatus;

  const ProviderStatusScreen({super.key, required this.providerStatus});

  String _getStatusMessage() {
    switch (providerStatus) {
      case 'pending':
        return AppStrings.statusPendingMessage; // Anda perlu menambahkan string ini
      case 'verified':
        return AppStrings.statusVerifiedMessage; // Anda perlu menambahkan string ini
      case 'rejected':
        return AppStrings.statusRejectedMessage; // Anda perlu menambahkan string ini
      default:
        return AppStrings.statusUnknownMessage; // Anda perlu menambahkan string ini
    }
  }

  IconData _getStatusIcon() {
    switch (providerStatus) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'verified':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getStatusColor() {
    switch (providerStatus) {
      case 'pending':
        return Colors.orangeAccent;
      case 'verified':
        return AppColors.success; // Asumsi Anda punya warna ini
      case 'rejected':
        return AppColors.error; // Asumsi Anda punya warna ini
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.providerApplicationStatus), // Anda perlu menambahkan string ini
        backgroundColor: AppColors.primary, // Menggunakan warna dari AppColors
        automaticallyImplyLeading: true, // Tombol kembali
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getStatusIcon(),
                size: 80,
                color: _getStatusColor(),
              ),
              const SizedBox(height: 24),
              Text(
                _getStatusMessage(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _getStatusColor(),
                ),
              ),
              const SizedBox(height: 32),
              if (providerStatus == 'verified')
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigasi ke dashboard penyedia jasa jika ada
                    // Navigator.of(context).pushReplacementNamed('/provider_dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: const Text(AppStrings.goToProviderDashboard), // Anda perlu menambahkan string ini
                )
              else if (providerStatus == 'rejected' || providerStatus == 'pending')
                 ElevatedButton(
                  onPressed: () {
                    // Navigasi ke halaman bantuan/FAQ menggunakan GoRouter
                    context.push('/profile/help');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87
                  ),
                  child: const Text(AppStrings.contactSupport), // Anda perlu menambahkan string ini
                ),
            ],
          ),
        ),
      ),
    );
  }
}
