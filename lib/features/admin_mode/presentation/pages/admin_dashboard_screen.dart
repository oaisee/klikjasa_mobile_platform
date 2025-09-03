import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/routes/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/admin_mode/presentation/widgets/admin_summary_widget.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/admin_dashboard_stats_bloc.dart';
import 'package:klik_jasa/features/admin_mode/data/repositories/admin_dashboard_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:klik_jasa/core/widgets/logout_dialog.dart';
import 'package:klik_jasa/features/admin_mode/presentation/widgets/admin_notification_bell_widget.dart';
import 'package:klik_jasa/features/admin_mode/presentation/cubit/admin_drawer_cubit.dart';
import 'package:klik_jasa/features/admin_mode/presentation/cubit/admin_drawer_state.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Widget? child; // Untuk ShellRoute
  const AdminDashboardScreen({super.key, this.child});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late AdminDashboardStatsBloc _adminDashboardStatsBloc;
  late AdminDrawerCubit _adminDrawerCubit;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Flag untuk mencegah double fetching
  bool _isDataLoaded = false;
  
  // Cache untuk judul dan drawer item
  final Map<String, String> _appBarTitleCache = {};
  final Map<String, Widget> _drawerItemCache = {};

  @override
  void initState() {
    super.initState();
    _adminDashboardStatsBloc = AdminDashboardStatsBloc(
      repository: AdminDashboardRepositoryImpl(supabase: Supabase.instance.client),
    );
    _adminDrawerCubit = AdminDrawerCubit();
    
    // Muat data dashboard stats secara otomatis saat halaman dibuka
    _loadDashboardData();
  }
  
  void _loadDashboardData() {
    // Cek flag untuk mencegah double fetching
    if (_isDataLoaded) return;
    
    // Memuat data statistik dashboard
    _adminDashboardStatsBloc.add(LoadAdminDashboardStats());
    
    // Memuat data user & provider untuk periode default (Minggu)
    _adminDashboardStatsBloc.add(LoadUserProvidersByPeriod(period: 'Minggu'));
    
    // Memuat data histori order untuk periode default (Minggu)
    _adminDashboardStatsBloc.add(LoadOrderHistoryByPeriod(period: 'Minggu'));
    
    // Set flag untuk mencegah double fetching
    _isDataLoaded = true;
  }

  @override
  void dispose() {
    _adminDashboardStatsBloc.close();
    _adminDrawerCubit.close();
    super.dispose();
  }

  void _navigateTo(String relativeRouteName) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final targetPath = relativeRouteName.isEmpty
        ? AppRouter.adminBaseRoute
        : '${AppRouter.adminBaseRoute}/$relativeRouteName';

    // Hanya navigasi jika path berbeda untuk menghindari loop atau navigasi yang tidak perlu
    if (currentPath != targetPath) {
      context.go(targetPath);
    }
  }

  Future<void> _logoutAdmin() async {
    // Tampilkan dialog konfirmasi logout. `showLogoutDialog` adalah async.
    final bool confirmLogout = await showLogoutDialog(context);

    // Setelah await, widget mungkin sudah tidak ada di tree. Periksa `mounted`.
    // Juga periksa apakah `confirmLogout` adalah true (bukan null atau false).
    if (mounted && confirmLogout == true) {
      // Dispatch event logout ke AuthBloc
      context.read<AuthBloc>().add(const AuthLogoutRequested());

      // Navigasi ke halaman login
      context.go(AppRouter.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.toString();
    // debugPrint("AdminDashboardScreen build: currentPath = $currentPath, widget.child is ${widget.child == null ? 'null' : 'not null'}");

    // Provide AdminDashboardStatsBloc so it's available to the entire Scaffold content,
    // including widget.child (sub-routes) and AdminSummaryWidget (on base route).
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _adminDashboardStatsBloc),
        BlocProvider.value(value: _adminDrawerCubit),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          leading: BlocBuilder<AdminDrawerCubit, AdminDrawerState>(
            builder: (context, state) {
              final bool isDrawerOpen = state is AdminDrawerOpened;
              return IconButton(
                icon: Icon(
                  isDrawerOpen ? Icons.arrow_back : Icons.menu,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (isDrawerOpen) {
                    _scaffoldKey.currentState?.closeDrawer();
                  } else {
                    _scaffoldKey.currentState?.openDrawer();
                  }
                },
              );
            },
          ),
          title: Text(
            _getAppBarTitle(currentPath),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // Widget notifikasi untuk admin
            const AdminNotificationBellWidget(),
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: AppStrings.logout,
                onPressed: _logoutAdmin,
              ),
            ),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColorDark,
                  Theme.of(context).primaryColor,
                ],
              ),
            ),
          ),
        ),
        onDrawerChanged: (isOpened) {
          if (isOpened) {
            _adminDrawerCubit.openDrawer();
          } else {
            _adminDrawerCubit.closeDrawer();
          }
        },
        drawer: Drawer(
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorDark,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                  ),
                ),
                child: DrawerHeader(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColorDark,
                        Theme.of(context).primaryColor,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Admin KlikJasa',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Panel Kontrol',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary.withAlpha((0.85 * 255).round()),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildDrawerItem(
                icon: Icons.dashboard_rounded,
                title: 'Dasbor Utama',
                relativeRouteName: '', // For base admin route
                currentPath: currentPath,
              ),
              // Menu Verifikasi Penyedia dihapus karena sudah diintegrasikan ke dalam Manajemen Pengguna
              _buildDrawerItem(
                icon: Icons.people_alt_outlined,
                title: 'Manajemen Pengguna',
                relativeRouteName: AppRouter.adminUserManagementRoute,
                currentPath: currentPath,
              ),
              _buildDrawerItem(
                icon: Icons.design_services_outlined,
                title: 'Manajemen Layanan',
                relativeRouteName: AppRouter.adminServiceManagementRoute,
                currentPath: currentPath,
              ),
              _buildDrawerItem(
                icon: Icons.category_outlined,
                title: 'Manajemen Kategori',
                relativeRouteName: AppRouter.adminCategoryManagementRoute,
                currentPath: currentPath,
              ),
              _buildDrawerItem(
                icon: Icons.article_outlined,
                title: 'Manajemen Konten',
                relativeRouteName: AppRouter.adminContentManagementRoute,
                currentPath: currentPath,
              ),
              _buildDrawerItem(
                icon: Icons.chat_outlined,
                title: 'Chat Pelanggan',
                relativeRouteName: AppRouter.adminChatRoute,
                currentPath: currentPath,
              ),
              _buildDrawerItem(
                icon: Icons.receipt_long_outlined,
                title: 'Manajemen Transaksi',
                relativeRouteName: AppRouter.adminTransactionManagementRoute,
                currentPath: currentPath,
              ),
              _buildDrawerItem(
                icon: Icons.settings_applications_outlined,
                title: 'Pengaturan Aplikasi',
                relativeRouteName: AppRouter.adminAppSettingsRoute,
                currentPath: currentPath,
              ),
            ],
          ),
        ),
        body: _buildBody(currentPath),
      ),
    );
  }

  Widget _buildBody(String currentPath) {
    // debugPrint("_buildBody called. currentPath: $currentPath, adminBaseRoute: ${AppRouter.adminBaseRoute}");
    if (currentPath == AppRouter.adminBaseRoute) {
      // debugPrint("Displaying AdminSummaryWidget with RefreshIndicator for $currentPath");
      // AdminSummaryWidget and RefreshIndicator will access AdminDashboardStatsBloc from context
      // because BlocProvider.value is now an ancestor of this Scaffold's body.
      return Builder(builder: (blocContext) { // Use a new Builder context for immediate access post-provider
        // It's good practice to use context.read inside event handlers/callbacks (like onRefresh or initState)
        // and context.watch in build methods if the widget should rebuild on state changes.
        // AdminSummaryWidget itself will likely use BlocBuilder or context.watch internally.
        final adminBloc = blocContext.read<AdminDashboardStatsBloc>();
        final currentState = adminBloc.state; 
        // final currentState = blocContext.watch<AdminDashboardStatsBloc>().state; // Alternative if this Builder needs to react

        // Trigger initial load only if BLoC is in initial state.
        if (currentState is AdminDashboardStatsInitial) {
          // debugPrint("AdminDashboardStatsBloc is Initial, dispatching LoadAdminDashboardStats");
          adminBloc.add(LoadAdminDashboardStats());
        }
        return RefreshIndicator(
          onRefresh: () {
            // debugPrint("RefreshIndicator onRefresh triggered");
            // Pass the BLoC instance obtained from context to _handleDashboardRefresh
            return _handleDashboardRefresh(blocContext.read<AdminDashboardStatsBloc>());
          },
          child: const AdminSummaryWidget(), // AdminSummaryWidget will handle displaying states
        );
      });
    } else if (widget.child != null) {
      // debugPrint("Displaying widget.child for $currentPath");
      // For other admin sub-routes, display the child provided by ShellRoute
      // widget.child can now access AdminDashboardStatsBloc via context if needed.
      return widget.child!;
    } else {
      // debugPrint("Fallback: Konten tidak ditemukan for $currentPath");
      // Fallback if no child is provided for a non-base admin route
      return const Center(child: Text("Konten tidak ditemukan untuk rute ini."));
    }
  }

  Future<void> _handleDashboardRefresh(AdminDashboardStatsBloc bloc) {
    final Completer<void> completer = Completer<void>();
    late StreamSubscription blocSubscription;

    // Reset flag untuk memungkinkan reload data
    _isDataLoaded = false;

    // Ensure we only listen once and clean up
    blocSubscription = bloc.stream.listen((state) {
      if (state is AdminDashboardStatsLoaded || state is AdminDashboardStatsError || 
          (state is CombinedDashboardState && !state.isSummaryLoading)) {
        if (!completer.isCompleted) {
          completer.complete();
          blocSubscription.cancel(); // Cancel subscription once completed
        }
      }
    });

    // Reload semua data
    _loadDashboardData();

    // Timeout for the refresh operation
    Future.delayed(const Duration(seconds: 20), () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Refresh dashboard timed out after 20 seconds'));
        blocSubscription.cancel(); // Cancel subscription on timeout
      }
    });

    return completer.future;
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String relativeRouteName,
    required String currentPath,
  }) {
    // Buat cache key dari kombinasi parameter
    final String cacheKey = '$relativeRouteName:$currentPath';
    
    // Cek cache terlebih dahulu
    if (_drawerItemCache.containsKey(cacheKey)) {
      return _drawerItemCache[cacheKey]!;
    }
    
    // Construct the full target path for comparison
    final String targetPath = relativeRouteName.isEmpty
        ? AppRouter.adminBaseRoute
        : '${AppRouter.adminBaseRoute}/$relativeRouteName';

    final bool isSelected = currentPath == targetPath;

    final Widget drawerItem = Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor.withAlpha((0.15 * 255).round()) : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withAlpha((255 * 0.2).round())
                : Colors.grey.withAlpha((255 * 0.1).round()),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(
            icon,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 15,
          ),
        ),
        onTap: () {
          _navigateTo(relativeRouteName);
          _scaffoldKey.currentState?.closeDrawer();
        },
      ),
    );
    
    // Simpan di cache hanya jika tidak selected (karena selected item bisa berubah)
    if (!isSelected) {
      _drawerItemCache[cacheKey] = drawerItem;
    }
    
    return drawerItem;
  }

  String _getAppBarTitle(String currentPath) {
    // Cek cache terlebih dahulu
    if (_appBarTitleCache.containsKey(currentPath)) {
      return _appBarTitleCache[currentPath]!;
    }
    
    // Jika tidak ada di cache, hitung dan simpan di cache
    String title;
    if (currentPath == AppRouter.adminBaseRoute) {
      title = 'Dasbor Admin';
    // Referensi ke Verifikasi Penyedia dihapus karena sudah diintegrasikan ke Manajemen Pengguna
    } else if (currentPath == '${AppRouter.adminBaseRoute}/${AppRouter.adminUserManagementRoute}') {
      title = 'Manajemen Pengguna';
    } else if (currentPath == '${AppRouter.adminBaseRoute}/${AppRouter.adminServiceManagementRoute}') {
      title = 'Manajemen Layanan';
    } else if (currentPath == '${AppRouter.adminBaseRoute}/${AppRouter.adminCategoryManagementRoute}') {
      title = 'Manajemen Kategori Layanan';
    } else if (currentPath == '${AppRouter.adminBaseRoute}/${AppRouter.adminContentManagementRoute}') {
      title = 'Manajemen Konten';
    } else if (currentPath == '${AppRouter.adminBaseRoute}/${AppRouter.adminTransactionManagementRoute}') {
      title = 'Manajemen Transaksi';
    } else if (currentPath == '${AppRouter.adminBaseRoute}/${AppRouter.adminAppSettingsRoute}') {
      title = 'Pengaturan Aplikasi';
    } else {
      title = 'Admin Panel KlikJasa'; // Default title if no specific match
    }
    
    // Simpan di cache
    _appBarTitleCache[currentPath] = title;
    return title;
  }
}
