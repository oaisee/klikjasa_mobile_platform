import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart'; // Impor GoRouter
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthState; // Menggunakan ini dengan hide AuthState
import 'package:intl/intl.dart'; // Untuk format mata uang
import 'package:klik_jasa/features/common/auth/domain/entities/user_entity.dart';

// Core
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/widgets/logout_dialog.dart';
import 'package:klik_jasa/core/widgets/profile_menu_item.dart';

// App Routes
import 'package:klik_jasa/routes/app_router.dart';

// Features - Auth
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart'; // Path yang benar untuk AuthBloc yang digunakan

// Features - Profile & Navigasi dari Profile
import 'package:klik_jasa/features/common/profile/presentation/pages/edit_profile_screen.dart';
import 'package:klik_jasa/features/common/profile/presentation/pages/order_history_screen.dart';
import 'package:klik_jasa/features/common/profile/presentation/pages/settings_screen.dart';
import 'package:klik_jasa/features/common/profile/presentation/pages/help_screen.dart';
import 'package:klik_jasa/features/common/utils/app_message_utils.dart';
// MessageType sudah tersedia di app_message_utils.dart
import 'package:klik_jasa/features/common/profile/presentation/pages/top_up_screen.dart';
import 'package:klik_jasa/features/common/profile/presentation/widgets/address_info_card.dart'; // Import untuk AddressInfoCard
import 'package:klik_jasa/features/common/chat/presentation/widgets/admin_chat_button.dart'; // Import untuk AdminChatButton
import 'package:klik_jasa/features/provider_mode/statistics/presentation/pages/provider_statistics_screen.dart'; // Import untuk ProviderStatisticsScreen
import 'package:klik_jasa/features/provider_mode/store_settings/presentation/pages/store_settings_screen.dart'; // Import untuk StoreSettingsScreen

// Features - Profile (Region Bloc & Dependencies - Path Baru)
import 'package:klik_jasa/injection_container.dart'
    as di; // Import service locator
import 'package:klik_jasa/features/common/profile/presentation/bloc/region/region_bloc.dart';
// import 'package:klik_jasa/features/common/profile/presentation/bloc/region/region_event.dart'; // Dihapus karena 'part-of' directive

// Features - Profile (User View Bloc)
import 'package:klik_jasa/features/common/profile/application/bloc/user_view_bloc.dart';

class ProfileScreen extends StatefulWidget {
  final AuthBloc authBloc;

  const ProfileScreen({super.key, required this.authBloc});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;
  final _supabase = Supabase.instance.client;
  late AnimationController _animationControllerHeader;
  late Animation<double> _fadeAnimationHeader;

  @override
  void initState() {
    super.initState();
    _animationControllerHeader = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimationHeader = CurvedAnimation(
      parent: _animationControllerHeader,
      curve: Curves.easeIn,
    );
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProfile = true;
    });
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Periksa mounted lagi di dalam callback
              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(content: Text('Pengguna tidak ditemukan. Silakan login kembali.')),
              // );
            }
          });
          setState(() {
            _isLoadingProfile = false;
          });
        }
        return;
      }

      // 1. Ambil atau buat data dari tabel 'profiles'
      Map<String, dynamic>? profileData = await _supabase
          .from('profiles')
          .select(
            'id, full_name, avatar_url, phone_number, address_detail, postal_code, provinsi, kabupaten_kota, kecamatan, desa_kelurahan, is_provider, latitude, longitude, provider_verification_status',
          )
          .eq('id', userId)
          .maybeSingle();

      // Ambil saldo dari tabel user_balances
      final balanceDataResponse = await _supabase
          .from('user_balances')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();

      num currentBalance = 0.00;
      if (balanceDataResponse != null &&
          balanceDataResponse['balance'] is num) {
        currentBalance = (balanceDataResponse['balance'] is num)
            ? balanceDataResponse['balance']
            : 0.00;
      } else if (balanceDataResponse != null &&
          balanceDataResponse['balance'] is String) {
        // Jika saldo disimpan sebagai string, coba parse
        currentBalance =
            num.tryParse(balanceDataResponse['balance']?.toString() ?? '') ??
            0.00;
      }
      // Tambahkan saldo ke profileData
      if (profileData != null) {
        profileData['balance'] = currentBalance;
      }

      if (mounted) {
        setState(() {
          _userProfile =
              profileData; // Sekarang profileData sudah termasuk balance
        });
      }
      // Catatan: Jika ada kegagalan dalam mengambil profileData,
      // error tersebut seharusnya sudah ditangani oleh blok catch di bawah.
    } catch (e) {
      if (mounted) {
        // Refaktor: Menggunakan AppMessageUtils untuk menampilkan error
        AppMessageUtils.showNetworkError(
          context: context,
          message: 'Gagal memuat profil: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
        // Hanya mulai animasi jika profil berhasil dimuat dan animasi belum berjalan
        if (_userProfile != null &&
            !_animationControllerHeader.isAnimating &&
            !_animationControllerHeader.isCompleted) {
          _animationControllerHeader.forward();
        }
      }
    }
  }

  @override
  void dispose() {
    _animationControllerHeader.dispose();
    super.dispose();
  }

  Widget _buildProviderStatusWidget(String status) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusText = AppStrings.statusPendingShort;
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      case 'verified':
        statusText = AppStrings.statusVerifiedShort;
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusText = AppStrings.statusRejectedShort;
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10.0),
      padding: const EdgeInsets.all(2.0), // Ketebalan border gradient
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: LinearGradient(
          colors: [Colors.white.withAlpha(179), Colors.white.withAlpha(77)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(
            64,
          ), // Latar belakang semi-transparan untuk konten
          borderRadius: BorderRadius.circular(
            10.0,
          ), // Sedikit lebih kecil dari border luar
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Agar kontainer menyesuaikan ukuran konten
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: statusColor, size: 16),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors
                    .white, // Warna teks putih agar kontras dengan latar semi-transparan
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    // Shadow tipis untuk keterbacaan teks
                    blurRadius: 1.0,
                    color: Colors.black.withAlpha(128),
                    offset: const Offset(0.5, 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserEntity user) {
    return FadeTransition(
      opacity: _fadeAnimationHeader,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF02A8C2),
              const Color.from(alpha: 1, red: 0, green: 0.486, blue: 0.569),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.end, // Memusatkan konten secara vertikal
          crossAxisAlignment:
              CrossAxisAlignment.center, // Memusatkan konten secara horizontal
          children: [
            const SizedBox(height: 25), // Konten diturunkan
            CircleAvatar(
              // Border putih
              radius: 52, // Radius luar (foto + border)
              backgroundColor: AppColors.white,
              child: CircleAvatar(
                radius: 50, // Radius foto
                backgroundColor: AppColors.accent.withAlpha(51),
                backgroundImage:
                    (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                    ? NetworkImage(user.avatarUrl!)
                    : (_userProfile != null &&
                          _userProfile!['avatar_url'] != null &&
                          _userProfile!['avatar_url'].toString().isNotEmpty)
                    ? NetworkImage(_userProfile!['avatar_url'])
                    : null,
                child:
                    (user.avatarUrl == null || user.avatarUrl!.isEmpty) &&
                        (_userProfile == null ||
                            _userProfile!['avatar_url'] == null ||
                            _userProfile!['avatar_url'].toString().isEmpty)
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.white.withAlpha(204),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _isLoadingProfile
                ? const SizedBox.shrink() // Jangan tampilkan apa-apa saat loading nama
                : Text(
                    user.fullName ??
                        _userProfile?['full_name'] as String? ??
                        user.email ??
                        AppStrings.penggunaKlikJasa,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
            const SizedBox(height: 8),

            Text(
              // Jika nama lengkap ada dan email ada, tampilkan email.
              // Jika nama lengkap tidak ada, email sudah ditampilkan di atas, jadi bisa tampilkan placeholder atau email lagi dengan style berbeda.
              // Untuk konsistensi, kita tetap tampilkan email atau placeholder jika email null.
              user.email ?? AppStrings.tidakAdaEmail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withAlpha(204),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            if (_userProfile?['provider_verification_status'] != null &&
                _userProfile!['provider_verification_status'] != 'unverified')
              _buildProviderStatusWidget(
                _userProfile!['provider_verification_status'] as String,
              ),
            const SizedBox(height: 5), // Jarak bawah dikurangi
          ],
        ),
      ),
    );
  }

  Widget _buildSaldoCard(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimationHeader,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.saldoAnda,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  // Menggunakan BlocSelector untuk mendapatkan saldo dari UserViewBloc secara realtime
                  BlocSelector<UserViewBloc, UserViewState, double?>(
                    selector: (state) => state.saldo,
                    builder: (context, balance) {
                      if (balance == null) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        );
                      }
                      return Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(balance),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      );
                    },
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_card, size: 18),
                label: const Text(AppStrings.topUp),
                onPressed: () {
                  _navigateToTopUp(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context, UserViewState userViewState) {
    final num currentBalance = _userProfile?['balance'] ?? 0;

    // Menu untuk Mode Penyedia
    final List<Map<String, dynamic>> providerMenuItems = [
      {
        'icon': Icons.bar_chart_outlined,
        'title': 'Statistik Kinerja',
        'onTap': () => _navigateToProviderStatistics(context),
      },
      {
        'icon': Icons.store_outlined,
        'title': 'Pengaturan Layanan',
        'onTap': () => _navigateToStoreSettings(context),
      },
    ];

    // Menu untuk Mode Pengguna
    final List<Map<String, dynamic>> userMenuItems = [
      {
        'icon': Icons.favorite_outline,
        'title': 'Wishlist',
        'onTap': () => _navigateToWishlist(context),
      },
      {
        'icon': Icons.history_outlined,
        'title': AppStrings.riwayatPesanan,
        'onTap': () => _navigateToOrderHistory(context),
      },
    ];

    if (!userViewState.isVerifiedProvider &&
        !userViewState.isPendingVerification) {
      userMenuItems.add({
        'icon': Icons.storefront_outlined,
        'title': AppStrings.registerAsProvider,
        'onTap': () => _handleProviderRegistration(context, currentBalance),
      });
    }

    // Menu Umum (selalu ada)
    final List<Map<String, dynamic>> commonMenuItems = [
      {
        'icon': Icons.settings_outlined,
        'title': AppStrings.pengaturan,
        'onTap': () => _navigateToSettings(context),
      },
      {
        'icon': Icons.help_outline,
        'title': AppStrings.bantuan,
        'onTap': () => _navigateToHelp(context),
      },
      {
        'icon': Icons.support_agent,
        'title': 'Hubungi Admin',
        'onTap': () => _showAdminChatButton(context),
      },
    ];

    bool isProviderMode =
        userViewState.currentViewMode == UserViewMode.penyedia;
    List<Map<String, dynamic>> activeMenuItems = isProviderMode
        ? providerMenuItems
        : userMenuItems;

    return FadeTransition(
      opacity: _fadeAnimationHeader,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeMenuItems.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final item = activeMenuItems[index];
                  return ProfileMenuItem(
                    icon: item['icon'] as IconData,
                    iconColor: AppColors.primary,
                    title: item['title'] as String,
                    onTap: item['onTap'] as VoidCallback,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: commonMenuItems.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  final item = commonMenuItems[index];
                  return ProfileMenuItem(
                    icon: item['icon'] as IconData,
                    iconColor: Colors.grey[700],
                    title: item['title'] as String,
                    onTap: item['onTap'] as VoidCallback,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Placeholder Navigation Methods ---
  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<RegionBloc>(
          create: (context) => di.sl<RegionBloc>()..add(FetchProvinces()),
          child: const EditProfileScreen(),
        ),
      ),
    );
  }

  void _navigateToOrderHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
    );
  }

  void _navigateToWishlist(BuildContext context) {
    context.go('/wishlist');
  }

  void _navigateToProviderStatistics(BuildContext context) {
    // Gunakan Navigator.push untuk tetap dalam shell provider
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProviderStatisticsScreen()),
    );
  }

  void _navigateToStoreSettings(BuildContext context) {
    // Gunakan Navigator.push untuk tetap dalam shell provider
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoreSettingsScreen()),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToHelp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpScreen()),
    );
  }

  // Metode untuk menampilkan bottom sheet chat admin
  void _showAdminChatBottomSheet(
    BuildContext context,
    String adminUuid,
    String adminName,
  ) {
    // Gunakan Future.delayed untuk menghindari konflik dengan Navigator.pop sebelumnya
    Future.delayed(Duration.zero, () {
      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (bottomSheetContext) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hubungi Admin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tim admin kami siap membantu Anda dengan pertanyaan atau masalah yang Anda hadapi.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AdminChatButton(
                adminUuid:
                    adminUuid, // Gunakan UUID admin yang valid dari database
                adminName: adminName,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    });
  }

  void _showAdminChatButton(BuildContext context) async {
    // Ambil UUID admin yang valid dari tabel profiles berdasarkan role='admin'
    final supabase = Supabase.instance.client;

    if (!mounted) return;

    // Simpan context reference
    final contextRef = context;

    // Tampilkan loading dialog
    BuildContext? dialogContext;
    showDialog(
      context: contextRef,
      barrierDismissible: false,
      builder: (BuildContext c) {
        dialogContext = c;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Gunakan fungsi RPC (Remote Procedure Call) untuk mengatasi masalah RLS
      // Buat fungsi PostgreSQL di Supabase yang dapat mengakses data admin
      // Contoh fungsi: create or replace function get_admin_user() returns json as $$ select json_build_object('id', id, 'full_name', full_name, 'role', role) from profiles where role = 'admin' limit 1; $$ language sql security definer;

      // Panggil fungsi RPC
      var response = await supabase.rpc('get_admin_user').maybeSingle();
      debugPrint('DEBUG: Hasil RPC get_admin_user: $response');

      // Jika RPC tidak tersedia atau belum dibuat, gunakan pendekatan fallback
      if (response == null) {
        debugPrint(
          'DEBUG: RPC tidak tersedia atau tidak mengembalikan hasil, mencoba query langsung',
        );

        // Coba query langsung dengan berbagai kemungkinan
        var directResponse = await supabase
            .from('profiles')
            .select('id, full_name, role')
            .eq('role', 'admin')
            .limit(1)
            .maybeSingle();

        debugPrint(
          'DEBUG: Hasil query admin dengan eq("role", "admin"): $directResponse',
        );

        // Jika tidak ditemukan dengan exact match, coba dengan full_name = 'Admin'
        if (directResponse == null) {
          directResponse = await supabase
              .from('profiles')
              .select('id, full_name, role')
              .eq('full_name', 'Admin')
              .limit(1)
              .maybeSingle();

          debugPrint(
            'DEBUG: Hasil query admin dengan eq("full_name", "Admin"): $directResponse',
          );
        }

        // Gunakan hasil query langsung jika ada
        if (directResponse != null) {
          response = directResponse;
        }
      }

      // Tutup dialog loading dengan aman
      if (dialogContext != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (Navigator.canPop(dialogContext!)) {
            Navigator.pop(dialogContext!);
          }
        });
      }

      // Periksa apakah context masih valid
      if (!mounted) return;

      if (response == null) {
        // Jika tidak ditemukan dengan semua query, coba ambil user pertama dari database sebagai fallback
        final allUsers = await supabase
            .from('profiles')
            .select('id, full_name, role')
            .limit(1)
            .maybeSingle();

        if (!mounted) return;

        if (allUsers != null) {
          debugPrint(
            'DEBUG: Menggunakan user pertama sebagai fallback admin: ${allUsers['full_name']} (${allUsers['id']})',
          );

          // Tampilkan pesan ke user bahwa menggunakan user pertama sebagai admin
          // Refaktor: Menggunakan AppMessageUtils untuk menampilkan info
          if (!mounted) return;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            AppMessageUtils.showSnackbar(
              context: contextRef,
              message:
                  'Menggunakan user pertama sebagai admin karena admin tidak ditemukan',
              type: MessageType.info,
            );
          });

          // Gunakan UUID user pertama sebagai admin
          final adminUuid = allUsers['id'];
          final adminName = allUsers['full_name'] ?? 'Admin Klik Jasa';

          // Lanjutkan dengan menampilkan bottom sheet admin chat
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showAdminChatBottomSheet(contextRef, adminUuid, adminName);
          });
          return;
        } else {
          // Jika tidak ada user sama sekali di database
          debugPrint(
            'DEBUG: Tidak ada user di database yang dapat digunakan sebagai admin',
          );

          // Refaktor: Menggunakan AppMessageUtils untuk menampilkan warning
          if (!mounted) return;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            AppMessageUtils.showSnackbar(
              context: contextRef,
              message:
                  'Tidak ada user di database yang dapat digunakan sebagai admin',
              type: MessageType.warning,
            );
          });
          return;
        }
      }

      // Jika admin ditemukan, gunakan data dari database
      final String adminUuid = response['id'];
      final String adminName = response['full_name'] ?? 'Admin Klik Jasa';

      // Tampilkan bottom sheet admin chat
      if (!mounted) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showAdminChatBottomSheet(contextRef, adminUuid, adminName);
      });
    } catch (e) {
      // Tutup dialog loading dengan aman
      if (dialogContext != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (Navigator.canPop(dialogContext!)) {
            Navigator.pop(dialogContext!);
          }
        });
      }

      // Periksa apakah context masih valid
      if (!mounted) return;

      // Refaktor: Menggunakan AppMessageUtils untuk menampilkan error
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          AppMessageUtils.showNetworkError(
            context: contextRef,
            message: 'Gagal memuat data admin: ${e.toString()}',
          );
        });
      }
    }
  }

  void _navigateToTopUp(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TopUpScreen()),
    );
    if (!mounted) return;
    if (result == true) {
      // Jika top up berhasil (TopUpScreen mengirim true), muat ulang data profil
      _fetchUserProfile();
    }
  }

  void _handleProviderRegistration(BuildContext context, num currentBalance) {
    if (currentBalance <= 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(AppStrings.saldoTidakCukup),
          content: Text(AppStrings.keteranganSaldoTidakCukup),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.ok),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _navigateToTopUp(context);
              },
              child: const Text(AppStrings.isiSaldo),
            ),
          ],
        ),
      );
      return;
    }

    // Langsung navigasi ke halaman pendaftaran penyedia jasa tanpa popup pilihan versi
    context.push('/profile/provider-registration');
  }

  Widget _buildAddressCard(
    BuildContext context,
    Map<String, dynamic>? userProfile,
  ) {
    if (userProfile == null) {
      return const SizedBox.shrink(); // Jangan tampilkan apa pun jika profil null
    }
    // Ambil data alamat dari userProfile dengan aman
    final String? detailJalan = userProfile['address_detail'] as String?;
    final String? desaKelurahan = userProfile['desa_kelurahan'] as String?;
    final String? kecamatan = userProfile['kecamatan'] as String?;
    final String? kabupatenKota = userProfile['kabupaten_kota'] as String?;
    final String? provinsi = userProfile['provinsi'] as String?;
    final String? kodePos = userProfile['postal_code'] as String?;
    final String? phoneNumber = userProfile['phone_number'] as String?;

    return AddressInfoCard(
      detailJalan: detailJalan,
      desaKelurahan: desaKelurahan,
      kecamatan: kecamatan,
      kabupatenKota: kabupatenKota,
      provinsi: provinsi,
      kodePos: kodePos,
      phoneNumber: phoneNumber,
      onEditProfilePressed: () => _navigateToEditProfile(context),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthBloc authBloc) {
    return FadeTransition(
      opacity: _fadeAnimationHeader,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.logout, color: AppColors.white),
          label: const Text(
            AppStrings.logout,
            style: TextStyle(color: AppColors.white),
          ),
          onPressed: () async {
            // Gunakan dialog konfirmasi logout
            final bool confirmLogout = await showLogoutDialog(context);
            if (confirmLogout && context.mounted) {
              authBloc.add(AuthLogoutRequested());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeToggleSwitch(
    BuildContext context,
    UserViewState userViewState,
  ) {
    // Tidak perlu cek isVerifiedProvider lagi karena sudah dicek sebelum memanggil widget ini
    return SwitchListTile(
      title: Text(
        userViewState.currentViewMode == UserViewMode.penyedia
            ? AppStrings
                  .providerModeActive // Ganti dengan AppStrings jika ada
            : AppStrings
                  .activateProviderMode, // Ganti dengan AppStrings jika ada
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        userViewState.currentViewMode == UserViewMode.penyedia
            ? AppStrings
                  .viewingAsProvider // Ganti dengan AppStrings jika ada
            : AppStrings
                  .switchToManageServices, // Ganti dengan AppStrings jika ada
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      value: userViewState.currentViewMode == UserViewMode.penyedia,
      onChanged: (bool newValue) {
        final newMode = newValue
            ? UserViewMode.penyedia
            : UserViewMode.pengguna;
        context.read<UserViewBloc>().add(
          UserViewSwitchModeRequested(requestedMode: newMode),
        );
      },
      secondary: Icon(
        userViewState.currentViewMode == UserViewMode.penyedia
            ? Icons.storefront_rounded
            : Icons.person_outline_rounded,
        color: Theme.of(context).primaryColor,
      ),
      activeColor: Theme.of(context).primaryColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserViewBloc, UserViewState>(
      builder: (context, userViewState) {
        // userViewState kini tersedia di sini
        // Kita juga bisa memanggil _fetchUserProfile jika user ID berubah dan userViewState belum terinisialisasi untuk user baru
        // Namun, UserViewBloc sudah listen ke AuthBloc, jadi ini seharusnya sudah ditangani.

        return Scaffold(
          backgroundColor:
              AppColors.scaffoldBackground, // Warna latar belakang umum
          body: BlocBuilder<AuthBloc, AuthState>(
            bloc: widget.authBloc, // Gunakan AuthBloc yang diinjeksi

            builder: (context, state) {
              if (state is AuthLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is AuthAuthenticated) {
                _animationControllerHeader
                    .forward(); // Pastikan animasi dimulai saat data siap
                return CustomScrollView(
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: _buildProfileHeader(context, state.user),
                    ),
                    // VIEW MODE TOGGLE (jika terverifikasi) - DIPINDAHKAN KE SINI
                    if (userViewState.isVerifiedProvider)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            8.0,
                            16.0,
                            0,
                          ), // Padding agar card tidak mentok
                          child: Card(
                            elevation:
                                userViewState.currentViewMode ==
                                    UserViewMode.penyedia
                                ? 1
                                : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            color:
                                userViewState.currentViewMode ==
                                    UserViewMode.penyedia
                                ? AppColors.accent.withAlpha(20)
                                : Theme.of(context).cardColor,
                            child: _buildViewModeToggleSwitch(
                              context,
                              userViewState,
                            ),
                          ),
                        ),
                      ),
                    if (userViewState
                        .isVerifiedProvider) // Spacer jika toggle ada - DIPINDAHKAN KE SINI
                      SliverToBoxAdapter(child: const SizedBox(height: 8)),
                    SliverToBoxAdapter(child: _buildSaldoCard(context)),
                    SliverToBoxAdapter(
                      child: _buildAddressCard(
                        context,
                        _userProfile,
                      ), // Tambahkan AddressInfoCard di sini
                    ),
                    SliverToBoxAdapter(
                      child: const SizedBox(height: 10),
                    ), // Spasi
                    SliverToBoxAdapter(
                      child: _buildProfileMenu(context, userViewState),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildLogoutButton(context, widget.authBloc),
                      ),
                    ),
                  ],
                );
              }
              // AuthUnauthenticated atau state lainnya
              _animationControllerHeader
                  .reset(); // Reset animasi jika tidak terautentikasi
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        AppStrings.silakanLoginUntukMelihatProfil,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          context.go(AppRouter.loginRoute);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(AppStrings.login),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ); // Tutup Scaffold
      }, // Tutup BlocBuilder<UserViewBloc, UserViewState> builder
    ); // Tutup BlocBuilder<UserViewBloc, UserViewState>
  }
}
