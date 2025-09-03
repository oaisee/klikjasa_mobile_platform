import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/features/common/widgets/service_card_adapter.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/provider_profile_cubit.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/provider_profile_state.dart';
// Import lainnya tetap sama...

class ProviderProfileScreen extends StatefulWidget {
  final String providerId;
  final String? providerName;

  const ProviderProfileScreen({
    super.key,
    required this.providerId,
    this.providerName,
  });

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProviderProfileCubit>().fetchProviderProfile(widget.providerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.providerName ?? 'Profil Penyedia Jasa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<ProviderProfileCubit, ProviderProfileState>(
        builder: (context, state) {
          if (state is ProviderProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is ProviderProfileLoaded) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProviderHeader(state),
                  _buildProviderInfo(state),
                  _buildProviderServices(state),
                  _buildProviderReviews(state),
                ],
              ),
            );
          } else if (state is ProviderProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProviderProfileCubit>().fetchProviderProfile(widget.providerId);
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  // Fungsi-fungsi lain tetap sama...

  Widget _buildProviderServices(ProviderProfileLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (state.services.isEmpty)
            const Center(
              child: Text('Belum ada layanan yang ditawarkan'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.services.length,
              itemBuilder: (context, index) {
                final service = state.services[index];
                // Refaktor: Menggunakan ServiceCardAdapter.fromMap
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ServiceCardAdapter.fromMap(
                    serviceMap: service,
                    onTap: () {
                      // Navigasi kembali ke detail layanan
                      context.pop();
                    },
                    isListView: true, // Menggunakan tampilan list
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan header profil penyedia jasa
  Widget _buildProviderHeader(ProviderProfileLoaded state) {
    final avatarUrl = state.profileData['avatar_url'] as String?;
    final fullName = state.profileData['full_name'] as String? ?? 'Nama tidak tersedia';
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).primaryColor.withAlpha(25),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[300],
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${state.averageRating.toStringAsFixed(1)} (${state.reviewCount} ulasan)',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan informasi penyedia jasa
  Widget _buildProviderInfo(ProviderProfileLoaded state) {
    final address = state.profileData['address'] as String? ?? 'Alamat tidak tersedia';
    final phone = state.profileData['phone_number'] as String? ?? 'Nomor telepon tidak tersedia';
    final verificationStatus = state.profileData['provider_verification_status'] as String? ?? 'unverified';
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Penyedia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _infoItem(Icons.location_on, 'Alamat', address),
          const Divider(),
          _infoItem(Icons.phone, 'Telepon', phone),
          const Divider(),
          _infoItem(
            Icons.verified_user,
            'Status Verifikasi',
            verificationStatus == 'verified' ? 'Terverifikasi' : 'Belum Terverifikasi',
            valueColor: verificationStatus == 'verified' ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan ulasan penyedia jasa
  Widget _buildProviderReviews(ProviderProfileLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ulasan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.reviewCount > 0)
                TextButton(
                  onPressed: () {
                    // TODO: Implementasi navigasi ke halaman semua ulasan
                  },
                  child: const Text('Lihat Semua'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.reviewCount == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Belum ada ulasan'),
              ),
            )
          else
            // TODO: Implementasi daftar ulasan
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Memuat ulasan...'),
              ),
            ),
        ],
      ),
    );
  }

  // Helper widget untuk item informasi
  Widget _infoItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
