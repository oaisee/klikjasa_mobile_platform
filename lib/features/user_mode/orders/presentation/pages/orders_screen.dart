import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:klik_jasa/features/common/orders/domain/repositories/order_repository.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/injection_container.dart' as di;

/// Screen untuk menampilkan pesanan pengguna
///
/// Menggunakan nama kelas dalam bahasa Inggris (OrdersScreen) untuk konsistensi,
/// tetapi juga mengekspor PesananScreen sebagai alias untuk kompatibilitas dengan kode lama
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _hasOrders = false;
  List<Map<String, dynamic>> _orders = [];
  late OrderRepository _orderRepository;
  late GetCurrentUserUseCase _getCurrentUserUsecase;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Menambahkan listener untuk mendeteksi perubahan tab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _orderRepository = di.sl<OrderRepository>();
    _getCurrentUserUsecase = di.sl<GetCurrentUserUseCase>();
    _refreshOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color.fromRGBO(255, 255, 255, 0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Selesai'),
            Tab(text: 'Dibatalkan'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasOrders
          ? _buildOrdersList()
          : _buildEmptyState(),
      // Menambahkan gesture detector untuk menangani swipe horizontal
      resizeToAvoidBottomInset: true,
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Pesanan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda belum memiliki pesanan layanan',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigasi ke halaman beranda
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cari Layanan'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshOrders() async {
    try {
      final currentUserResult = await _getCurrentUserUsecase(const NoParams());
      currentUserResult.fold(
        (failure) {
          logger.e('Error mendapatkan user saat ini: ${failure.message}');
          setState(() {
            _hasOrders = false;
          });
        },
        (user) async {
          if (user != null) {
            final ordersResult = await _orderRepository.getUserOrders(user.id);
            ordersResult.fold(
              (failure) {
                logger.e('Error mendapatkan pesanan: ${failure.message}');
                setState(() {
                  _isLoading = false;
                  _hasOrders = false;
                });
              },
              (orders) {
                // Debug: Memeriksa status pesanan yang diterima
                for (var order in orders) {
                  logger.d(
                    'Order ID: ${order['id']}, Status: ${order['order_status']}',
                  );
                }

                // Debug: Memeriksa jumlah pesanan dibatalkan
                final cancelledOrders = orders
                    .where(
                      (order) =>
                          order['order_status'] == 'cancelled' ||
                          order['order_status'] == 'rejected',
                    )
                    .toList();
                logger.d(
                  'Jumlah pesanan dibatalkan: ${cancelledOrders.length}',
                );

                setState(() {
                  _orders = orders;
                  _isLoading = false;
                  _hasOrders = orders.isNotEmpty;
                });
              },
            );
          } else {
            setState(() {
              _isLoading = false;
              _hasOrders = false;
            });
          }
        },
      );
    } catch (e) {
      logger.e('Error tidak terduga saat memuat pesanan: $e');
      setState(() {
        _isLoading = false;
        _hasOrders = false;
      });
    }
  }

  Widget _buildOrdersList() {
    // Menggunakan data pesanan dari Supabase

    return TabBarView(
      controller: _tabController,
      // Memastikan swipe gesture diaktifkan
      physics: const BouncingScrollPhysics(),
      children: [
        // Tab Aktif - hanya menampilkan pesanan yang masih aktif (menunggu konfirmasi, diterima, dikerjakan)
        _buildOrdersListView(
          _orders
              .where(
                (order) =>
                    order['order_status'] == 'pending_confirmation' ||
                    order['order_status'] == 'accepted_by_provider' ||
                    order['order_status'] == 'in_progress',
              )
              .toList(),
        ),
        // Tab Selesai - menampilkan semua pesanan yang telah selesai
        _buildOrdersListView(
          _orders
              .where(
                (order) =>
                    order['order_status'] == 'completed_by_provider' ||
                    order['order_status'] == 'completed_by_provider',
              )
              .toList(),
        ),
        // Tab Dibatalkan - menampilkan semua pesanan yang dibatalkan atau ditolak
        _buildOrdersListView(
          _orders
              .where(
                (order) =>
                    order['order_status'] == 'cancelled_by_user' ||
                    order['order_status'] == 'cancelled_by_provider' ||
                    order['order_status'] == 'rejected_by_provider' ||
                    order['order_status'] == 'cancelled' ||
                    order['order_status'] == 'rejected',
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildOrdersListView(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Pesanan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderItem(order);
        },
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    Color statusColor;
    String statusText;

    switch (order['order_status']) {
      case 'pending_confirmation':
        statusColor = Colors.orange;
        statusText = 'Menunggu Konfirmasi';
        break;
      case 'accepted_by_provider':
        statusColor = Colors.blue;
        statusText = 'Diterima';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = 'Sedang Dikerjakan';
        break;
      case 'completed_by_provider':
        statusColor = Colors.green;
        statusText = 'Selesai';
        break;
      case 'cancelled_by_user':
        statusColor = Colors.red;
        statusText = 'Dibatalkan oleh Pengguna';
        break;
      case 'cancelled_by_provider':
        statusColor = Colors.red;
        statusText = 'Dibatalkan oleh Penyedia';
        break;
      case 'rejected_by_provider':
        statusColor = Colors.red;
        statusText = 'Ditolak oleh Penyedia';
        break;
      case 'cancelled': // Status lama untuk kompatibilitas
        statusColor = Colors.red;
        statusText = 'Dibatalkan';
        break;
      case 'rejected': // Status lama untuk kompatibilitas
        statusColor = Colors.red;
        statusText = 'Ditolak';
        break;
      default:
        statusColor = Colors.grey;
        statusText = order['order_status'] ?? 'Tidak Diketahui';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.home_repair_service,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['services']?['title'] ?? 'Layanan',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order['profiles']?['full_name'] ?? 'Penyedia Jasa',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      order['order_date'] != null
                          ? DateTime.parse(
                              order['order_date'],
                            ).toLocal().toString().substring(0, 10)
                          : '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      'Rp ${order['total_price'] != null ? order['total_price'].toString() : '0'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tampilkan alasan pembatalan jika pesanan dibatalkan
            if (order['order_status'] == 'cancelled_by_user' ||
                order['order_status'] == 'cancelled_by_provider' ||
                order['order_status'] == 'rejected_by_provider' ||
                order['order_status'] == 'cancelled' ||
                order['order_status'] == 'rejected') ...[
              const Divider(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alasan Pembatalan:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['cancellation_reason'] ??
                        'Tidak ada alasan yang diberikan',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Tampilkan tanggal selesai jika pesanan sudah selesai
            if (order['order_status'] == 'completed_by_provider' ||
                order['order_status'] == 'completed_by_provider') ...[
              const Divider(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal Selesai:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['completion_date'] != null
                        ? DateTime.parse(
                            order['completion_date'],
                          ).toLocal().toString().substring(0, 10)
                        : 'Belum ada tanggal penyelesaian',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Tombol aksi berdasarkan status pesanan
            _buildOrderActions(order, statusText, context),
          ],
        ),
      ),
    );
  }

  // Helper untuk menampilkan item detail pesanan
  Widget _buildOrderDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Helper untuk menampilkan tombol aksi berdasarkan status pesanan
  Widget _buildOrderActions(
    Map<String, dynamic> order,
    String statusText,
    BuildContext context,
  ) {
    // Tentukan apakah pesanan masih aktif (untuk menampilkan tombol yang sesuai)
    final bool isActiveOrder =
        order['order_status'] == 'pending_confirmation' ||
        order['order_status'] == 'accepted_by_provider' ||
        order['order_status'] == 'in_progress';

    // Tentukan apakah pesanan masih bisa dibatalkan (hanya status pending_confirmation)
    final bool canBeCancelled = order['order_status'] == 'pending_confirmation';

    // Tentukan apakah pesanan sudah selesai atau dibatalkan
    final bool isCompletedOrder =
        order['order_status'] == 'completed_by_provider' ||
        order['order_status'] == 'completed_by_provider';
    final bool isCancelledOrder =
        order['order_status'] == 'cancelled_by_user' ||
        order['order_status'] == 'cancelled_by_provider' ||
        order['order_status'] == 'rejected_by_provider' ||
        order['order_status'] == 'cancelled' ||
        order['order_status'] == 'rejected';

    return Row(
      children: [
        // Tombol Detail (selalu ditampilkan)
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Tampilkan detail pesanan
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  maxChildSize: 0.9,
                  minChildSize: 0.5,
                  expand: false,
                  builder: (context, scrollController) => SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Detail Pesanan',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildOrderDetailItem(
                            'ID Pesanan',
                            order['id'].toString(),
                          ),
                          _buildOrderDetailItem(
                            'Layanan',
                            order['services']?['title'] ?? 'Layanan',
                          ),
                          _buildOrderDetailItem(
                            'Penyedia',
                            order['profiles']?['full_name'] ?? 'Penyedia Jasa',
                          ),
                          _buildOrderDetailItem(
                            'Tanggal',
                            order['order_date'] != null
                                ? DateTime.parse(
                                    order['order_date'],
                                  ).toLocal().toString().substring(0, 10)
                                : '-',
                          ),
                          _buildOrderDetailItem('Status', statusText),
                          _buildOrderDetailItem(
                            'Total',
                            'Rp ${order['total_price'] != null ? order['total_price'].toString() : '0'}',
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Detail', style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),

        // Tombol kedua - bisa Batalkan, Review, atau Hubungi tergantung status
        // Tombol kedua dan ketiga (Batalkan dan Hubungi) untuk pesanan aktif
        isActiveOrder
            ? Expanded(
                flex: 2,
                child: Row(
                  children: [
                    // Tombol Batalkan hanya untuk pesanan dengan status pending_confirmation
                    canBeCancelled
                        ? Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Tampilkan dialog konfirmasi pembatalan
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) {
                                    // Controller untuk input alasan pembatalan
                                    final TextEditingController
                                    reasonController = TextEditingController();
                                    String? errorText;

                                    return StatefulBuilder(
                                      builder: (context, setDialogState) => AlertDialog(
                                        title: const Text('Batalkan Pesanan'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Apakah Anda yakin ingin membatalkan pesanan ini?',
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Alasan Pembatalan (Wajib):',
                                            ),
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: reasonController,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Masukkan alasan pembatalan',
                                                errorText: errorText,
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                              maxLines: 3,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Tidak'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              // Validasi alasan pembatalan
                                              if (reasonController.text
                                                  .trim()
                                                  .isEmpty) {
                                                setDialogState(() {
                                                  errorText =
                                                      'Alasan pembatalan wajib diisi';
                                                });
                                                return;
                                              }

                                              // Simpan referensi ScaffoldMessenger sebelum pop dialog
                                              // untuk menghindari error deactivated widget
                                              final scaffoldMessenger =
                                                  ScaffoldMessenger.of(context);

                                              // Implementasi pembatalan pesanan
                                              Navigator.pop(context);

                                              // Tampilkan loading
                                              setState(() {
                                                _isLoading = true;
                                              });

                                              try {
                                                // Panggil API untuk membatalkan pesanan dengan status baru yang sesuai enum
                                                final result = await _orderRepository
                                                    .updateOrderStatus(
                                                      orderId: order['id'],
                                                      status:
                                                          'cancelled_by_user',
                                                      // Gunakan notes untuk menyimpan alasan pembatalan
                                                      notes: reasonController
                                                          .text
                                                          .trim(),
                                                    );

                                                result.fold(
                                                  (failure) {
                                                    // Error
                                                    scaffoldMessenger.showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Gagal membatalkan pesanan: ${failure.message}',
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  },
                                                  (_) {
                                                    // Sukses
                                                    scaffoldMessenger.showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Pesanan berhasil dibatalkan',
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                  },
                                                );
                                              } catch (e) {
                                                // Tangani exception yang tidak tertangkap
                                                scaffoldMessenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Terjadi kesalahan: ${e.toString()}',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              } finally {
                                                // Pastikan widget masih terpasang sebelum update state
                                                if (mounted) {
                                                  // Matikan loading
                                                  setState(() {
                                                    _isLoading = false;
                                                  });

                                                  // Reload pesanan
                                                  _refreshOrders();
                                                }
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Ya, Batalkan'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                foregroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Batalkan',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                        : const SizedBox(),
                    canBeCancelled
                        ? const SizedBox(width: 12)
                        : const SizedBox(),
                    // Tombol Hubungi untuk pesanan aktif
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Hubungi penyedia layanan - navigasi ke halaman chat
                          // Gunakan query parameter userId sesuai perubahan di GoRouter
                          context.pushNamed(
                            'userChatDetail',
                            pathParameters: {
                              'otherUserId':
                                  order['provider_id'] ??
                                  '00000000-0000-0000-0000-000000000000',
                            },
                            extra: {
                              'providerName':
                                  order['profiles']?['full_name'] ??
                                  'Penyedia Jasa',
                              'avatarUrl': order['profiles']?['avatar_url'],
                              'orderData': {
                                'order_id': order['id'],
                                'service_id':
                                    order['service_id'] ??
                                    order['id'].toString(),
                                'service_name':
                                    order['services']?['title'] ?? 'Layanan',
                                'provider_name':
                                    order['profiles']?['full_name'] ??
                                    'Penyedia Jasa',
                                'provider_id': order['provider_id'],
                                'status': order['status'],
                                'created_at': order['created_at'],
                                'price': order['total_price'],
                                'type':
                                    'service_info', // Menandai ini sebagai info layanan agar muncul sebagai balon
                              },
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Hubungi',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : isCompletedOrder
            ? Expanded(
                child: _buildReviewButton(order, context),
              ) // Menampilkan tombol Review pada tab Selesai
            : isCancelledOrder
            ? const SizedBox() // Tidak menampilkan tombol pada tab Dibatalkan
            : Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Hubungi penyedia layanan - navigasi ke halaman chat
                    // Gunakan query parameter userId sesuai perubahan di GoRouter
                    context.pushNamed(
                      'userChatDetail',
                      pathParameters: {
                        'otherUserId':
                            order['provider_id'] ??
                            '00000000-0000-0000-0000-000000000000',
                      },
                      extra: {
                        'providerName':
                            order['profiles']?['full_name'] ?? 'Penyedia Jasa',
                        'avatarUrl': order['profiles']?['avatar_url'],
                        'orderData': {
                          'order_id': order['id'],
                          'service_id':
                              order['service_id'] ?? order['id'].toString(),
                          'service_name':
                              order['services']?['title'] ?? 'Layanan',
                          'provider_name':
                              order['profiles']?['full_name'] ??
                              'Penyedia Jasa',
                          'provider_id': order['provider_id'],
                          'status': order['status'],
                          'created_at': order['created_at'],
                          'price': order['total_price'],
                          'type':
                              'service_info', // Menandai ini sebagai info layanan agar muncul sebagai balon
                        },
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Hubungi', style: TextStyle(fontSize: 13)),
                ),
              ),
      ],
    );
  }

  // Helper untuk menampilkan tombol Review
  Widget _buildReviewButton(Map<String, dynamic> order, BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkIfReviewExists(order['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bool hasReview = snapshot.data ?? false;

        if (hasReview) {
          return OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              disabledForegroundColor: Colors.grey,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Sudah Direview', style: TextStyle(fontSize: 13)),
          );
        }

        return ElevatedButton(
          onPressed: () => _showReviewDialog(order, context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Beri Review', style: TextStyle(fontSize: 13)),
        );
      },
    );
  }

  // Memeriksa apakah review sudah ada untuk pesanan tertentu
  Future<bool> _checkIfReviewExists(int orderId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      logger.e('Error checking review: $e');
      return false;
    }
  }

  // Menampilkan dialog review
  void _showReviewDialog(Map<String, dynamic> order, BuildContext context) {
    double rating = 5;
    final commentController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Beri Review'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informasi layanan
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.home_repair_service,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['services']?['title'] ?? 'Layanan',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order['profiles']?['full_name'] ??
                                  'Penyedia Jasa',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Rating
                  const Text(
                    'Rating',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: RatingBar(
                      initialRating: rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemSize: 36,
                      ratingWidget: RatingWidget(
                        full: Icon(Icons.star, color: Colors.red),
                        half: Icon(Icons.star_half, color: Colors.red),
                        empty: Icon(Icons.star, color: Colors.grey),
                      ),
                      // Menambahkan animasi pada bintang
                      updateOnDrag: true,
                      glow: true,
                      glowColor: Colors.red,
                      glowRadius: 2,
                      onRatingUpdate: (newRating) {
                        setDialogState(() {
                          rating = newRating;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Komentar
                  const Text(
                    'Beri Komentar Di sini',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Bagikan pengalaman Anda...',
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Simpan referensi ScaffoldMessenger sebelum pop dialog
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);

                  // Tampilkan loading
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // Dapatkan user saat ini
                    final currentUserResult = await _getCurrentUserUsecase(
                      const NoParams(),
                    );
                    await currentUserResult.fold(
                      (failure) {
                        throw Exception(
                          'Gagal mendapatkan user: ${failure.message}',
                        );
                      },
                      (user) async {
                        if (user == null) {
                          throw Exception('User tidak ditemukan');
                        }

                        // Simpan review ke Supabase
                        await _supabase.from('reviews').insert({
                          'order_id': order['id'],
                          'user_id': user.id,
                          'service_id': order['service_id'],
                          'provider_id': order['provider_id'],
                          'rating': rating.toInt(),
                          'comment': commentController.text.trim(),
                          'review_date': DateTime.now().toIso8601String(),
                        });

                        // Sukses
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Review berhasil disimpan'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    );
                  } catch (e) {
                    // Tangani exception
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Terjadi kesalahan: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    // Pastikan widget masih terpasang sebelum update state
                    if (mounted) {
                      // Matikan loading
                      setState(() {
                        _isLoading = false;
                      });

                      // Reload pesanan
                      _refreshOrders();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kirim Review'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Alias untuk OrdersScreen untuk kompatibilitas dengan kode lama
typedef PesananScreen = OrdersScreen;
