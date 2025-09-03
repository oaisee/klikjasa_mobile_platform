part of 'admin_dashboard_stats_bloc.dart';

abstract class AdminDashboardStatsState extends Equatable {
  const AdminDashboardStatsState();

  @override
  List<Object> get props => [];
}

// Class untuk data chart user/provider
class UserProviderChartData extends Equatable {
  final String period;
  final Map<String, int> userData;
  final Map<String, int> providerData;
  final List<String> labels;

  const UserProviderChartData({
    required this.period,
    required this.userData,
    required this.providerData,
    required this.labels,
  });

  @override
  List<Object> get props => [period, userData, providerData, labels];
}

// Class untuk data chart order history
class OrderHistoryChartData extends Equatable {
  final String period;
  final Map<String, int> pendingOrdersData;
  final Map<String, int> confirmedOrdersData;
  final Map<String, int> inProgressOrdersData;
  final Map<String, int> completedOrdersData;
  final Map<String, int> cancelledOrdersData;
  final List<String> labels;

  const OrderHistoryChartData({
    required this.period,
    required this.pendingOrdersData,
    required this.confirmedOrdersData,
    required this.inProgressOrdersData,
    required this.completedOrdersData,
    required this.cancelledOrdersData,
    required this.labels,
  });

  @override
  List<Object> get props => [
    period, 
    pendingOrdersData, 
    confirmedOrdersData, 
    inProgressOrdersData, 
    completedOrdersData, 
    cancelledOrdersData, 
    labels
  ];
}

// Class untuk menyimpan state gabungan dari semua komponen dasbor
class CombinedDashboardState extends AdminDashboardStatsState {
  // State untuk summary dashboard
  final AdminDashboardStats? summaryStats;
  final bool isSummaryLoading;
  final String? summaryError;
  
  // State untuk chart user/provider
  final UserProviderChartData? userProviderData;
  final bool isUserProviderLoading;
  final String? userProviderError;
  
  // State untuk chart order history
  final OrderHistoryChartData? orderHistoryData;
  final bool isOrderHistoryLoading;
  final String? orderHistoryError;

  const CombinedDashboardState({
    this.summaryStats,
    this.isSummaryLoading = false,
    this.summaryError,
    this.userProviderData,
    this.isUserProviderLoading = false,
    this.userProviderError,
    this.orderHistoryData,
    this.isOrderHistoryLoading = false,
    this.orderHistoryError,
  });

  @override
  List<Object> get props => [
    if (summaryStats != null) summaryStats!,
    isSummaryLoading,
    if (summaryError != null) summaryError!,
    if (userProviderData != null) userProviderData!,
    isUserProviderLoading,
    if (userProviderError != null) userProviderError!,
    if (orderHistoryData != null) orderHistoryData!,
    isOrderHistoryLoading,
    if (orderHistoryError != null) orderHistoryError!,
  ];
  
  // Helper method untuk membuat salinan dengan perubahan pada state summary
  CombinedDashboardState copyWithSummary({
    AdminDashboardStats? summaryStats,
    bool? isSummaryLoading,
    String? summaryError,
  }) {
    return CombinedDashboardState(
      summaryStats: summaryStats ?? this.summaryStats,
      isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
      summaryError: summaryError,
      userProviderData: userProviderData,
      isUserProviderLoading: isUserProviderLoading,
      userProviderError: userProviderError,
      orderHistoryData: orderHistoryData,
      isOrderHistoryLoading: isOrderHistoryLoading,
      orderHistoryError: orderHistoryError,
    );
  }
  
  // Helper method untuk membuat salinan dengan perubahan pada state user/provider
  CombinedDashboardState copyWithUserProvider({
    UserProviderChartData? userProviderData,
    bool? isUserProviderLoading,
    String? userProviderError,
  }) {
    return CombinedDashboardState(
      summaryStats: summaryStats,
      isSummaryLoading: isSummaryLoading,
      summaryError: summaryError,
      userProviderData: userProviderData ?? this.userProviderData,
      isUserProviderLoading: isUserProviderLoading ?? this.isUserProviderLoading,
      userProviderError: userProviderError,
      orderHistoryData: orderHistoryData,
      isOrderHistoryLoading: isOrderHistoryLoading,
      orderHistoryError: orderHistoryError,
    );
  }
  
  // Helper method untuk membuat salinan dengan perubahan pada state order history
  CombinedDashboardState copyWithOrderHistory({
    OrderHistoryChartData? orderHistoryData,
    bool? isOrderHistoryLoading,
    String? orderHistoryError,
  }) {
    return CombinedDashboardState(
      summaryStats: summaryStats,
      isSummaryLoading: isSummaryLoading,
      summaryError: summaryError,
      userProviderData: userProviderData,
      isUserProviderLoading: isUserProviderLoading,
      userProviderError: userProviderError,
      orderHistoryData: orderHistoryData ?? this.orderHistoryData,
      isOrderHistoryLoading: isOrderHistoryLoading ?? this.isOrderHistoryLoading,
      orderHistoryError: orderHistoryError,
    );
  }
}

class AdminDashboardStatsInitial extends AdminDashboardStatsState {}

class AdminDashboardStatsLoading extends AdminDashboardStatsState {}

class AdminDashboardStatsLoaded extends AdminDashboardStatsState {
  final AdminDashboardStats stats;

  const AdminDashboardStatsLoaded({required this.stats});

  @override
  List<Object> get props => [stats];
}

class AdminDashboardStatsError extends AdminDashboardStatsState {
  final String message;

  const AdminDashboardStatsError({required this.message});

  @override
  List<Object> get props => [message];
}

class TransactionDataLoaded extends AdminDashboardStatsState {
  final String period; // 'Minggu', 'Bulan', 'Tahun'
  final Map<String, int> transactionData; // Map label ke jumlah transaksi
  final List<String> labels; // Label untuk chart (hari, bulan, tahun)

  const TransactionDataLoaded({
    required this.period,
    required this.transactionData,
    required this.labels,
  });

  @override
  List<Object> get props => [period, transactionData, labels];
}

class UserProviderDataLoaded extends AdminDashboardStatsState {
  final String period; // 'Minggu', 'Bulan', 'Tahun'
  final Map<String, int> userData; // Map label ke jumlah user
  final Map<String, int> providerData; // Map label ke jumlah provider
  final List<String> labels; // Label untuk chart (hari, bulan, tahun)
  
  // Tambahkan data summary agar tidak hilang saat refresh statistik
  final int pendingVerifications;
  final int totalActiveServices;
  final int transactionsThisMonth;

  const UserProviderDataLoaded({
    required this.period,
    required this.userData,
    required this.providerData,
    required this.labels,
    this.pendingVerifications = 0, // Default value jika tidak disediakan
    this.totalActiveServices = 0, // Default value jika tidak disediakan
    this.transactionsThisMonth = 0, // Default value jika tidak disediakan
  });

  @override
  List<Object> get props => [period, userData, providerData, labels, pendingVerifications, totalActiveServices, transactionsThisMonth];
  
  // Helper method untuk membuat salinan dengan data summary baru
  UserProviderDataLoaded copyWith({
    int? pendingVerifications,
    int? totalActiveServices,
    int? transactionsThisMonth,
  }) {
    return UserProviderDataLoaded(
      period: period,
      userData: userData,
      providerData: providerData,
      labels: labels,
      pendingVerifications: pendingVerifications ?? this.pendingVerifications,
      totalActiveServices: totalActiveServices ?? this.totalActiveServices,
      transactionsThisMonth: transactionsThisMonth ?? this.transactionsThisMonth,
    );
  }
}

class OrderHistoryDataLoaded extends AdminDashboardStatsState {
  final String period; // 'Minggu', 'Bulan', 'Tahun'
  final Map<String, int> pendingOrdersData; // Map label ke jumlah order menunggu
  final Map<String, int> confirmedOrdersData; // Map label ke jumlah order dikonfirmasi
  final Map<String, int> inProgressOrdersData; // Map label ke jumlah order dikerjakan
  final Map<String, int> completedOrdersData; // Map label ke jumlah order selesai
  final Map<String, int> cancelledOrdersData; // Map label ke jumlah order dibatalkan
  final List<String> labels; // Label untuk chart (hari, bulan, tahun)
  
  // Tambahkan data summary agar tidak hilang saat refresh statistik
  final int pendingVerifications;
  final int totalActiveServices;
  final int transactionsThisMonth;

  const OrderHistoryDataLoaded({
    required this.period,
    required this.pendingOrdersData,
    required this.confirmedOrdersData,
    required this.inProgressOrdersData,
    required this.completedOrdersData,
    required this.cancelledOrdersData,
    required this.labels,
    this.pendingVerifications = 0,
    this.totalActiveServices = 0,
    this.transactionsThisMonth = 0,
  });

  @override
  List<Object> get props => [
    period, 
    pendingOrdersData, 
    confirmedOrdersData, 
    inProgressOrdersData, 
    completedOrdersData, 
    cancelledOrdersData, 
    labels, 
    pendingVerifications, 
    totalActiveServices, 
    transactionsThisMonth
  ];
}
