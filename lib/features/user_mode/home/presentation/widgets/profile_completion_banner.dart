import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/profile/application/bloc/user_view_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileCompletionBanner extends StatefulWidget {
  const ProfileCompletionBanner({super.key});

  @override
  State<ProfileCompletionBanner> createState() =>
      _ProfileCompletionBannerState();
}

class _ProfileCompletionBannerState extends State<ProfileCompletionBanner>
    with SingleTickerProviderStateMixin {
  // Supabase client untuk mengambil data profil
  final _supabase = Supabase.instance.client;

  // Status kelengkapan profil
  bool _isProfileComplete = false;
  final bool _isCheckingProfile = false; // Ubah menjadi false agar tidak menampilkan loading UI saat pengecekan
  bool _isBannerVisible = true;
  final bool _forceShow = false; // Ubah menjadi false agar tidak memaksa tampilkan banner
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Key untuk menyimpan status banner di SharedPreferences
  static const String _bannerDismissedKey =
      'profile_completion_banner_dismissed';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
    // Default banner tidak terlihat sampai pengecekan profil selesai
    _isBannerVisible = false;
    _checkBannerDismissed();
    
    // Jalankan pengecekan profil di background tanpa menampilkan loading UI
    logger.d('DEBUG: Memeriksa kelengkapan profil di background...');
    _checkProfileCompleteness();
  }

  // Memeriksa apakah banner sudah ditutup sebelumnya
  Future<void> _checkBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    // Reset banner dismissed status untuk memastikan banner muncul jika profil belum lengkap
    await prefs.remove(_bannerDismissedKey);
    
    final isDismissed = prefs.getBool(_bannerDismissedKey) ?? false;
    logger.d('DEBUG Banner dismissed status: $isDismissed');

    // Jika banner sudah ditutup sebelumnya, tapi kita ingin tetap menampilkan
    // jika profil belum lengkap, maka kita tidak perlu mengubah _isBannerVisible di sini
    // Kita akan menentukan visibilitas banner berdasarkan kelengkapan profil
    
    // Komentar kode lama:
    // if (isDismissed && mounted) {
    //   setState(() {
    //     _isBannerVisible = false;
    //   });
    // }
  }

  // Menyimpan status banner ditutup
  Future<void> _saveBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bannerDismissedKey, true);
  }

  // Menutup banner dengan animasi
  void _closeBanner() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isBannerVisible = false;
        });
      }
      _saveBannerDismissed();
    });
  }

  // Memeriksa kelengkapan profil pengguna dari database
  Future<void> _checkProfileCompleteness() async {
    logger.d('DEBUG: Mulai pengecekan profil di background...');
    
    // Tambahkan delay 2 detik untuk memastikan data user sudah terdeteksi dengan benar
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      // Dapatkan user ID saat ini
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        logger.d('DEBUG: Tidak ada user yang login, banner tidak ditampilkan');
        if (mounted) {
          setState(() {
            _isProfileComplete = true; // Jika tidak ada user, jangan tampilkan banner
          });
        }
        return;
      }

      // Ambil data profil dari database
      final response = await _supabase
          .from('profiles')
          .select(
            'full_name, address_detail, provinsi, kabupaten_kota, kecamatan, desa_kelurahan',
          )
          .eq('id', currentUser.id)
          .single();

      // Debug: Tampilkan nilai response untuk debugging
      logger.d('DEBUG PROFILE DATA: ${response.toString()}');
      
      // Cek kelengkapan profil dengan pengecekan yang lebih ketat
      final hasFullName = response['full_name'] is String && 
          (response['full_name'] as String).trim().isNotEmpty;
      logger.d('DEBUG hasFullName: $hasFullName, value: ${response['full_name']}');
          
      final hasAddressDetail = response['address_detail'] is String && 
          (response['address_detail'] as String).trim().isNotEmpty;
      logger.d('DEBUG hasAddressDetail: $hasAddressDetail, value: ${response['address_detail']}');
          
      final hasKabupaten = response['kabupaten_kota'] is String && 
          (response['kabupaten_kota'] as String).trim().isNotEmpty;
      logger.d('DEBUG hasKabupaten: $hasKabupaten, value: ${response['kabupaten_kota']}');
          
      final hasKecamatan = response['kecamatan'] is String && 
          (response['kecamatan'] as String).trim().isNotEmpty;
      logger.d('DEBUG hasKecamatan: $hasKecamatan, value: ${response['kecamatan']}');
          
      final hasDesaKelurahan = response['desa_kelurahan'] is String && 
          (response['desa_kelurahan'] as String).trim().isNotEmpty;
      logger.d('DEBUG hasDesaKelurahan: $hasDesaKelurahan, value: ${response['desa_kelurahan']}');
          
      // Profil dianggap lengkap jika memiliki:
      // 1. Nama lengkap, DAN
      // 2. Alamat lengkap (kabupaten, kecamatan, desa/kelurahan, dan detail alamat)
      final hasCompleteAddress = hasKabupaten && hasKecamatan && hasDesaKelurahan && hasAddressDetail;
      logger.d('DEBUG hasCompleteAddress: $hasCompleteAddress');
      
      // Banner tidak ditampilkan jika profil sudah lengkap
      final isComplete = hasFullName && hasCompleteAddress;
      logger.d('DEBUG isComplete: $isComplete');

      if (mounted) {
        setState(() {
          _isProfileComplete = isComplete;
          // Jika profil belum lengkap, tampilkan banner
          _isBannerVisible = !isComplete;
        });
      }
    } catch (e) {
      // Jika terjadi error, jangan tampilkan banner
      if (mounted) {
        setState(() {
          _isProfileComplete = true; // Jangan tampilkan banner jika error
          _isBannerVisible = false;
        });
      }
      logger.e('Error checking profile completeness: $e');
    }
    
    logger.d('DEBUG: Pengecekan profil selesai. Banner visible: $_isBannerVisible');
  }

  // Metode untuk menampilkan banner dengan loading indicator
  Widget _buildBannerWithLoading() {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withAlpha(242),
              AppColors.primary.withAlpha(230),
              Colors.blue.shade700.withAlpha(242),
            ],
          ),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(64),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white.withAlpha(51), width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Ikon profil
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Teks ajakan dengan loading indicator
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Memeriksa Profil Anda',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mohon tunggu sebentar...',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white.withAlpha(230)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Log status banner untuk debugging
    logger.d('DEBUG BANNER STATUS: isProfileComplete: $_isProfileComplete, isBannerVisible: $_isBannerVisible, isCheckingProfile: $_isCheckingProfile');
    
    // Jika profil sudah lengkap, jangan tampilkan banner
    // Kita tidak lagi memeriksa _isBannerVisible di sini karena kita ingin banner selalu muncul jika profil belum lengkap
    if (_isProfileComplete) {
      return const SizedBox.shrink();
    }
    
    return BlocBuilder<UserViewBloc, UserViewState>(
      builder: (context, state) {
        // Jika sedang memeriksa profil, tetap tampilkan banner dengan loading indicator
        if (_isCheckingProfile) {
          return Padding(
            padding: const EdgeInsets.only(top: 210.0),
            child: _buildBannerWithLoading(),
          );
        }

        // Jika profil sudah lengkap atau banner ditutup, tidak tampilkan banner
        // Kecuali jika _forceShow true (setelah login/registrasi)
        if ((_isProfileComplete || !_isBannerVisible) && !_forceShow) {
          return const SizedBox.shrink();
        }

        // Banner utama dengan padding top 200px
        return Padding(
          padding: const EdgeInsets.only(top: 200.0),
          child: FadeTransition(
            opacity: _animation,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Elemen dekoratif abstrak di luar konten utama
                Positioned(
                  right: -20,
                  top: -60,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: -15,
                  bottom: -15,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Kontainer utama banner
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withAlpha(242),
                        AppColors.primary.withAlpha(230),
                        Colors.blue.shade700.withAlpha(242),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(64),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withAlpha(51),
                      width: 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Ikon profil
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(51),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Teks ajakan
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lengkapi Profil Anda',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lengkapi profil dan alamat kamu sekarang!',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.white.withAlpha(230),
                                        ),
                                    softWrap: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: () {
                              // Pastikan route sudah sesuai dengan router aplikasi Anda
                              context.push('/profile/edit');
                              _closeBanner();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Edit Profil'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tombol close
                Positioned(
                  top: 6,
                  right: 8,
                  child: InkWell(
                    onTap: _closeBanner,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 248, 1, 1).withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color.fromRGBO(254, 246, 1, 1),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
