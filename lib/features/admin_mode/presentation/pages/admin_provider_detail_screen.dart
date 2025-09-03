import 'package:flutter/material.dart';
import 'package:klik_jasa/features/admin_mode/domain/entities/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/provider_verification/provider_verification_bloc.dart';
import 'package:intl/intl.dart';

class AdminProviderDetailScreen extends StatelessWidget {
  final UserProfile userProfile;

  const AdminProviderDetailScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Tombol kembali melayang di sudut kanan atas dengan latar bulat
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.2).round()),
                spreadRadius: 0,
                blurRadius: 5,
                offset: const Offset(0,2),
              ),
            ],
          ),
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
            elevation: 12,
            child: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle(context, 'Informasi Akun'),
            _buildInfoRow('Email:', userProfile.email ?? 'Tidak tersedia'),
            _buildInfoRow(
              'Nama Lengkap:',
              userProfile.fullName ?? 'Tidak tersedia',
            ),
            _buildInfoRow(
              'Nomor Telepon:',
              userProfile.phoneNumber ?? 'Tidak tersedia',
            ),
            _buildInfoRow(
              'Status Verifikasi:',
              userProfile.providerVerificationStatus ?? 'N/A',
            ),
            _buildInfoRow('Role:', userProfile.role ?? 'N/A'),
            _buildInfoRow(
              'Terdaftar Sejak:',
              userProfile.createdAt != null
                  ? DateFormat(
                      'dd MMM yyyy, HH:mm',
                      'id_ID',
                    ).format(userProfile.createdAt!.toLocal())
                  : 'N/A',
            ),
            _buildInfoRow(
              'Update Terakhir:',
              userProfile.updatedAt != null
                  ? DateFormat(
                      'dd MMM yyyy, HH:mm',
                      'id_ID',
                    ).format(userProfile.updatedAt!.toLocal())
                  : 'N/A',
            ),

            const SizedBox(height: 20),
            _buildSectionTitle(context, 'Alamat'),
            _buildInfoRow(
              'Provinsi:',
              userProfile.provinsi ?? 'Tidak tersedia',
            ),
            _buildInfoRow(
              'Kabupaten/Kota:',
              userProfile.kabupatenKota ?? 'Tidak tersedia',
            ),
            _buildInfoRow(
              'Kecamatan:',
              userProfile.kecamatan ?? 'Tidak tersedia',
            ),
            _buildInfoRow(
              'Desa/Kelurahan:',
              userProfile.desaKelurahan ?? 'Tidak tersedia',
            ),
            _buildInfoRow(
              'Detail Alamat:',
              userProfile.addressDetail ?? 'Tidak tersedia',
            ),
            _buildInfoRow(
              'Kode Pos:',
              userProfile.postalCode ?? 'Tidak tersedia',
            ),
            if (userProfile.latitude != null && userProfile.longitude != null)
              _buildInfoRow(
                'Koordinat:',
                '${userProfile.latitude}, ${userProfile.longitude}',
              ),

            const SizedBox(height: 20),
            _buildSectionTitle(context, 'Dokumen Verifikasi'),
            // Bagian untuk menampilkan KTP
            if (userProfile.ktpUrl != null && userProfile.ktpUrl!.isNotEmpty)
              _buildKtpDisplay(context, userProfile.ktpUrl!)
            else
              _buildInfoRow('Foto KTP:', 'Tidak tersedia'),

            const SizedBox(height: 30),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Pastikan ProviderVerificationBloc tersedia di context jika halaman ini
    // dipanggil dari dalam BlocProvider<ProviderVerificationBloc>
    // atau jika ProviderVerificationBloc disediakan lebih tinggi di widget tree.
    final verificationBloc = BlocProvider.of<ProviderVerificationBloc>(
      context,
      listen: false,
    );

    // Tambahkan SafeArea untuk memastikan tombol tidak tertutup oleh tombol navigasi
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Setujui'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  onPressed: () {
                    verificationBloc.add(
                      ApproveProviderVerification(userProfile.id),
                    );
                    Navigator.of(
                      context,
                    ).pop(); // Kembali ke halaman daftar setelah aksi
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Tolak'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  onPressed: () {
                    verificationBloc.add(
                      RejectProviderVerification(userProfile.id),
                    );
                    Navigator.of(
                      context,
                    ).pop(); // Kembali ke halaman daftar setelah aksi
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKtpDisplay(BuildContext context, String ktpUrl) {
    // Print KTP URL for debugging
    debugPrint('Mencoba memuat KTP dari URL: $ktpUrl');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Foto KTP:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Center(
          child: InteractiveViewer(
            child: Image.network(
              ktpUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error memuat gambar KTP: $error');
                debugPrint('Stacktrace KTP: $stackTrace');
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Gagal memuat gambar KTP',
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
