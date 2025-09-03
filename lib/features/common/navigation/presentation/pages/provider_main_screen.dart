import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_bloc.dart';
import 'package:klik_jasa/features/common/profile/application/bloc/user_view_bloc.dart';
import 'package:klik_jasa/injection_container.dart';
import 'package:klik_jasa/routes/app_router.dart';

class ProviderMainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ProviderMainScreen({super.key, required this.navigationShell});

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  final Logger _logger = Logger();
  void _onItemTapped(int index) {
    // Jika tab dasbor (index 0) ditekan, tutup halaman notifikasi jika terbuka
    if (index == 0) {
      // Periksa apakah ada halaman notifikasi yang terbuka
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        // Cek apakah halaman teratas adalah halaman notifikasi
        navigator.popUntil((route) {
          // Tutup halaman notifikasi jika ditemukan
          return !(route.settings.name?.contains('NotificationScreen') ?? false);
        });
      }
    }
    
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  List<BottomNavigationBarItem> _buildProviderItems(BuildContext context) {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: AppStrings.navPenyediaDasbor,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.inbox_outlined),
        activeIcon: Icon(Icons.inbox),
        label: AppStrings.navPenyediaPesanan,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.build_outlined),
        activeIcon: Icon(Icons.build),
        label: AppStrings.navPenyediaLayanan,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_outlined),
        activeIcon: Icon(Icons.chat),
        label: 'Chat',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: AppStrings.profil,
      ),
    ];
  }

  int _getValidCurrentIndex() {
    final shellIndex = widget.navigationShell.currentIndex;
    // Ambil item aktual untuk memastikan kita mendapatkan panjang yang benar saat ini
    final List<BottomNavigationBarItem> currentItems = _buildProviderItems(context);
    final itemCount = currentItems.length;

    // Log nilai sebelum pemeriksaan
    _logger.d('ProviderMainScreen._getValidCurrentIndex: shellIndex = $shellIndex, itemCount = $itemCount');

    if (shellIndex >= 0 && shellIndex < itemCount) {
      _logger.d('ProviderMainScreen._getValidCurrentIndex: Returning shellIndex = $shellIndex (valid)');
      return shellIndex;
    }
    
    _logger.w('ProviderMainScreen._getValidCurrentIndex: Warning! Invalid shellIndex ($shellIndex) for itemCount ($itemCount). Defaulting to 0.');
    return 0; 
  }

  @override
  Widget build(BuildContext context) {
    // Bungkus dengan MultiBlocProvider untuk menyediakan NotificationBloc di level atas
    return MultiBlocProvider(
      providers: [
        // Tambahkan NotificationBloc di level atas agar tersedia untuk semua branch
        BlocProvider<NotificationBloc>(
          create: (context) => sl<NotificationBloc>(),
        ),
      ],
      child: BlocListener<UserViewBloc, UserViewState>(
        listenWhen: (previous, current) =>
            previous.currentViewMode != current.currentViewMode,
        listener: (context, state) {
          if (state.currentViewMode == UserViewMode.pengguna) {
            // Pengguna telah beralih kembali ke mode pengguna.
            // Navigasikan ke titik masuk shell pengguna.
            // Pastikan navigasi terjadi setelah build selesai jika ada rebuild yang dipicu
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) { // Selalu baik untuk memeriksa mounted dalam callback async
                context.go(AppRouter.homeRoute);
              }
            });
          }
        },
        child: Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            items: _buildProviderItems(context),
            currentIndex: _getValidCurrentIndex(),
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}