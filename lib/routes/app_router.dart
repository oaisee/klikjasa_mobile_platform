import 'package:flutter/material.dart';
import 'package:klik_jasa/core/utils/go_router_refresh_stream.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/app_settings/app_settings_bloc.dart';
import 'package:klik_jasa/injection_container.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/admin_dashboard_screen.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/service_management_screen.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/transaction_management_screen.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/user_management_screen.dart';
import 'package:klik_jasa/features/admin_mode/presentation/widgets/admin_summary_widget.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/auth/presentation/pages/login_screen.dart';
import 'package:klik_jasa/features/common/auth/presentation/pages/register_screen.dart';
import 'package:klik_jasa/features/common/auth/presentation/pages/email_verification_screen.dart';
import 'package:klik_jasa/features/common/auth/presentation/pages/reset_password_screen.dart';
import 'package:klik_jasa/features/common/profile/application/bloc/user_view_bloc.dart';
import 'package:klik_jasa/features/common/navigation/presentation/pages/main_screen.dart';
import 'package:klik_jasa/features/common/profile/presentation/pages/top_up_screen.dart';
import 'package:klik_jasa/features/common/navigation/presentation/pages/provider_main_screen.dart';
import 'package:klik_jasa/features/common/profile/presentation/pages/profile_screen.dart';
import 'package:klik_jasa/features/common/profile/presentation/pages/provider_registration_screen.dart';
import 'package:klik_jasa/features/common/profile/presentation/cubit/provider_registration_cubit.dart';
import 'package:klik_jasa/features/common/profile/presentation/pages/provider_status_screen.dart';
import 'package:klik_jasa/features/common/profile/presentation/pages/edit_profile_screen.dart';
import 'package:klik_jasa/features/common/profile/presentation/pages/help_screen.dart';
import 'package:klik_jasa/features/common/splash/presentation/pages/splash_screen.dart';
import 'package:klik_jasa/features/common/chat/presentation/bloc/chat_bloc.dart';
import 'package:klik_jasa/features/common/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:klik_jasa/features/common/chat/presentation/pages/chat_detail_screen.dart';
import 'package:klik_jasa/features/common/chat/presentation/pages/chat_screen.dart';
import 'package:klik_jasa/features/common/chat/presentation/widgets/chat_edge_case_test.dart';
import 'package:klik_jasa/features/common/profile/presentation/bloc/region/region_bloc.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/bloc/services_bloc.dart';

import 'package:klik_jasa/features/provider_mode/dashboard/presentation/pages/provider_dashboard_screen.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/presentation/pages/provider_order_details_screen.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/presentation/pages/provider_orders_screen.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/pages/add_edit_layanan_screen.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/pages/layanan_detail_screen.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/pages/provider_service_management_screen.dart';
import 'package:klik_jasa/features/provider_mode/statistics/presentation/pages/provider_statistics_screen.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/presentation/pages/store_settings_screen.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/pages/home_screen.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/pages/provider_profile_screen.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/provider_profile_cubit.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/pages/service_detail_screen.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/pages/services_by_category_screen.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service_category.dart';

import 'package:klik_jasa/features/user_mode/orders/presentation/pages/orders_screen.dart';
import 'package:klik_jasa/features/user_mode/orders/presentation/pages/order_checkout_screen.dart';
import 'package:klik_jasa/features/user_mode/search/presentation/pages/search_screen.dart';
import 'package:klik_jasa/features/user_mode/wishlist/presentation/pages/wishlist_screen.dart';
import 'package:klik_jasa/features/common/notifications/presentation/pages/notification_screen.dart';
import 'package:klik_jasa/routes/route_aware_service.dart';
import 'package:klik_jasa/features/admin_mode/data/repositories/user_profile_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/user_management_bloc.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/analytics_report_screen.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/app_settings_screen.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/category_management_screen.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/content_management_screen.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/app_config/app_config_monitoring_dashboard.dart';
import 'package:klik_jasa/features/admin_mode/presentation/pages/admin_chat_screen.dart';

class AppRouter {
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String emailVerificationRoute = '/email-verification';
  static const String resetPasswordRoute = '/reset-password';
  static const String homeRoute = '/home';
  static const String adminBaseRoute = '/admin';
  static const String providerStatisticsRoute = '/provider-statistics';
  static const String storeSettingsRoute = '/store-settings';
  static const String adminUserManagementRoute = 'users';
  static const String adminServiceManagementRoute = 'services';
  static const String adminCategoryManagementRoute = 'categories';
  static const String adminContentManagementRoute = 'content';
  static const String adminTransactionManagementRoute = 'transactions';
  static const String adminAppSettingsRoute = 'settings';
  static const String adminAppConfigMonitoringRoute = 'config-monitoring';
  static const String adminChatRoute = 'chat';

  final AuthBloc authBloc;
  final UserViewBloc userViewBloc;
  late final GoRouter router;
  late final GoRouterRefreshStream _goRouterRefreshStream;
  final RouteAwareService _routeAwareService = RouteAwareService();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );
  static final _adminShellNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'adminShell',
  );

  // User Shell Keys
  static final _shellNavigatorKeyHome = GlobalKey<NavigatorState>(
    debugLabel: 'shellHome',
  );
  static final _shellNavigatorKeyOrders = GlobalKey<NavigatorState>(
    debugLabel: 'shellOrders',
  );

  static final _shellNavigatorKeyChat = GlobalKey<NavigatorState>(
    debugLabel: 'shellChat',
  );
  static final _shellNavigatorKeyProfile = GlobalKey<NavigatorState>(
    debugLabel: 'shellProfile',
  );

  // Provider Shell Keys
  static final _providerShellNavigatorKeyDashboard = GlobalKey<NavigatorState>(
    debugLabel: 'providerShellDashboard',
  );
  static final _providerShellNavigatorKeyOrders = GlobalKey<NavigatorState>(
    debugLabel: 'providerShellOrders',
  );
  static final _providerShellNavigatorKeyServices = GlobalKey<NavigatorState>(
    debugLabel: 'providerShellServices',
  );
  static final _providerShellNavigatorKeyChat = GlobalKey<NavigatorState>(
    debugLabel: 'providerShellChat',
  );
  static final _providerShellNavigatorKeyProfile = GlobalKey<NavigatorState>(
    debugLabel: 'providerShellProfile',
  );

  AppRouter(this.authBloc, this.userViewBloc) {
    _goRouterRefreshStream = GoRouterRefreshStream.multiple([
      authBloc.stream,
      userViewBloc.stream,
    ]);
    router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: _goRouterRefreshStream,
      observers: [_routeAwareService],

      redirect: (BuildContext context, GoRouterState state) {
        final authState = authBloc.state;
        final currentLocation = state.matchedLocation;

        if (authState is AuthInitial || authState is AuthLoading) {
          return null; // No redirect during initial load
        }

        final isAuthenticated = authState is AuthAuthenticated;

        // Guest trying to access protected routes
        if (!isAuthenticated && currentLocation.startsWith('/profile')) {
          return '/login';
        }

        // Authenticated user
        if (isAuthenticated) {
          final user = authState.user;

          // Trying to access auth pages while logged in
          if (currentLocation == '/login' || currentLocation == '/register') {
            return '/home';
          }

          // Admin role always redirects to admin dashboard
          if (user.role == 'admin' && !currentLocation.startsWith('/admin')) {
            return '/admin';
          }

          // For provider users, check UserViewBloc state for manual mode switching
          if (user.role == 'penyedia_jasa') {
            final userViewState = userViewBloc.state;

            // If user manually switched to user mode, allow access to user routes
            if (userViewState.currentViewMode == UserViewMode.pengguna) {
              // Allow access to user routes when in user mode
              if (currentLocation == '/') {
                return '/home';
              }
              // Don't redirect if already on user routes
              if (currentLocation.startsWith('/home') ||
                  currentLocation.startsWith('/profile') ||
                  currentLocation.startsWith('/search') ||
                  currentLocation.startsWith('/wishlist')) {
                return null; // No redirect needed
              }
            } else {
              // Default provider mode behavior
              if (currentLocation == '/') {
                return '/provider-dashboard';
              } else if (currentLocation == '/home' ||
                  (currentLocation.startsWith('/home') &&
                      !currentLocation.contains('service-detail'))) {
                return '/provider-dashboard';
              }
            }
          } else if (user.role == 'pengguna_jasa') {
            // Regular user behavior - redirect away from provider routes
            if (currentLocation == '/') {
              return '/home';
            } else if (currentLocation.startsWith('/provider-dashboard') ||
                currentLocation.startsWith('/provider-orders') ||
                currentLocation.startsWith('/provider-services')) {
              return '/home';
            }
          }

          // From splash to appropriate home based on role and view mode
          if (currentLocation == '/') {
            if (user.role == 'penyedia_jasa') {
              // Check UserViewBloc state for initial route
              final userViewState = userViewBloc.state;
              if (userViewState.currentViewMode == UserViewMode.pengguna) {
                return '/home';
              }
              return '/provider-dashboard';
            } else if (user.role == 'admin') {
              return '/admin';
            } else {
              return '/home';
            }
          }
        } else {
          // Guest
          // From splash to home for guests
          if (currentLocation == '/') {
            return '/home';
          }
        }

        return null; // No redirect needed
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/email-verification',
          name: 'emailVerification',
          builder: (context, state) {
            final email = state.uri.queryParameters['email'] ?? '';
            return EmailVerificationScreen(email: email);
          },
        ),
        GoRoute(
          path: '/reset-password',
          name: 'resetPassword',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) {
            // Parameter query tidak digunakan, SearchScreen tidak menerima parameter query
            return const SearchScreen();
          },
        ),
        GoRoute(
          path: '/wishlist',
          name: 'wishlist',
          builder: (context, state) => const WishlistScreen(),
        ),
        GoRoute(
          path: '/topup',
          name: 'topUp',
          builder: (context, state) => const TopUpScreen(),
        ),

        // USER MODE SHELL
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return KeyedSubtree(
              key: const ValueKey('userShell'),
              child: MainScreen(navigationShell: navigationShell),
            );
          },
          branches: [
            // Home Branch
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeyHome,
              routes: [
                GoRoute(
                  path: '/home',
                  name: 'home',
                  builder: (context, state) => HomeScreen(),
                  routes: [
                    GoRoute(
                      path: 'service-detail',
                      name: 'serviceDetail',
                      builder: (context, state) {
                        // Pastikan extra berisi data yang diperlukan
                        if (state.extra is Map) {
                          final Map<String, dynamic> extraData =
                              state.extra as Map<String, dynamic>;

                          // Cek apakah service ada dan bertipe ServiceWithLocation
                          if (extraData.containsKey('service')) {
                            final serviceData = extraData['service'];
                            ServiceWithLocation service;

                            if (serviceData is ServiceWithLocation) {
                              service = serviceData;
                            } else if (serviceData is Map<String, dynamic>) {
                              // Jika service berupa Map, konversi ke ServiceWithLocation
                              service = ServiceWithLocation.fromMap(
                                serviceData,
                              );
                            } else {
                              return const Scaffold(
                                body: Center(
                                  child: Text(
                                    'Format data layanan tidak valid',
                                  ),
                                ),
                              );
                            }

                            final heroTag = extraData['heroTag'] as String?;
                            return ServiceDetailScreen(
                              service: service,
                              heroTag: heroTag,
                            );
                          } else {
                            return const Scaffold(
                              body: Center(
                                child: Text('Data layanan tidak ditemukan'),
                              ),
                            );
                          }
                        } else if (state.extra is ServiceWithLocation) {
                          // Fallback jika hanya service yang dikirim tanpa heroTag
                          final service = state.extra as ServiceWithLocation;
                          return ServiceDetailScreen(service: service);
                        } else if (state.extra is Map<String, dynamic>) {
                          // Jika extra adalah Map tapi bukan format yang diharapkan,
                          // coba konversi langsung ke ServiceWithLocation
                          try {
                            final service = ServiceWithLocation.fromMap(
                              state.extra as Map<String, dynamic>,
                            );
                            return ServiceDetailScreen(service: service);
                          } catch (e) {
                            return const Scaffold(
                              body: Center(
                                child: Text('Gagal memuat data layanan'),
                              ),
                            );
                          }
                        } else {
                          // Fallback jika tidak ada data yang valid
                          return const Scaffold(
                            body: Center(
                              child: Text('Data layanan tidak valid'),
                            ),
                          );
                        }
                      },
                    ),
                    GoRoute(
                      path: 'provider-profile/:providerId',
                      name: 'userProviderProfile',
                      builder: (context, state) {
                        final providerId = state.pathParameters['providerId']!;
                        return BlocProvider(
                          create: (context) => ProviderProfileCubit(),
                          child: ProviderProfileScreen(providerId: providerId),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'checkout',
                      name: 'checkout',
                      builder: (context, state) {
                        ServiceWithLocation service;

                        if (state.extra is ServiceWithLocation) {
                          service = state.extra as ServiceWithLocation;
                        } else if (state.extra is Map<String, dynamic>) {
                          // Jika extra adalah Map, konversi ke ServiceWithLocation
                          try {
                            service = ServiceWithLocation.fromMap(
                              state.extra as Map<String, dynamic>,
                            );
                          } catch (e) {
                            return const Scaffold(
                              body: Center(
                                child: Text(
                                  'Gagal memuat data layanan untuk checkout',
                                ),
                              ),
                            );
                          }
                        } else {
                          return const Scaffold(
                            body: Center(
                              child: Text(
                                'Data layanan tidak valid untuk checkout',
                              ),
                            ),
                          );
                        }

                        return OrderCheckoutScreen(service: service);
                      },
                    ),
                    GoRoute(
                      path: 'notifications',
                      name: 'userNotifications',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final authState = context.read<AuthBloc>().state;
                        if (authState is AuthAuthenticated) {
                          return NotificationScreen(
                            userId: authState.user.id,
                            mode: 'user',
                          );
                        }
                        // Fallback, should be protected by redirect
                        return const Scaffold(
                          body: Center(
                            child: Text('Please log in to see notifications.'),
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'services-by-category',
                      name: 'servicesByCategory',
                      builder: (context, state) {
                        try {
                          final category = state.extra as ServiceCategory;
                          return ServicesByCategoryScreen(category: category);
                        } catch (e, stackTrace) {
                          debugPrint('Error in services-by-category route: $e');
                          debugPrint('Stack trace: $stackTrace');
                          return Scaffold(
                            appBar: AppBar(title: const Text('Error')),
                            body: const Center(
                              child: Text(
                                'Terjadi kesalahan saat memuat kategori layanan',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Orders Branch
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeyOrders,
              routes: [
                GoRoute(
                  path: '/orders-user',
                  name: 'orders-user',
                  builder: (context, state) => const PesananScreen(),
                ),
              ],
            ),

            // Chat Branch
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeyChat,
              routes: [
                GoRoute(
                  path: '/chat',
                  name: 'chat',
                  builder: (context, state) => BlocProvider<ChatListBloc>(
                    create: (context) => sl<ChatListBloc>(),
                    child: const ChatScreen(userType: UserType.user),
                  ),
                  routes: [
                    GoRoute(
                      // Gunakan 'detail' sebagai path tetap dan userId sebagai query parameter
                      path: 'detail/:otherUserId',
                      name: 'userChatDetail',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final otherUserId =
                            state.pathParameters['otherUserId']!;
                        final extra = state.extra as Map<String, dynamic>?;

                        if (extra != null) {
                          return BlocProvider(
                            create: (context) => sl<ChatBloc>(),
                            child: ChatDetailScreen(
                              otherUserId: otherUserId,
                              otherUserName: extra['otherUserName'] as String?,
                              profilePicture:
                                  extra['profilePicture'] as String?,
                              userType: UserType.user,
                              orderData:
                                  extra['orderData'] as Map<String, dynamic>?,
                              serviceData:
                                  extra['serviceData'] as Map<String, dynamic>?,
                            ),
                          );
                        } else {
                          final repo = sl<UserProfileRepositoryImpl>();
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: repo.getUserProfile(otherUserId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Scaffold(
                                  body: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return Scaffold(
                                  appBar: AppBar(),
                                  body: const Center(
                                    child: Text('Gagal memuat data pengguna'),
                                  ),
                                );
                              }
                              final userProfile = snapshot.data!;
                              return BlocProvider(
                                create: (context) => sl<ChatBloc>(),
                                child: ChatDetailScreen(
                                  otherUserId: otherUserId,
                                  otherUserName:
                                      userProfile['full_name'] as String?,
                                  profilePicture:
                                      userProfile['avatar_url'] as String?,
                                  userType: UserType.user,
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                    GoRoute(
                      path: 'edge-case-test',
                      name: 'chatEdgeCaseTest',
                      builder: (context, state) {
                        return const ChatEdgeCaseTest();
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Profile Branch
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeyProfile,
              routes: [
                GoRoute(
                  path: '/profile',
                  name: 'profile',
                  builder: (context, state) =>
                      ProfileScreen(authBloc: context.read<AuthBloc>()),
                  routes: [
                    GoRoute(
                      path: 'provider-registration',
                      name: 'providerRegistration',
                      builder: (context, state) => BlocProvider(
                        create: (context) => sl<ProviderRegistrationCubit>(),
                        child: const ProviderRegistrationScreen(),
                      ),
                    ),
                    // Rute provider-registration-refactored dihapus karena sudah dikonsolidasi ke provider-registration
                    GoRoute(
                      path: 'provider-status',
                      name: 'providerStatus',
                      builder: (context, state) {
                        final extra = state.extra as Map<String, dynamic>?;
                        final providerStatus =
                            extra?['providerStatus'] as String? ?? 'unknown';
                        return ProviderStatusScreen(
                          providerStatus: providerStatus,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'help',
                      name: 'help',
                      builder: (context, state) => const HelpScreen(),
                    ),
                    GoRoute(
                      path: 'provider-statistics',
                      name: 'providerStatistics',
                      builder: (context, state) =>
                          const ProviderStatisticsScreen(),
                    ),
                    GoRoute(
                      path: 'store-settings',
                      name: 'storeSettings',
                      builder: (context, state) => const StoreSettingsScreen(),
                    ),
                    GoRoute(
                      path: 'edit',
                      name: 'editProfile',
                      builder: (context, state) => BlocProvider<RegionBloc>(
                        create: (context) => sl<RegionBloc>(),
                        child: const EditProfileScreen(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // ADMIN MODE SHELL
        ShellRoute(
          navigatorKey: _adminShellNavigatorKey,
          builder: (context, state, child) =>
              AdminDashboardScreen(child: child),
          routes: [
            GoRoute(
              path: '/admin',
              name: 'adminBase',
              builder: (context, state) => const AdminSummaryWidget(),
              routes: [
                GoRoute(
                  path: 'users',
                  name: 'adminUsers',
                  builder: (context, state) {
                    final repo = UserProfileRepositoryImpl(
                      supabase: Supabase.instance.client,
                    );
                    return BlocProvider(
                      create: (context) =>
                          UserManagementBloc(userProfileRepository: repo),
                      child: const UserManagementScreen(),
                    );
                  },
                ),
                // Rute verifikasi penyedia dihapus karena sudah diintegrasikan ke dalam Manajemen Pengguna
                GoRoute(
                  path: 'services',
                  name: 'adminServices',
                  builder: (context, state) => const ServiceManagementScreen(),
                ),
                GoRoute(
                  path: 'categories',
                  name: 'adminCategories',
                  builder: (context, state) => const CategoryManagementScreen(),
                ),
                GoRoute(
                  path: 'transactions',
                  name: 'adminTransactions',
                  builder: (context, state) => BlocProvider<AppSettingsBloc>(
                    create: (context) => sl<AppSettingsBloc>(),
                    child: const TransactionManagementScreen(),
                  ),
                ),
                GoRoute(
                  path: 'content',
                  name: 'adminContent',
                  builder: (context, state) => const ContentManagementScreen(),
                ),
                GoRoute(
                  path: 'settings',
                  name: 'adminSettings',
                  builder: (context, state) => BlocProvider<AppSettingsBloc>(
                    create: (context) => sl<AppSettingsBloc>(),
                    child: const AppSettingsScreen(),
                  ),
                ),
                GoRoute(
                  path: 'config-monitoring',
                  name: 'adminAppConfigMonitoring',
                  builder: (context, state) =>
                      const AppConfigMonitoringDashboard(),
                ),
                GoRoute(
                  path: 'analytics',
                  name: 'adminAnalytics',
                  builder: (context, state) => const AnalyticsReportScreen(),
                ),
                GoRoute(
                  path: 'chat',
                  name: 'adminChat',
                  builder: (context, state) => const AdminChatScreen(),
                ),
              ],
            ),
          ],
        ),

        // PROVIDER MODE SHELL
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return KeyedSubtree(
              key: const ValueKey('providerShell'),
              child: ProviderMainScreen(navigationShell: navigationShell),
            );
          },
          branches: [
            // Dashboard Branch
            StatefulShellBranch(
              navigatorKey: _providerShellNavigatorKeyDashboard,
              routes: [
                GoRoute(
                  path: '/provider-dashboard',
                  name: 'providerDashboard',
                  builder: (context, state) => const ProviderDashboardScreen(),
                  routes: [
                    GoRoute(
                      path: 'notifications',
                      name: 'providerNotifications',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final authState = context.read<AuthBloc>().state;
                        if (authState is AuthAuthenticated) {
                          return NotificationScreen(
                            userId: authState.user.id,
                            mode: 'provider',
                          );
                        }
                        // Fallback, should be protected by redirect
                        return const Scaffold(
                          body: Center(
                            child: Text('Please log in to see notifications.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Orders Branch
            StatefulShellBranch(
              navigatorKey: _providerShellNavigatorKeyOrders,
              routes: [
                GoRoute(
                  path: '/provider-orders',
                  name: 'providerOrders',
                  builder: (context, state) => const ProviderOrdersScreen(),
                  routes: [
                    GoRoute(
                      path: 'details/:orderId',
                      name: 'providerOrderDetails',
                      builder: (context, state) {
                        final orderId = int.tryParse(
                          state.pathParameters['orderId'] ??
                              '00000000-0000-0000-0000-000000000000',
                        );
                        if (orderId != null) {
                          return ProviderOrderDetailsScreen(orderId: orderId);
                        } else {
                          return const Scaffold(
                            body: Center(
                              child: Text('ID Pesanan tidak valid.'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Services Branch
            StatefulShellBranch(
              navigatorKey: _providerShellNavigatorKeyServices,
              routes: [
                GoRoute(
                  path: '/provider-services',
                  name: 'providerServices',
                  builder: (context, state) =>
                      const ProviderServiceManagementScreen(),
                  routes: [
                    GoRoute(
                      path: 'add-edit',
                      name: 'addEditLayanan',
                      builder: (context, state) {
                        final extra = state.extra as Map<String, dynamic>?;
                        return MultiBlocProvider(
                          providers: [
                            BlocProvider<RegionBloc>(
                              create: (context) => sl<RegionBloc>(),
                            ),
                            BlocProvider<ServicesBloc>(
                              create: (context) => sl<ServicesBloc>(),
                            ),
                          ],
                          child: AddEditLayananScreen(
                            service: extra?['layanan'] as Service?,
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'detail/:serviceId',
                      name: 'providerServiceDetail',
                      builder: (context, state) {
                        final serviceId = state.pathParameters['serviceId']!;
                        return BlocProvider<ServicesBloc>(
                          create: (context) => sl<ServicesBloc>(),
                          child: LayananDetailScreen(layananId: serviceId),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Chat Branch
            StatefulShellBranch(
              navigatorKey: _providerShellNavigatorKeyChat,
              routes: [
                GoRoute(
                  path: '/provider-chat',
                  name: 'providerChat',
                  builder: (context, state) => BlocProvider<ChatListBloc>(
                    create: (context) => sl<ChatListBloc>(),
                    child: const ChatScreen(userType: UserType.provider),
                  ),
                  routes: [
                    GoRoute(
                      // Gunakan 'detail' sebagai path tetap dan userId sebagai query parameter
                      path: 'detail',
                      name: 'providerChatDetail',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        // Ambil userId dari query parameter, bukan path parameter
                        final userId = state.uri.queryParameters['userId'];
                        final extra = state.extra as Map<String, dynamic>?;

                        // Validasi userId
                        if (userId == null || userId.isEmpty) {
                          return const Center(
                            child: Text(
                              'ID pengguna tidak valid. Silakan kembali dan coba lagi.',
                            ),
                          );
                        }

                        if (extra != null) {
                          return BlocProvider(
                            create: (context) => sl<ChatBloc>(),
                            child: ChatDetailScreen(
                              otherUserId: userId,
                              otherUserName: extra['otherUserName'] as String?,
                              profilePicture:
                                  extra['profilePicture'] as String?,
                              userType: UserType.provider,
                            ),
                          );
                        } else {
                          final repo = sl<UserProfileRepositoryImpl>();
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: repo.getUserProfile(userId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Scaffold(
                                  body: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return Scaffold(
                                  appBar: AppBar(),
                                  body: const Center(
                                    child: Text('Gagal memuat data pengguna'),
                                  ),
                                );
                              }
                              final userProfile = snapshot.data!;
                              return BlocProvider(
                                create: (context) => sl<ChatBloc>(),
                                child: ChatDetailScreen(
                                  otherUserId: userId,
                                  otherUserName:
                                      userProfile['full_name'] as String?,
                                  profilePicture:
                                      userProfile['avatar_url'] as String?,
                                  userType: UserType.provider,
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Profile Branch
            StatefulShellBranch(
              navigatorKey: _providerShellNavigatorKeyProfile,
              routes: [
                GoRoute(
                  path: '/provider-profile',
                  name: 'providerProfile',
                  builder: (context, state) =>
                      ProfileScreen(authBloc: context.read<AuthBloc>()),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void dispose() {
    _goRouterRefreshStream.dispose();
  }
}
