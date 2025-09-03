import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/profile/application/bloc/user_view_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Widget yang menampilkan banner status penyedia jasa di halaman beranda
/// berdasarkan status user saat ini.
class ProviderStatusBannerWidget extends StatefulWidget {
  const ProviderStatusBannerWidget({super.key});

  @override
  State<ProviderStatusBannerWidget> createState() => _ProviderStatusBannerWidgetState();
}

class _ProviderStatusBannerWidgetState extends State<ProviderStatusBannerWidget> {
  bool _isLoading = true;
  String? _providerStatus;
  bool _hasLocalServices = true; // Default: anggap ada layanan di lokasi user
  
  @override
  void initState() {
    super.initState();
    _fetchUserProviderStatus();
  }

  /// Mengambil status provider dari user saat ini
  /// Mendapatkan lokasi (kabupaten/kota) user dari database
  Future<String?> _getUserLocation(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('kabupaten_kota')
          .eq('id', userId)
          .single();
      
      return data['kabupaten_kota'] as String?;
    } catch (e) {
      logger.e('Error mengambil lokasi user: $e');
      return null;
    }
  }

  Future<void> _fetchUserProviderStatus() async {
    if (!mounted) return;
    
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final userId = authState.user.id;
    
    try {
      // Ambil status provider dari profil user
      final data = await Supabase.instance.client
          .from('profiles')
          .select('provider_verification_status')
          .eq('id', userId)
          .single();
      
      // Cek apakah ada layanan di lokasi user
      bool hasLocalServices = true;
      
      if (!mounted) return;
      final userViewState = context.read<UserViewBloc>().state;
      
      if (!userViewState.isLoading) { // UserViewState selalu bertipe UserViewState, jadi tidak perlu pengecekan tipe
        // Dapatkan lokasi user dari state UserViewState
        final String? kabupatenKota = await _getUserLocation(userId);
        
        if (kabupatenKota != null && kabupatenKota.isNotEmpty) {
          // Cek apakah ada layanan di kabupaten/kota user
          final serviceCountResult = await Supabase.instance.client
              .from('services')
              .select('id')
              .eq('kabupaten_kota', kabupatenKota)
              .limit(1)
              .maybeSingle();
          
          hasLocalServices = serviceCountResult != null;
        }
      }
      
      if (!mounted) return;
      setState(() {
        _providerStatus = data['provider_verification_status']?.toString();
        _hasLocalServices = hasLocalServices;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error mengambil status provider: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Jika user adalah penyedia jasa terverifikasi
    if (_providerStatus == 'verified') {
      return _buildProviderDashboardButton();
    }
    
    // Jika user sedang menunggu verifikasi
    if (_providerStatus == 'pending') {
      return _buildPendingStatusWidget();
    }
    
    // Jika pengajuan user ditolak
    if (_providerStatus == 'rejected') {
      return _buildRejectedStatusWidget();
    }
    
    // Jika di lokasi user belum ada layanan yang tersedia
    if (!_hasLocalServices) {
      return _buildBecomeProviderCTA();
    }
    
    // Default: user belum mendaftar sebagai penyedia jasa
    return _buildRegisterProviderButton();
  }

  /// Widget tombol untuk mendaftar sebagai penyedia jasa
  Widget _buildRegisterProviderButton() {
    return ElevatedButton(
      onPressed: () {
        context.push('/profile/provider-registration');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade600,
        foregroundColor: Colors.white,
      ),
      child: const Text('Daftar Sekarang'),
    );
  }

  /// Widget untuk menampilkan status pengajuan yang sedang pending
  Widget _buildPendingStatusWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pengajuan Penyedia Jasa Sedang Diproses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Kami sedang memverifikasi data Anda. Proses ini biasanya memakan waktu 1-3 hari kerja.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.push('/profile/help');
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade700,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Hubungi Dukungan'),
          ),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan status pengajuan yang ditolak
  Widget _buildRejectedStatusWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pengajuan Penyedia Jasa Ditolak',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Mohon maaf, pengajuan Anda tidak dapat disetujui. Silakan periksa kembali data Anda dan ajukan ulang.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  context.push('/profile/help');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Hubungi Dukungan'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.push('/profile/provider-registration');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ulangi Pengajuan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget tombol untuk mengakses dashboard penyedia jasa
  Widget _buildProviderDashboardButton() {
    return ElevatedButton(
      onPressed: () {
        // Navigasi ke dashboard penyedia jasa
        context.go('/provider');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      child: const Text('Akses Dasbor Penyedia Jasa'),
    );
  }

  /// Widget ajakan untuk menjadi penyedia jasa di lokasi yang belum ada layanan
  /// atau untuk posting layanan pertama jika user sudah terverifikasi
  Widget _buildBecomeProviderCTA() {
    // Cek apakah user sudah terverifikasi sebagai penyedia jasa
    final bool isVerifiedProvider = _providerStatus == 'verified';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isVerifiedProvider ? Icons.add_circle_outline : Icons.lightbulb_outline, 
                  color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isVerifiedProvider
                      ? 'Posting Layanan Pertama Anda!'
                      : 'Jadilah Penyedia Jasa Pertama di Lokasi Anda!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isVerifiedProvider
                ? 'Layanan penyedia jasa di daerah anda belum tersedia nih... \nYuk, Mulai posting Layanan Jasa pertamamu dan dapatkan Penghasilan tak terbatas bersama KlikJasa!'
                : 'Belum ada layanan tersedia di lokasi Anda. Ini kesempatan bagus untuk menjadi penyedia jasa pertama dan mendapatkan pelanggan lebih banyak!',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // Jika sudah terverifikasi, arahkan ke dashboard penyedia
                // Jika belum, arahkan ke halaman pendaftaran
                context.go(isVerifiedProvider ? '/provider' : '/profile/provider-registration');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(isVerifiedProvider ? 'Masuk Ke Dasbor Penyedia' : 'Daftar Sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}
