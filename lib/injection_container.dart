import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/common/app_config/data/datasources/app_config_remote_data_source.dart';
import 'package:klik_jasa/features/common/app_config/data/datasources/supabase_app_config_remote_data_source.dart';
import 'package:klik_jasa/features/common/app_config/data/repositories/app_config_repository_impl.dart';
import 'package:klik_jasa/features/common/app_config/domain/repositories/app_config_repository.dart';
import 'package:klik_jasa/features/common/app_config/domain/usecases/get_all_app_configs.dart';
import 'package:klik_jasa/features/common/app_config/domain/usecases/get_app_config_by_key.dart'
    as app_config_key;
import 'package:klik_jasa/features/common/app_config/domain/usecases/update_app_config.dart'
    as update_app_config;
import 'package:klik_jasa/features/common/app_config/domain/usecases/get_user_fee_percentage.dart';
import 'package:klik_jasa/features/common/app_config/domain/usecases/get_provider_fee_percentage.dart';
import 'package:klik_jasa/features/common/app_config/domain/usecases/calculate_order_fee.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/data/datasources/order_remote_data_source.dart';
import 'package:klik_jasa/core/data/datasources/supabase/supabase_order_remote_data_source.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/data/datasources/provider_order_remote_data_source.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/data/repositories/order_repository_impl.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/repositories/order_repository.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/usecases/get_incoming_orders_usecase.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/usecases/update_order_status_usecase.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/usecases/get_provider_total_revenue_usecase.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/usecases/get_provider_active_orders_count_usecase.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/usecases/get_provider_orders_usecase.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/presentation/bloc/incoming_orders/incoming_orders_bloc.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/presentation/bloc/provider_orders/provider_orders_bloc.dart';
import 'package:klik_jasa/features/common/balance/data/datasources/user_balance_remote_data_source.dart';
import 'package:klik_jasa/features/common/balance/data/datasources/top_up_history_remote_data_source.dart';
import 'package:klik_jasa/features/common/balance/data/repositories/user_balance_repository_impl.dart';
import 'package:klik_jasa/features/common/balance/data/repositories/top_up_repository_impl.dart';
import 'package:klik_jasa/features/common/balance/domain/repositories/user_balance_repository.dart';
import 'package:klik_jasa/features/common/balance/domain/repositories/top_up_repository.dart';
import 'package:klik_jasa/features/common/balance/domain/usecases/get_user_balance_usecase.dart';
import 'package:klik_jasa/features/common/balance/domain/usecases/deduct_promotion_balance_usecase.dart';
import 'package:klik_jasa/features/common/balance/domain/usecases/deduct_checkout_fee_usecase.dart';

import 'package:klik_jasa/features/common/balance/domain/usecases/create_top_up_usecase.dart';
import 'package:klik_jasa/features/common/balance/domain/usecases/process_successful_top_up_usecase.dart';
import 'package:klik_jasa/features/common/balance/domain/usecases/get_top_up_history_usecase.dart';
import 'package:klik_jasa/features/common/balance/presentation/bloc/balance_bloc.dart';
import 'package:klik_jasa/core/network/network_info.dart';
import 'package:klik_jasa/core/network/network_info_impl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:klik_jasa/features/common/auth/data/datasources/auth_remote_data_source.dart';
import 'package:klik_jasa/features/common/auth/data/datasources/supabase_auth_remote_data_source.dart';
import 'package:klik_jasa/features/common/auth/data/repositories/auth_repository_impl.dart';
import 'package:klik_jasa/features/common/auth/data/services/social_auth_service.dart';
import 'package:klik_jasa/features/common/auth/data/services/biometric_auth_service.dart';

import 'package:klik_jasa/features/common/auth/domain/repositories/auth_repository.dart';
import 'package:klik_jasa/features/common/auth/domain/usecases/get_auth_state_stream_usecase.dart';
import 'package:klik_jasa/features/common/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:klik_jasa/features/common/auth/domain/usecases/sign_in_user_usecase.dart';
import 'package:klik_jasa/features/common/auth/domain/usecases/sign_out_user_usecase.dart';
import 'package:klik_jasa/features/common/auth/domain/usecases/sign_up_user_usecase.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/notifications/data/datasources/notification_local_data_source.dart';
import 'package:klik_jasa/features/common/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:klik_jasa/features/common/notifications/data/repositories/notification_repository_impl.dart';
import 'package:klik_jasa/features/common/notifications/domain/repositories/notification_repository.dart';
import 'package:klik_jasa/features/common/notifications/domain/usecases/get_notifications.dart';
import 'package:klik_jasa/features/common/notifications/domain/usecases/mark_as_read.dart';
import 'package:klik_jasa/features/common/notifications/domain/usecases/mark_all_as_read.dart';
import 'package:klik_jasa/features/common/notifications/domain/usecases/create_notification.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_bloc.dart';
import 'package:klik_jasa/features/common/chat/di/chat_injection_container.dart'
    as chat_di;
import 'package:klik_jasa/features/admin_mode/presentation/bloc/app_settings/app_settings_bloc.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/get_provider_layanan_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/add_layanan_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/update_layanan_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/delete_layanan_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/get_layanan_detail_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/get_provider_services_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/toggle_service_promotion_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/toggle_service_active_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/repositories/service_provider_repository.dart';
import 'package:klik_jasa/features/provider_mode/services/data/repositories/service_provider_repository_impl.dart';
import 'package:klik_jasa/features/provider_mode/services/data/datasources/service_provider_remote_data_source.dart';
import 'package:klik_jasa/core/data/datasources/supabase/supabase_service_provider_remote_data_source.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/bloc/services_bloc.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/application/blocs/provider_summary_bloc/provider_summary_bloc.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/usecases/get_provider_summary_data_usecase.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/repositories/provider_summary_repository.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/data/repositories/provider_summary_repository_impl.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/data/datasources/provider_summary_remote_data_source.dart';
import 'package:klik_jasa/core/data/contracts/supabase_rpc_contract.dart';
import 'package:klik_jasa/core/data/adapters/supabase_rpc_adapter.dart';
import 'package:klik_jasa/core/data/datasources/supabase/supabase_provider_summary_remote_data_source.dart';
import 'package:klik_jasa/features/common/profile/domain/repositories/region_repository.dart';
import 'package:klik_jasa/features/common/profile/data/repositories/region_repository_impl.dart';
import 'package:klik_jasa/features/common/profile/data/datasources/region_remote_data_source.dart';
import 'package:klik_jasa/features/common/profile/domain/usecases/get_provinces_usecase.dart';
import 'package:klik_jasa/features/common/profile/domain/usecases/get_kabupaten_kota_usecase.dart';
import 'package:klik_jasa/features/common/profile/domain/usecases/get_kecamatan_usecase.dart';
import 'package:klik_jasa/features/common/profile/domain/usecases/get_desa_kelurahan_usecase.dart';
import 'package:klik_jasa/features/common/profile/presentation/bloc/region/region_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:klik_jasa/features/common/profile/presentation/cubit/provider_registration_cubit.dart';
import 'package:klik_jasa/features/common/orders/domain/repositories/order_repository.dart'
    as common_orders;
import 'package:klik_jasa/features/common/orders/data/repositories/order_repository_impl.dart'
    as common_orders;
import 'package:klik_jasa/features/common/orders/data/datasources/order_remote_data_source.dart'
    as common_orders;
import 'package:klik_jasa/features/common/orders/domain/usecases/complete_order_usecase.dart';
import 'package:klik_jasa/features/user_mode/home/data/datasources/category_remote_data_source.dart';
import 'package:klik_jasa/features/user_mode/home/data/repositories/category_repository_impl.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/category_repository.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/category_cubit.dart';
import 'package:klik_jasa/features/user_mode/home/data/datasources/service_data_source.dart';
import 'package:klik_jasa/features/user_mode/home/data/repositories/service_repository_impl.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/service_repository.dart';
import 'package:klik_jasa/features/user_mode/home/domain/usecases/get_promoted_services.dart';
import 'package:klik_jasa/features/user_mode/home/domain/usecases/get_services_by_highest_rating.dart';
import 'package:klik_jasa/features/user_mode/home/domain/usecases/get_services_by_location.dart';
import 'package:klik_jasa/features/user_mode/home/domain/usecases/get_services_with_promotion_priority.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/service_location_cubit.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/recommended_services_cubit.dart';
import 'package:klik_jasa/features/user_mode/home/data/repositories/promotional_banner_repository_impl.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/promotional_banner_repository.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/promotional_banner_cubit.dart';
// Search
import 'package:klik_jasa/features/user_mode/search/presentation/cubit/search_cubit.dart';
import 'package:klik_jasa/features/user_mode/search/domain/usecases/search_services_usecase.dart';
import 'package:klik_jasa/features/user_mode/search/domain/repositories/search_repository.dart';
import 'package:klik_jasa/features/user_mode/search/data/repositories/search_repository_impl.dart';
import 'package:klik_jasa/features/user_mode/search/data/datasources/search_remote_data_source.dart';
// Admin Mode
import 'package:klik_jasa/features/admin_mode/domain/repositories/user_profile_repository.dart';
import 'package:klik_jasa/features/admin_mode/data/repositories/user_profile_repository_impl.dart';

final sl = GetIt.instance;

// PENTING: Jangan mendaftarkan dependency yang sama lebih dari sekali!
// Lihat docs/dependency_injection_guidelines.md untuk panduan lengkap

Future<void> init() async {
  // Logger
  sl.registerLazySingleton(() => Logger());

  // ===== CORE & EXTERNAL DEPENDENCIES =====
  // Daftarkan semua core dan external dependencies di sini
  // JANGAN mendaftarkan ulang di bagian lain dari file

  // External Services
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Supabase.instance.client);
  sl.registerLazySingleton(() => ImagePicker());

  // Core Services
  sl.registerLazySingleton(
    () => Connectivity(),
  ); // PENTING: Jangan didaftarkan ulang!
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );

  // Initialize all dependencies
  _initCoreDependencies();
  _initAuthDependencies();
  _initBalanceDependencies();
  _initNotificationDependencies();
  _initChatDependencies();
  _initOrderDependencies();
  _initProviderServicesDependencies();
  _initProviderDashboardDependencies();
  _initRegionDependencies();
  _initCategoryDependencies();
  _initServiceLocationDependencies();
  _initRecommendedServicesDependencies();
  _initPromotionalBannerDependencies();
  _initSearchDependencies();
  _initAdminDependencies();
}

Future<void> _initCoreDependencies() async {
  // App Config Repository
  sl.registerLazySingleton<AppConfigRemoteDataSource>(
    () => SupabaseAppConfigRemoteDataSource(supabaseClient: sl(), logger: sl()),
  );
  sl.registerLazySingleton<AppConfigRepository>(
    () => AppConfigRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
    ),
  );

  // App Config Use Cases
  sl.registerLazySingleton(
    () => GetAllAppConfigs(repository: sl<AppConfigRepository>()),
  );
  sl.registerLazySingleton(
    () =>
        app_config_key.GetAppConfigByKey(repository: sl<AppConfigRepository>()),
  );
  sl.registerLazySingleton(
    () => update_app_config.UpdateAppConfig(
      repository: sl<AppConfigRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetUserFeePercentage(sl<AppConfigRepository>()),
  );
  sl.registerLazySingleton(
    () => GetProviderFeePercentage(sl<AppConfigRepository>()),
  );
  sl.registerLazySingleton(
    () => CalculateOrderFee(repository: sl<AppConfigRepository>()),
  );

  // App Settings BLoC
  sl.registerFactory(
    () => AppSettingsBloc(
      getAllAppSettings: sl<GetAllAppConfigs>(),
      getAppSettingByKey: sl<app_config_key.GetAppConfigByKey>(),
      updateAppSetting: sl<update_app_config.UpdateAppConfig>(),
      logger: sl<Logger>(),
    ),
  );
}

Future<void> _initAuthDependencies() async {
  // BLoC
  sl.registerLazySingleton(() => AuthBloc(authRepository: sl()));

  // Use Cases
  sl.registerLazySingleton(() => SignInUserUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUserUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUserUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => GetAuthStateStreamUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authRemoteDataSource: sl(),
      socialAuthService: sl(),
      supabaseClient: sl(),
      logger: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => SupabaseAuthRemoteDataSource(supabaseAuth: sl<SupabaseClient>().auth),
  );

  // Services
  sl.registerLazySingleton(() => SocialAuthService());
  sl.registerLazySingleton(() => BiometricAuthService());

}

Future<void> _initBalanceDependencies() async {
  // BLoC
  sl.registerFactory(
    () => BalanceBloc(
      getUserBalanceUsecase: sl<GetUserBalanceUsecase>(),
      authBloc: sl(),
    ),
  );

  // Use Cases - Balance
  sl.registerLazySingleton(() => GetUserBalanceUsecase(sl()));
  sl.registerLazySingleton(() => DeductPromotionBalanceUsecase(sl()));
  sl.registerLazySingleton(
    () => DeductCheckoutFeeUsecase(sl(), sl<AppConfigRepository>()),
  );

  // Use Cases - Top Up
  sl.registerLazySingleton(() => CreateTopUpUseCase(sl<TopUpRepository>()));
  sl.registerLazySingleton(
    () => ProcessSuccessfulTopUpUseCase(sl<TopUpRepository>()),
  );
  sl.registerLazySingleton(() => GetTopUpHistoryUseCase(sl<TopUpRepository>()));

  // Repository - Balance
  sl.registerLazySingleton<UserBalanceRepository>(
    () => UserBalanceRepositoryImpl(remoteDataSource: sl()),
  );

  // Repository - Top Up
  sl.registerLazySingleton<TopUpRepository>(
    () => TopUpRepositoryImpl(
      topUpHistoryDataSource: sl<TopUpHistoryRemoteDataSource>(),
      userBalanceDataSource: sl<UserBalanceRemoteDataSource>(),
      supabaseClient: sl(),
    ),
  );

  // Data Sources - Balance
  sl.registerLazySingleton<UserBalanceRemoteDataSource>(
    () => UserBalanceRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Data Sources - Top Up History
  sl.registerLazySingleton<TopUpHistoryRemoteDataSource>(
    () => TopUpHistoryRemoteDataSourceImpl(supabaseClient: sl()),
  );
}

Future<void> _initNotificationDependencies() async {
  // BLoC
  sl.registerFactory(
    () => NotificationBloc(
      getNotifications: sl(),
      markAsRead: sl(),
      markAllAsRead: sl(),
      createNotification: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => MarkAsRead(sl()));
  sl.registerLazySingleton(() => MarkAllAsRead(sl()));
  sl.registerLazySingleton(() => CreateNotification(sl()));

  // Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => SupabaseNotificationRemoteDataSource(supabaseClient: sl()),
  );
  sl.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationLocalDataSourceImpl(sharedPreferences: sl()),
  );
}

Future<void> _initChatDependencies() async {
  // Menggunakan dependency injection dari common/chat
  chat_di.initChatDependencies();
}

Future<void> _initOrderDependencies() async {
  // BLoC
  sl.registerFactory(
    () => IncomingOrdersBloc(
      sl(), // GetIncomingOrdersUseCase
      sl(), // UpdateOrderStatusUseCase
      sl<CreateNotification>(), // CreateNotification
    ),
  );

  sl.registerFactory(
    () => ProviderOrdersBloc(
      getProviderOrdersUseCase: sl(),
      updateOrderStatusUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetIncomingOrdersUseCase(sl()));
  sl.registerLazySingleton(() => UpdateOrderStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetProviderTotalRevenueUseCase(sl()));
  sl.registerLazySingleton(() => GetProviderActiveOrdersCountUseCase(sl()));
  sl.registerLazySingleton(() => GetProviderOrdersUseCase(sl()));
  sl.registerLazySingleton(
    () => CompleteOrderUseCase(
      repository: sl<common_orders.OrderRepository>(),
      createNotification: sl<CreateNotification>(),
    ),
  );

  // Repository
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<common_orders.OrderRepository>(
    () => common_orders.OrderRepositoryImpl(
      remoteDataSource: sl<common_orders.OrderRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => SupabaseOrderRemoteDataSource(supabaseClient: sl()),
  );

  sl.registerLazySingleton<ProviderOrderRemoteDataSource>(
    () => SupabaseProviderOrderRemoteDataSource(supabaseClient: sl()),
  );

  sl.registerLazySingleton<common_orders.OrderRemoteDataSource>(
    () => common_orders.SupabaseOrderRemoteDataSource(supabaseClient: sl()),
  );
}

Future<void> _initProviderServicesDependencies() async {
  // BLoC
  sl.registerFactory(
    () => ServicesBloc(
      getProviderLayananUseCase: sl(),
      addLayananUseCase: sl(),
      updateLayananUseCase: sl(),
      deleteLayananUseCase: sl(),
      getLayananDetailUseCase: sl(),
      toggleServicePromotionUsecase: sl(),
      toggleServiceActiveUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerFactory<GetProviderLayananUseCase>(
    () => GetProviderLayananUseCase(sl<ServiceProviderRepository>()),
  );
  sl.registerFactory<AddLayananUseCase>(
    () => AddLayananUseCase(sl<ServiceProviderRepository>()),
  );
  sl.registerFactory<UpdateLayananUseCase>(
    () => UpdateLayananUseCase(sl<ServiceProviderRepository>()),
  );
  sl.registerFactory<DeleteLayananUseCase>(
    () => DeleteLayananUseCase(sl<ServiceProviderRepository>()),
  );
  sl.registerFactory<GetLayananDetailUseCase>(
    () => GetLayananDetailUseCase(sl<ServiceProviderRepository>()),
  );
  sl.registerFactory<GetProviderServicesUseCase>(
    () => GetProviderServicesUseCase(sl<ServiceProviderRepository>()),
  );
  sl.registerFactory<ToggleServiceActiveUseCase>(
    () => ToggleServiceActiveUseCase(sl<ServiceProviderRepository>()),
  );
  sl.registerLazySingleton(
    () => ToggleServicePromotionUsecase(
      serviceProviderRepository: sl<ServiceProviderRepository>(),
      deductPromotionBalanceUsecase: sl<DeductPromotionBalanceUsecase>(),
    ),
  );

  // Repository
  sl.registerLazySingleton<ServiceProviderRepository>(
    () => ServiceProviderRepositoryImpl(
      remoteDataSource: sl<ServiceProviderRemoteDataSource>(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<ServiceProviderRemoteDataSource>(
    () => SupabaseServiceProviderRemoteDataSource(supabaseClient: sl()),
  );
}

Future<void> _initProviderDashboardDependencies() async {
  // BLoC
  sl.registerFactory(
    () => ProviderSummaryBloc(sl<WatchProviderSummaryDataUseCase>()),
  );

  // Use Cases
  sl.registerLazySingleton(
    () => WatchProviderSummaryDataUseCase(sl<ProviderSummaryRepository>()),
  );

  // Repository
  sl.registerLazySingleton<ProviderSummaryRepository>(
    () => ProviderSummaryRepositoryImpl(sl<ProviderSummaryRemoteDataSource>()),
  );

  // Data Sources
  sl.registerLazySingleton<SupabaseRpcContract>(
    () => SupabaseRpcAdapter(supabaseClient: sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ProviderSummaryRemoteDataSource>(
    () => SupabaseProviderSummaryRemoteDataSource(
      sl<SupabaseRpcContract>(),
      supabaseClient: sl<SupabaseClient>(),
    ),
  );
}

Future<void> _initRegionDependencies() async {
  // BLoC
  sl.registerFactory(
    () => RegionBloc(
      getProvincesUseCase: sl(),
      getKabupatenKotaUseCase: sl(),
      getKecamatanUseCase: sl(),
      getDesaKelurahanUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetProvincesUseCase(sl()));
  sl.registerLazySingleton(() => GetKabupatenKotaUseCase(sl()));
  sl.registerLazySingleton(() => GetKecamatanUseCase(sl()));
  sl.registerLazySingleton(() => GetDesaKelurahanUseCase(sl()));

  // Repository
  sl.registerLazySingleton<RegionRepository>(
    () => RegionRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<RegionRemoteDataSource>(
    () => RegionRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Provider Registration Cubit
  sl.registerFactory(
    () => ProviderRegistrationCubit(
      supabase: sl<SupabaseClient>(),
      picker: sl<ImagePicker>(),
      logger: sl<Logger>(),
    ),
  );
}

Future<void> _initCategoryDependencies() async {
  // Cubit
  sl.registerFactory(() => CategoryCubit(repository: sl()));

  // Repository
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(supabaseClient: sl<SupabaseClient>()),
  );
}

Future<void> _initServiceLocationDependencies() async {
  // Cubit
  sl.registerFactory(
    () => ServiceLocationCubit(
      getServicesByLocation: sl(),
      getPromotedServices: sl(),
      getServicesByHighestRating: sl(),
      getServicesWithPromotionPriority: sl(),
      serviceRepository: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetServicesByLocation(sl()));
  sl.registerLazySingleton(() => GetPromotedServices(sl()));
  sl.registerLazySingleton(() => GetServicesByHighestRating(sl()));
  sl.registerLazySingleton(() => GetServicesWithPromotionPriority(sl()));

  // Repository
  sl.registerLazySingleton<ServiceRepository>(
    () => ServiceRepositoryImpl(dataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<ServiceDataSource>(
    () => ServiceDataSourceImpl(supabaseClient: sl<SupabaseClient>()),
  );
}

Future<void> _initRecommendedServicesDependencies() async {
  // Cubit
  sl.registerFactory(() => RecommendedServicesCubit());
}

Future<void> _initPromotionalBannerDependencies() async {
  // Cubit
  sl.registerFactory(
    () => PromotionalBannerCubit(repository: sl<PromotionalBannerRepository>()),
  );

  // Repository
  sl.registerLazySingleton<PromotionalBannerRepository>(
    () => PromotionalBannerRepositoryImpl(supabaseClient: sl<SupabaseClient>()),
  );
}

void _initSearchDependencies() {
  // Cubit
  sl.registerFactory(() => SearchCubit(SearchServicesUseCase(sl())));

  // Use cases
  sl.registerLazySingleton(() => SearchServicesUseCase(sl()));

  // Repository
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSource(sl<SupabaseClient>()),
  );
}

void _initAdminDependencies() {
  // Repository
  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(supabase: sl<SupabaseClient>()),
  );

  // Register concrete implementation for direct access
  sl.registerLazySingleton<UserProfileRepositoryImpl>(
    () => UserProfileRepositoryImpl(supabase: sl<SupabaseClient>()),
  );
}
