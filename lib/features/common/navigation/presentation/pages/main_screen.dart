import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/notifications/presentation/services/notification_service.dart';
import 'package:klik_jasa/features/common/profile/application/bloc/user_view_bloc.dart';
import 'package:go_router/go_router.dart'; // Impor GoRouter // Untuk addPostFrameCallback
import 'package:logger/logger.dart';

// --- Placeholder Screens untuk Mode Penyedia ---
// Definisi DasborPenyediaScreen placeholder dihapus karena implementasi sebenarnya sudah diimpor.

class LayananPenyediaScreen extends StatelessWidget {
  const LayananPenyediaScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Halaman Layanan Penyedia')));
}

class PesananPenyediaScreen extends StatelessWidget {
  const PesananPenyediaScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Halaman Pesanan Penyedia')));
}
// --- Akhir Placeholder Screens ---

// Definisi KategoriScreen dan PesananPenggunaScreen telah dipindahkan ke file terpisah.

// PencarianScreen dihapus karena fungsinya digantikan oleh search bar di HomeScreen

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Logger _logger = Logger();

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Diperlukan'),
        content: const Text('Anda harus login untuk mengakses fitur ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index, bool isAuthenticated) {
    final protectedTabs = {1, 2, 3}; // Indeks untuk Pesanan, Chat, dan Profil

    if (!isAuthenticated && protectedTabs.contains(index)) {
      _showLoginPrompt(context);
      return; // Hentikan navigasi jika pop-up ditampilkan
    }
    
    // Jika tab beranda (index 0) ditekan, tutup halaman notifikasi jika terbuka
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

  int _getValidCurrentIndex() {
    final shellIndex = widget.navigationShell.currentIndex;
    final List<BottomNavigationBarItem> currentItems = _buildUserItems(context);
    final itemCount = currentItems.length;

    _logger.d('_getValidCurrentIndex: shellIndex = $shellIndex, itemCount = $itemCount');

    if (shellIndex >= 0 && shellIndex < itemCount) {
      _logger.d('_getValidCurrentIndex: Returning shellIndex = $shellIndex (valid)');
      return shellIndex;
    }

    _logger.w('_getValidCurrentIndex: Warning! Invalid shellIndex ($shellIndex) for itemCount ($itemCount). Defaulting to 0.');
    return 0;
  }

  List<BottomNavigationBarItem> _buildUserItems(BuildContext context) {
    // Navbar baru: Beranda, Pesanan, Chat, Profil
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: AppStrings.beranda,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_outlined),
        activeIcon: Icon(Icons.receipt_long),
        label: AppStrings.pesanan,
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        // Setup atau stop notification handler berdasarkan status autentikasi
        // Pindahkan ke BlocListener untuk menghindari multiple calls saat rebuild
        if (authState is AuthAuthenticated) {
          _logger.d('Auth state is Authenticated, user ID: ${authState.user.id}');
          context.read<UserViewBloc>().add(UserViewInitialize(userId: authState.user.id, userRole: authState.user.role));

          // Mulai listening notifikasi realtime saat user terautentikasi
          NotificationService().startListening(authState.user.id);
        } else if (authState is AuthUnauthenticated) {
          _logger.d('Auth state is Unauthenticated');
          // Hentikan listening notifikasi saat user logout
          NotificationService().stopListening();
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final bool isAuthenticated = authState is AuthAuthenticated;

          return BlocConsumer<UserViewBloc, UserViewState>(
          listener: (context, userViewState) {
            if (userViewState.currentViewMode == UserViewMode.penyedia) {
              // Gunakan Future.microtask untuk menghindari lifecycle assertion error
              Future.microtask(() {
                // Periksa apakah context masih valid sebelum navigasi
                if (context.mounted && 
                    GoRouter.of(context).routeInformationProvider.value.uri.toString() != '/provider-dashboard') {
                  context.go('/provider-dashboard');
                }
              });
            }
          },
          builder: (context, userViewState) {
            int currentIndex = _getValidCurrentIndex();
            if (userViewState.currentViewMode == UserViewMode.penyedia) {
              currentIndex = 0; // Indeks aman selama transisi keluar
            }

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor:
                    Colors.transparent, // Transparan agar warna header terlihat
                statusBarIconBrightness:
                    Brightness.light, // Ikon status bar berwarna terang
                statusBarBrightness: Brightness.dark, // Untuk iOS
              ),
              child: Scaffold(
                body: widget.navigationShell,
                bottomNavigationBar: BottomNavigationBar(
                  items: _buildUserItems(context),
                  currentIndex: currentIndex,
                  onTap: (index) => _onItemTapped(index, isAuthenticated),
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: Theme.of(context).primaryColor,
                  unselectedItemColor: Colors.grey,
                  showUnselectedLabels: true,
                ),
              ),
            );
          },
        );
        },
      ),
    );
  }
}
