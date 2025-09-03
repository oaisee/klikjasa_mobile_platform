part of 'admin_dashboard_stats_bloc.dart';

abstract class AdminDashboardStatsEvent extends Equatable {
  const AdminDashboardStatsEvent();

  @override
  List<Object> get props => [];
}

class LoadAdminDashboardStats extends AdminDashboardStatsEvent {}

class LoadTransactionsByPeriod extends AdminDashboardStatsEvent {
  final String period; // 'Minggu', 'Bulan', 'Tahun'

  const LoadTransactionsByPeriod({required this.period});

  @override
  List<Object> get props => [period];
}

class LoadUserProvidersByPeriod extends AdminDashboardStatsEvent {
  final String period; // 'Minggu', 'Bulan', 'Tahun'

  const LoadUserProvidersByPeriod({required this.period});

  @override
  List<Object> get props => [period];
}

class LoadOrderHistoryByPeriod extends AdminDashboardStatsEvent {
  final String period; // 'Minggu', 'Bulan', 'Tahun'

  const LoadOrderHistoryByPeriod({required this.period});

  @override
  List<Object> get props => [period];
}
