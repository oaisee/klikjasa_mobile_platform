import 'package:klik_jasa/features/admin_mode/domain/entities/admin_dashboard_stats.dart';
import 'package:klik_jasa/features/admin_mode/domain/repositories/admin_dashboard_repository.dart';
import 'package:flutter/foundation.dart'; // Untuk debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  final SupabaseClient supabase;

  AdminDashboardRepositoryImpl({required this.supabase});

  Future<int> _fetchCount({
    required String tableName,
    required List<Map<String, dynamic>> filters,
  }) async {
    try {
      PostgrestFilterBuilder queryBuilder = supabase.from(tableName).select();
      for (var filter in filters) {
        final column = filter['column'] as String;
        final operator = filter['operator'] as String;
        final value = filter['value'];

        switch (operator) {
          case 'eq':
            queryBuilder = queryBuilder.eq(column, value);
            break;
          case 'neq':
            queryBuilder = queryBuilder.neq(column, value);
            break;
          case 'gt':
            queryBuilder = queryBuilder.gt(column, value);
            break;
          case 'gte':
            queryBuilder = queryBuilder.gte(column, value);
            break;
          case 'lt':
            queryBuilder = queryBuilder.lt(column, value);
            break;
          case 'lte':
            queryBuilder = queryBuilder.lte(column, value);
            break;
          // Tambahkan operator lain jika perlu (is, in, etc.)
          default:
            debugPrint('Unsupported filter operator: $operator');
        }
      }
      final response = await queryBuilder.count(CountOption.exact);
      // Debugging log spesifik bisa dipertahankan jika masih relevan
      // if (tableName == 'profiles' && filters.any((f) => f['column'] == 'provider_verification_status' && f['value'] == 'pending')) {
      //   debugPrint('Raw count for PENDING provider_verification_status in _fetchCount: $response');
      // }
      return response.count;
    } catch (e) {
      debugPrint('Error fetching count for $tableName with filters $filters: $e');
      // Melempar ulang error agar dapat ditangani oleh pemanggil (getDashboardStats -> BLoC)
      rethrow;
    }
  }

  @override
  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      debugPrint('[AdminRepo] Fetching totalUsers...');
      final totalUsers = await _fetchCount(
        tableName: 'profiles',
        filters: [{'column': 'role', 'operator': 'neq', 'value': 'admin'}], // Menghitung semua yang bukan admin
      );
      debugPrint('[AdminRepo] Fetched totalUsers: $totalUsers');
      debugPrint('[AdminRepo] Fetching totalProviders...');
      final totalProviders = await _fetchCount(
        tableName: 'profiles',
        filters: [
          {'column': 'provider_verification_status', 'operator': 'eq', 'value': 'verified'},
        ],
      );
      debugPrint('[AdminRepo] Fetched totalProviders: $totalProviders');
      debugPrint('[AdminRepo] Fetching pendingVerifications...');
      final pendingVerifications = await _fetchCount(
        tableName: 'profiles',
        filters: [
          {'column': 'provider_verification_status', 'operator': 'eq', 'value': 'pending'},
        ],
      );
      debugPrint('[AdminRepo] Fetched pendingVerifications: $pendingVerifications');

      // Mengambil total layanan aktif (asumsi tabel 'services' dan kolom 'status')
      debugPrint('[AdminRepo] Fetching totalActiveServices...');
      final totalActiveServices = await _fetchCount(
        tableName: 'services', // Ganti jika nama tabel berbeda
        filters: [
          {'column': 'is_active', 'operator': 'eq', 'value': true},
        ],
      );
      debugPrint('[AdminRepo] Fetched totalActiveServices: $totalActiveServices');

      // Mengambil transaksi bulan ini dari tabel 'orders' dengan filter order_date dan order_status
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String(); // Akhir hari di akhir bulan

      debugPrint('[AdminRepo] Fetching transactionsThisMonth from orders table...');
      
      // Menghitung semua transaksi dalam bulan ini (termasuk yang sedang berjalan dan selesai)
      // Status yang dihitung: accepted_by_provider, in_progress, completed_by_provider
      // Tidak termasuk: pending_confirmation, rejected_by_provider, cancelled_by_user, cancelled_by_provider, disputed
      
      // Ambil transaksi yang sudah selesai (completed_by_provider)
      final completedTransactions = await _fetchCount(
        tableName: 'orders',
        filters: [
          {'column': 'order_date', 'operator': 'gte', 'value': startOfMonth},
          {'column': 'order_date', 'operator': 'lte', 'value': endOfMonth},
          {'column': 'order_status', 'operator': 'eq', 'value': 'completed_by_provider'},
        ],
      );
      
      // Ambil transaksi yang sedang berjalan (accepted_by_provider, in_progress, completed_by_provider)
      final inProgressTransactions = await _fetchCount(
        tableName: 'orders',
        filters: [
          {'column': 'order_date', 'operator': 'gte', 'value': startOfMonth},
          {'column': 'order_date', 'operator': 'lte', 'value': endOfMonth},
          {'column': 'order_status', 'operator': 'eq', 'value': 'in_progress'},
        ],
      );
      
      final acceptedTransactions = await _fetchCount(
        tableName: 'orders',
        filters: [
          {'column': 'order_date', 'operator': 'gte', 'value': startOfMonth},
          {'column': 'order_date', 'operator': 'lte', 'value': endOfMonth},
          {'column': 'order_status', 'operator': 'eq', 'value': 'accepted_by_provider'},
        ],
      );
      
      final completedByProviderTransactions = await _fetchCount(
        tableName: 'orders',
        filters: [
          {'column': 'order_date', 'operator': 'gte', 'value': startOfMonth},
          {'column': 'order_date', 'operator': 'lte', 'value': endOfMonth},
          {'column': 'order_status', 'operator': 'eq', 'value': 'completed_by_provider'},
        ],
      );
      
      // Jumlahkan semua transaksi yang relevan
      final transactionsThisMonth = completedTransactions + inProgressTransactions + 
                                   acceptedTransactions + completedByProviderTransactions;
      
      debugPrint('[AdminRepo] Fetched transactionsThisMonth: $transactionsThisMonth');
      debugPrint('[AdminRepo] Details: completed=$completedTransactions, inProgress=$inProgressTransactions, ' 'accepted=$acceptedTransactions, completedByProvider=$completedByProviderTransactions');

      return AdminDashboardStats(
        totalUsers: totalUsers,
        totalProviders: totalProviders,
        pendingVerifications: pendingVerifications,
        totalActiveServices: totalActiveServices,
        transactionsThisMonth: transactionsThisMonth,
      );
    } catch (e) {
      // Error ini akan menangkap masalah yang lebih general, misal network error
      // atau jika salah satu Future.wait gagal karena exception yang tidak ditangani di _fetchCount (jika diubah menjadi throw e).
      debugPrint('Error in getDashboardStats: $e');
      throw Exception('Failed to fetch dashboard statistics: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getUserProviderStatsByPeriod(String period) async {
    try {
      debugPrint('[AdminRepo] Fetching user-provider stats by period: $period');
      final now = DateTime.now();
      
      // Inisialisasi variabel untuk rentang waktu dan label
      DateTime startDate;
      DateTime endDate = now;
      List<String> labels = [];
      Map<String, int> userData = {};
      Map<String, int> providerData = {};
      
      // Tentukan rentang waktu dan label berdasarkan periode
      switch (period) {
        case 'Minggu':
          // Ambil data 7 hari terakhir
          startDate = now.subtract(const Duration(days: 6));
          
          // Buat label untuk 7 hari (Minggu-Sabtu)
          final List<String> dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
          for (int i = 0; i < 7; i++) {
            final day = startDate.add(Duration(days: i));
            final dayName = dayNames[day.weekday % 7]; // 0 = Minggu, 1 = Senin, dst.
            labels.add(dayName);
            userData[dayName] = 0;
            providerData[dayName] = 0;
          }
          break;
          
        case 'Bulan':
          // Ambil data 12 bulan terakhir
          startDate = DateTime(now.year - 1, now.month + 1, 1);
          
          // Buat label untuk 12 bulan
          final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
          for (int i = 0; i < 12; i++) {
            final month = (startDate.month + i - 1) % 12;
            final monthName = monthNames[month];
            labels.add(monthName);
            userData[monthName] = 0;
            providerData[monthName] = 0;
          }
          break;
          
        case 'Tahun':
          // Ambil data 6 tahun (2025-2030)
          startDate = DateTime(2025, 1, 1);
          endDate = DateTime(2030, 12, 31);
          
          // Buat label untuk 6 tahun
          for (int year = 2025; year <= 2030; year++) {
            final yearStr = year.toString();
            labels.add(yearStr);
            userData[yearStr] = 0;
            providerData[yearStr] = 0;
          }
          break;
          
        default:
          throw Exception('Periode tidak valid: $period');
      }
      
      // Format tanggal untuk query
      final startDateStr = startDate.toIso8601String();
      final endDateStr = endDate.toIso8601String();
      
      // Query untuk mendapatkan jumlah pengguna berdasarkan tanggal registrasi
      final userResponse = await supabase
          .from('profiles')
          .select('created_at, role')
          .gte('created_at', startDateStr)
          .lte('created_at', endDateStr)
          .neq('role', 'admin')
          .order('created_at');
      
      // Query untuk mendapatkan jumlah penyedia jasa berdasarkan tanggal registrasi
      final providerResponse = await supabase
          .from('profiles')
          .select('created_at, provider_verification_status')
          .gte('created_at', startDateStr)
          .lte('created_at', endDateStr)
          .eq('provider_verification_status', 'verified')
          .order('created_at');
      
      // Proses data pengguna
      for (final user in userResponse) {
        final createdAt = DateTime.parse(user['created_at']);
        String key;
        
        switch (period) {
          case 'Minggu':
            final dayIndex = createdAt.weekday % 7; // 0 = Minggu, 1 = Senin, dst.
            final List<String> dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
            key = dayNames[dayIndex];
            break;
            
          case 'Bulan':
            final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
            key = monthNames[createdAt.month - 1];
            break;
            
          case 'Tahun':
            key = createdAt.year.toString();
            break;
            
          default:
            continue;
        }
        
        if (userData.containsKey(key)) {
          userData[key] = (userData[key] ?? 0) + 1;
        }
      }
      
      // Proses data penyedia jasa
      for (final provider in providerResponse) {
        final createdAt = DateTime.parse(provider['created_at']);
        String key;
        
        switch (period) {
          case 'Minggu':
            final dayIndex = createdAt.weekday % 7; // 0 = Minggu, 1 = Senin, dst.
            final List<String> dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
            key = dayNames[dayIndex];
            break;
            
          case 'Bulan':
            final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
            key = monthNames[createdAt.month - 1];
            break;
            
          case 'Tahun':
            key = createdAt.year.toString();
            break;
            
          default:
            continue;
        }
        
        if (providerData.containsKey(key)) {
          providerData[key] = (providerData[key] ?? 0) + 1;
        }
      }
      
      debugPrint('[AdminRepo] User-provider stats fetched successfully');
      return {
        'labels': labels,
        'userData': userData,
        'providerData': providerData,
        'period': period,
      };
    } catch (e) {
      debugPrint('Error fetching user-provider stats by period: $e');
      throw Exception('Failed to fetch user-provider statistics: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getOrderHistoryByPeriod(String period) async {
    try {
      debugPrint('[AdminRepo] Fetching order history by period: $period');
      final now = DateTime.now();
      
      // Inisialisasi variabel untuk rentang waktu dan label
      DateTime startDate;
      DateTime endDate = now;
      List<String> labels = [];
      Map<String, int> pendingOrdersData = {};
      Map<String, int> confirmedOrdersData = {};
      Map<String, int> inProgressOrdersData = {};
      Map<String, int> completedOrdersData = {};
      Map<String, int> cancelledOrdersData = {};
      
      // Tentukan rentang waktu dan label berdasarkan periode
      switch (period) {
        case 'Minggu':
          // Ambil data 7 hari terakhir
          startDate = now.subtract(const Duration(days: 6));
          
          // Buat label untuk 7 hari terakhir dengan format tanggal spesifik
          // untuk menghindari double-count pada hari yang sama dari minggu berbeda
          for (int i = 0; i < 7; i++) {
            final day = startDate.add(Duration(days: i));
            final dayName = '${day.day}/${day.month}'; // Format: DD/MM
            labels.add(dayName);
            pendingOrdersData[dayName] = 0;
            confirmedOrdersData[dayName] = 0;
            inProgressOrdersData[dayName] = 0;
            completedOrdersData[dayName] = 0;
            cancelledOrdersData[dayName] = 0;
          }
          break;
          
        case 'Bulan':
          // Ambil data 12 bulan terakhir
          startDate = DateTime(now.year - 1, now.month + 1, 1);
          
          // Buat label untuk 12 bulan
          final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
          for (int i = 0; i < 12; i++) {
            final month = (startDate.month + i - 1) % 12;
            final monthName = monthNames[month];
            labels.add(monthName);
            pendingOrdersData[monthName] = 0;
            confirmedOrdersData[monthName] = 0;
            inProgressOrdersData[monthName] = 0;
            completedOrdersData[monthName] = 0;
            cancelledOrdersData[monthName] = 0;
          }
          break;
          
        case 'Tahun':
          // Ambil data 6 tahun (2025-2030)
          startDate = DateTime(2025, 1, 1);
          endDate = DateTime(2030, 12, 31);
          
          // Buat label untuk 6 tahun
          for (int year = 2025; year <= 2030; year++) {
            final yearStr = year.toString();
            labels.add(yearStr);
            pendingOrdersData[yearStr] = 0;
            confirmedOrdersData[yearStr] = 0;
            inProgressOrdersData[yearStr] = 0;
            completedOrdersData[yearStr] = 0;
            cancelledOrdersData[yearStr] = 0;
          }
          break;
          
        default:
          throw Exception('Periode tidak valid: $period');
      }
      
      // Format tanggal untuk query
      final startDateStr = startDate.toIso8601String();
      final endDateStr = endDate.toIso8601String();
      
      // Query untuk mendapatkan semua order dalam rentang waktu
      final ordersResponse = await supabase
          .from('orders')
          .select('order_date, order_status')
          .gte('order_date', startDateStr)
          .lte('order_date', endDateStr)
          .order('order_date');
      
      // Log untuk debug jumlah total order
      debugPrint('[AdminRepo] Total orders fetched: ${ordersResponse.length}');
      
      // Hitung jumlah order per status untuk verifikasi
      int totalPending = 0;
      int totalConfirmed = 0;
      int totalInProgress = 0;
      int totalCompleted = 0;
      int totalCancelled = 0;
      
      // Proses data order berdasarkan status
      for (final order in ordersResponse) {
        final orderDate = DateTime.parse(order['order_date']);
        final orderStatus = order['order_status'] as String;
        String key;
        
        switch (period) {
          case 'Minggu':
            // Gunakan format tanggal spesifik untuk menghindari double-count
            key = '${orderDate.day}/${orderDate.month}';
            break;
            
          case 'Bulan':
            final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
            key = monthNames[orderDate.month - 1];
            break;
            
          case 'Tahun':
            key = orderDate.year.toString();
            break;
            
          default:
            continue;
        }
        
        // Kategorikan order berdasarkan status
        if (orderStatus == 'pending_confirmation') {
          // Order Menunggu
          totalPending++;
          pendingOrdersData[key] = (pendingOrdersData[key] ?? 0) + 1;
          debugPrint('[AdminRepo] Menambah order Menunggu untuk $key: ${pendingOrdersData[key]}');
        } else if (orderStatus == 'accepted_by_provider') {
          // Order Dikonfirmasi
          totalConfirmed++;
          confirmedOrdersData[key] = (confirmedOrdersData[key] ?? 0) + 1;
          debugPrint('[AdminRepo] Menambah order Dikonfirmasi untuk $key: ${confirmedOrdersData[key]}');
        } else if (orderStatus == 'in_progress' || orderStatus == 'completed_by_provider') {
          // Order Dikerjakan
          totalInProgress++;
          inProgressOrdersData[key] = (inProgressOrdersData[key] ?? 0) + 1;
          debugPrint('[AdminRepo] Menambah order Dikerjakan untuk $key: ${inProgressOrdersData[key]}');
        } else if (orderStatus == 'completed_by_provider') {
          // Order Selesai
          totalCompleted++;
          completedOrdersData[key] = (completedOrdersData[key] ?? 0) + 1;
          debugPrint('[AdminRepo] Menambah order Selesai untuk $key: ${completedOrdersData[key]}');
        } else if (orderStatus == 'cancelled_by_user' || orderStatus == 'cancelled_by_provider' || 
                  orderStatus == 'rejected_by_provider' || orderStatus == 'disputed') {
          // Order Dibatalkan
          totalCancelled++;
          cancelledOrdersData[key] = (cancelledOrdersData[key] ?? 0) + 1;
          debugPrint('[AdminRepo] Menambah order Dibatalkan untuk $key: ${cancelledOrdersData[key]}');
        } else {
          // Log status yang tidak termasuk dalam kategori di atas
          debugPrint('[AdminRepo] Status tidak terkategorisasi: $orderStatus');
        }
      }
      
      // Log jumlah order per status untuk verifikasi
      debugPrint('[AdminRepo] Jumlah order per status:');
      debugPrint('[AdminRepo] - Menunggu: $totalPending');
      debugPrint('[AdminRepo] - Dikonfirmasi: $totalConfirmed');
      debugPrint('[AdminRepo] - Dikerjakan: $totalInProgress');
      debugPrint('[AdminRepo] - Selesai: $totalCompleted');
      debugPrint('[AdminRepo] - Dibatalkan: $totalCancelled');
      debugPrint('[AdminRepo] - Total: ${totalPending + totalConfirmed + totalInProgress + totalCompleted + totalCancelled}');
      
      debugPrint('[AdminRepo] Order history fetched successfully');
      return {
        'labels': labels,
        'pendingOrdersData': pendingOrdersData,
        'confirmedOrdersData': confirmedOrdersData,
        'inProgressOrdersData': inProgressOrdersData,
        'completedOrdersData': completedOrdersData,
        'cancelledOrdersData': cancelledOrdersData,
        'period': period,
      };
    } catch (e) {
      debugPrint('Error fetching order history by period: $e');
      throw Exception('Failed to fetch order history: ${e.toString()}');
    }
  }
}
