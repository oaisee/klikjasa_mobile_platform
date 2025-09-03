import 'package:equatable/equatable.dart';

class AdminDashboardStats extends Equatable {
  final int totalUsers;
  final int totalProviders;
  final int pendingVerifications;
  final int totalActiveServices;
  final int transactionsThisMonth;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalProviders,
    required this.pendingVerifications,
    required this.totalActiveServices,
    required this.transactionsThisMonth,
  });

  @override
  List<Object?> get props => [totalUsers, totalProviders, pendingVerifications, totalActiveServices, transactionsThisMonth];
}
