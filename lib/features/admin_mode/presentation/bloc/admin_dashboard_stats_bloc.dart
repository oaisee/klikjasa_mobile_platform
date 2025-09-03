import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/admin_mode/domain/entities/admin_dashboard_stats.dart';
import 'package:klik_jasa/features/admin_mode/domain/repositories/admin_dashboard_repository.dart';

part 'admin_dashboard_stats_event.dart';
part 'admin_dashboard_stats_state.dart';

class AdminDashboardStatsBloc
    extends Bloc<AdminDashboardStatsEvent, AdminDashboardStatsState> {
  final AdminDashboardRepository repository;

  AdminDashboardStatsBloc({required this.repository})
    : super(CombinedDashboardState()) {
    on<LoadAdminDashboardStats>(_onLoadAdminDashboardStats);
    on<LoadTransactionsByPeriod>(_onLoadTransactionsByPeriod);
    on<LoadUserProvidersByPeriod>(_onLoadUserProvidersByPeriod);
    on<LoadOrderHistoryByPeriod>(_onLoadOrderHistoryByPeriod);
  }

  Future<void> _onLoadAdminDashboardStats(
    LoadAdminDashboardStats event,
    Emitter<AdminDashboardStatsState> emit,
  ) async {
    // Ambil state saat ini jika sudah CombinedDashboardState
    final currentState = state is CombinedDashboardState
        ? state as CombinedDashboardState
        : CombinedDashboardState();

    // Emit loading state untuk summary saja
    emit(currentState.copyWithSummary(isSummaryLoading: true));

    try {
      final stats = await repository.getDashboardStats();

      // Emit loaded state dengan data summary baru, tapi pertahankan data chart
      emit(
        currentState.copyWithSummary(
          summaryStats: stats,
          isSummaryLoading: false,
          summaryError: null,
        ),
      );
    } catch (error) {
      logger.e('Error in AdminDashboardStatsBloc: $error');

      // Emit error state untuk summary saja
      emit(
        currentState.copyWithSummary(
          isSummaryLoading: false,
          summaryError: error.toString(),
        ),
      );
    }
  }

  // Handler untuk memuat data transaksi berdasarkan periode
  Future<void> _onLoadTransactionsByPeriod(
    LoadTransactionsByPeriod event,
    Emitter<AdminDashboardStatsState> emit,
  ) async {
    emit(AdminDashboardStatsLoading());
    try {
      // Di sini kita akan memuat data transaksi dari database berdasarkan periode
      // Untuk sementara kita gunakan data dummy
      final Map<String, List<String>> labelsByPeriod = {
        'Minggu': ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
        'Bulan': [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des',
        ],
        'Tahun': ['2025', '2026', '2027', '2028', '2029', '2030'],
      };

      // Simulasi data transaksi dari database berdasarkan order_status
      final labels = labelsByPeriod[event.period] ?? [];
      final Map<String, int> transactionData = {};

      // Dummy data untuk setiap label (seharusnya diambil dari database)
      for (int i = 0; i < labels.length; i++) {
        transactionData[labels[i]] = (i + 1) * 5 + (i * 2); // Dummy formula
      }

      emit(
        TransactionDataLoaded(
          period: event.period,
          transactionData: transactionData,
          labels: labels,
        ),
      );
    } catch (error) {
      logger.e('Error loading transaction data: $error');
      emit(AdminDashboardStatsError(message: error.toString()));
    }
  }

  // Handler untuk memuat data user & provider berdasarkan periode
  Future<void> _onLoadUserProvidersByPeriod(
    LoadUserProvidersByPeriod event,
    Emitter<AdminDashboardStatsState> emit,
  ) async {
    // Ambil state saat ini jika sudah CombinedDashboardState
    final currentState = state is CombinedDashboardState
        ? state as CombinedDashboardState
        : CombinedDashboardState();

    // Emit loading state untuk user/provider chart saja
    emit(currentState.copyWithUserProvider(isUserProviderLoading: true));

    try {
      logger.d(
        '[AdminDashboardStatsBloc] Loading user-provider data for period: ${event.period}',
      );

      // Mengambil data dari repository yang terhubung ke Supabase
      final result = await repository.getUserProviderStatsByPeriod(
        event.period,
      );

      // Ekstrak data dari hasil query
      final List<String> labels = List<String>.from(result['labels']);
      final Map<String, int> userData = Map<String, int>.from(
        result['userData'],
      );
      final Map<String, int> providerData = Map<String, int>.from(
        result['providerData'],
      );
      final String period = result['period'];

      logger.d(
        '[AdminDashboardStatsBloc] User-provider data loaded successfully',
      );
      logger.d('[AdminDashboardStatsBloc] Labels: $labels');
      logger.d('[AdminDashboardStatsBloc] User data: $userData');
      logger.d('[AdminDashboardStatsBloc] Provider data: $providerData');

      // Buat objek UserProviderChartData
      final userProviderData = UserProviderChartData(
        period: period,
        userData: userData,
        providerData: providerData,
        labels: labels,
      );

      // Emit loaded state dengan data user/provider baru, tapi pertahankan data lainnya
      emit(
        currentState.copyWithUserProvider(
          userProviderData: userProviderData,
          isUserProviderLoading: false,
          userProviderError: null,
        ),
      );
    } catch (error) {
      logger.e('Error loading user & provider data: $error');

      // Emit error state untuk user/provider chart saja
      emit(
        currentState.copyWithUserProvider(
          isUserProviderLoading: false,
          userProviderError: error.toString(),
        ),
      );
    }
  }

  // Handler untuk memuat data histori transaksi berdasarkan periode
  Future<void> _onLoadOrderHistoryByPeriod(
    LoadOrderHistoryByPeriod event,
    Emitter<AdminDashboardStatsState> emit,
  ) async {
    // Ambil state saat ini jika sudah CombinedDashboardState
    final currentState = state is CombinedDashboardState
        ? state as CombinedDashboardState
        : CombinedDashboardState();

    // Emit loading state untuk order history chart saja
    emit(currentState.copyWithOrderHistory(isOrderHistoryLoading: true));

    try {
      logger.d(
        '[AdminDashboardStatsBloc] Loading order history data for period: ${event.period}',
      );

      // Mengambil data dari repository yang terhubung ke Supabase
      final Map<String, dynamic> result = await repository
          .getOrderHistoryByPeriod(event.period);

      // Ekstrak data dari hasil query
      final List<String> labels = List<String>.from(result['labels']);
      final Map<String, int> pendingOrdersData = Map<String, int>.from(
        result['pendingOrdersData'],
      );
      final Map<String, int> confirmedOrdersData = Map<String, int>.from(
        result['confirmedOrdersData'],
      );
      final Map<String, int> inProgressOrdersData = Map<String, int>.from(
        result['inProgressOrdersData'],
      );
      final Map<String, int> completedOrdersData = Map<String, int>.from(
        result['completedOrdersData'],
      );
      final Map<String, int> cancelledOrdersData = Map<String, int>.from(
        result['cancelledOrdersData'],
      );
      final String period = result['period'];

      logger.d(
        '[AdminDashboardStatsBloc] Order history data loaded successfully',
      );

      // Buat objek OrderHistoryChartData
      final orderHistoryData = OrderHistoryChartData(
        period: period,
        pendingOrdersData: pendingOrdersData,
        confirmedOrdersData: confirmedOrdersData,
        inProgressOrdersData: inProgressOrdersData,
        completedOrdersData: completedOrdersData,
        cancelledOrdersData: cancelledOrdersData,
        labels: labels,
      );

      // Emit loaded state dengan data order history baru, tapi pertahankan data lainnya
      emit(
        currentState.copyWithOrderHistory(
          orderHistoryData: orderHistoryData,
          isOrderHistoryLoading: false,
          orderHistoryError: null,
        ),
      );
    } catch (e) {
      // Emit error state untuk order history chart saja
      logger.e('Error loading order history data: $e');
      emit(
        currentState.copyWithOrderHistory(
          isOrderHistoryLoading: false,
          orderHistoryError: e.toString(),
        ),
      );
    }
  }
}
