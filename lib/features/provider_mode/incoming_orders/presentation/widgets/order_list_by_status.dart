import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/presentation/bloc/provider_orders/provider_orders_bloc.dart';

class OrderListByStatus extends StatelessWidget {
  final String status;
  final List<Order> orders;

  const OrderListByStatus({
    super.key,
    required this.status,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada pesanan dengan status "${_getStatusLabel(status)}".',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    // Gunakan LayoutBuilder untuk mendapatkan constraints dari parent
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final formattedDate =
                  DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(order.createdAt);
              final formattedPrice = NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(order.totalPrice).replaceAll(',', '.');

              // Cek apakah pesanan ini sedang diperbarui
              final isUpdating = context.watch<ProviderOrdersBloc>().state is ProviderOrdersUpdating &&
                  (context.watch<ProviderOrdersBloc>().state as ProviderOrdersUpdating).orderId == order.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 1,
                shadowColor: AppColors.shadowLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.serviceTitle ?? 'Tanpa Judul',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                _buildStatusChip(context, status),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              formattedPrice,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.info,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 18, color: AppColors.info),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    order.userName ?? 'Tanpa Nama',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.warning),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    formattedDate,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (order.userNotes != null && order.userNotes!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catatan Pelanggan:',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.userNotes ?? '',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // Navigasi ke halaman chat dengan provider
                              final authState = context.read<AuthBloc>().state;
                              final userId = authState is AuthAuthenticated ? authState.user.id : null;
                              if (userId != null) {
                                context.push(
                                  '/provider-chat/detail?userId=${order.userId}',
                                  extra: {
                                    'otherUserName': order.userName ?? 'Pelanggan',
                                    'orderId': order.id,
                                    'serviceTitle': order.serviceTitle ?? 'Layanan',
                                  },
                                );
                              }
                            },
                            icon: const Icon(Icons.chat_outlined, size: 16),
                            label: const Text('Chat'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(0, 36),
                              textStyle: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          if (isUpdating)
                            Container(
                              width: 36,
                              height: 36,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                            )
                          else
                            _buildActionButton(context, order.id, status),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusLabel = _getStatusLabel(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  // Menampilkan dialog detail pesanan
  void _showOrderDetailsDialog(BuildContext context, int orderId) {
    // Cari pesanan berdasarkan ID
    final state = context.read<ProviderOrdersBloc>().state;
    
    if (state is! ProviderOrdersLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pesanan belum dimuat')),
      );
      return;
    }
    
    // Gabungkan semua pesanan dari berbagai status
    final allOrdersList = state.allOrders.values.expand((orders) => orders).toList();
    
    final order = allOrdersList.firstWhere(
      (order) => order.id == orderId,
      orElse: () => Order(
        id: 0,
        userId: '',
        serviceId: 0,
        providerId: '',
        orderStatus: OrderStatus.pendingConfirmation,
        quantity: 0,
        totalPrice: 0,
        feeAmount: 0,
        orderDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    if (order.id == 0) {
      // Pesanan tidak ditemukan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detail pesanan tidak ditemukan')),
      );
      return;
    }
    
    // Format tanggal dan harga
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(order.createdAt);
    final formattedPrice = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(order.totalPrice).replaceAll(',', '.');
    
    // Tampilkan dialog dengan detail pesanan
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Pesanan #${order.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Layanan', order.serviceTitle ?? 'Tanpa Judul'),
              _buildDetailItem('Pelanggan', order.userName ?? 'Tanpa Nama'),
              _buildDetailItem('Status', _getStatusLabel(orderStatusToString(order.orderStatus))),
              _buildDetailItem('Tanggal Pesan', formattedDate),
              _buildDetailItem('Jumlah', '${order.quantity}'),
              _buildDetailItem('Total Harga', formattedPrice),
              if (order.userNotes != null && order.userNotes!.isNotEmpty)
                _buildDetailItem('Catatan Pelanggan', order.userNotes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigasi ke halaman chat dengan pelanggan
              final authState = context.read<AuthBloc>().state;
              final userId = authState is AuthAuthenticated ? authState.user.id : null;
              if (userId != null) {
                context.push(
                  '/provider-chat/detail?userId=${order.userId}',
                  extra: {
                    'otherUserName': order.userName ?? 'Pelanggan',
                    'orderId': order.id,
                    'serviceTitle': order.serviceTitle ?? 'Layanan',
                  },
                );
              }
            },
            child: const Text('Chat Pelanggan'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
  
  // Helper untuk membangun item detail pesanan
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, int orderId, String currentStatus) {
    final authState = context.read<AuthBloc>().state;
    final providerId = authState is AuthAuthenticated ? authState.user.id : '';
    
    switch (currentStatus) {
      case 'pending_confirmation':
        return Row(
          children: [
            ElevatedButton(
              onPressed: () {
                // Terima pesanan
                context.read<ProviderOrdersBloc>().add(
                      UpdateOrderStatus(
                        orderId: orderId,
                        newStatus: orderStatusToString(OrderStatus.confirmed),
                        providerId: providerId,
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 36),
                elevation: 0,
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Terima'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                // Tolak pesanan
                context.read<ProviderOrdersBloc>().add(
                      UpdateOrderStatus(
                        orderId: orderId,
                        newStatus: orderStatusToString(OrderStatus.rejected),
                        providerId: providerId,
                      ),
                    );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
              ),
              child: const Text('Tolak'),
            ),
          ],
        );
      case 'confirmed':
      case 'accepted_by_provider':
        return Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Mulai pengerjaan
                context.read<ProviderOrdersBloc>().add(
                      UpdateOrderStatus(
                        orderId: orderId,
                        newStatus: orderStatusToString(OrderStatus.inProgress),
                        providerId: providerId,
                      ),
                    );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('Mulai Pengerjaan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 36),
                elevation: 0,
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                // Tampilkan dialog detail pesanan
                _showOrderDetailsDialog(context, orderId);
              },
              icon: const Icon(Icons.info_outline, size: 20),
              tooltip: 'Detail Pesanan',
              style: IconButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
              ),
            ),
          ],
        );
      case 'in_progress':
        return ElevatedButton.icon(
          onPressed: () {
            // Selesaikan pesanan
            context.read<ProviderOrdersBloc>().add(
                  UpdateOrderStatus(
                    orderId: orderId,
                    newStatus: orderStatusToString(OrderStatus.completed),
                    providerId: providerId,
                  ),
                );
          },
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Selesaikan Pesanan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 36),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        );
      case 'completed':
      case 'completed_by_provider':
        return TextButton.icon(
          onPressed: () {
            // Tampilkan dialog detail pesanan
            _showOrderDetailsDialog(context, orderId);
          },
          icon: const Icon(Icons.info_outline, size: 16),
          label: const Text('Lihat Detail'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.info,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 36),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        );
      case 'cancelled':
      case 'rejected':
        return OutlinedButton(
          onPressed: null, // Disabled button
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(currentStatus == 'cancelled' ? 'Dibatalkan' : 'Ditolak'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Helper untuk mendapatkan label yang lebih user-friendly dari status
  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending_confirmation':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
      case 'accepted_by_provider':
        return 'Dikonfirmasi';
      case 'in_progress':
        return 'Dalam Pengerjaan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  // Helper untuk mendapatkan warna sesuai status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_confirmation':
        return AppColors.warning;
      case 'confirmed':
      case 'accepted_by_provider':
        return AppColors.info;
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  // Helper untuk mendapatkan ikon sesuai status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending_confirmation':
        return Icons.hourglass_empty;
      case 'confirmed':
      case 'accepted_by_provider':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.engineering;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
