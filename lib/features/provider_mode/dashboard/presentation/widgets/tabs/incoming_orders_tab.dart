import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/presentation/bloc/incoming_orders/incoming_orders_bloc.dart';
import 'package:klik_jasa/features/common/chat/presentation/pages/chat_detail_screen.dart';
import 'package:klik_jasa/features/common/chat/presentation/pages/chat_screen.dart';
import 'package:klik_jasa/features/common/chat/presentation/bloc/chat_bloc.dart';
import 'package:klik_jasa/injection_container.dart' as di;

/// A tab that displays incoming orders for service providers.
/// 
/// This tab shows a list of orders that are pending confirmation from the provider.
class IncomingOrdersTab extends StatefulWidget {
  const IncomingOrdersTab({super.key});

  @override
  State<IncomingOrdersTab> createState() => _IncomingOrdersTabState();
}

class _IncomingOrdersTabState extends State<IncomingOrdersTab> {
  @override
  void initState() {
    super.initState();
    // IncomingOrdersBloc is now provided by the parent widget (ProviderDashboardScreen)
    // and FetchIncomingOrders event is already triggered there
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String? currentProviderId;
    if (authState is AuthAuthenticated) {
      currentProviderId = authState.user.id;
    }

    return BlocListener<IncomingOrdersBloc, IncomingOrdersState>(
      listener: (context, state) {
          if (state is IncomingOrderAcceptSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pesanan ID: ${state.order.id} berhasil diterima.'), backgroundColor: Colors.green),
            );
          } else if (state is IncomingOrderAcceptFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menerima pesanan ID: ${state.orderId}. Error: ${state.message}'), backgroundColor: Colors.red),
            );
          } else if (state is IncomingOrderDeclineSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pesanan ID: ${state.order.id} berhasil ditolak.'), backgroundColor: Colors.orange),
            );
          } else if (state is IncomingOrderDeclineFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menolak pesanan ID: ${state.orderId}. Error: ${state.message}'), backgroundColor: Colors.red),
            );
          }
      },
      child: BlocBuilder<IncomingOrdersBloc, IncomingOrdersState>(
        builder: (context, state) {
            if (state is IncomingOrdersLoading && !(state is IncomingOrderAcceptLoading || state is IncomingOrderDeclineLoading)) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is IncomingOrdersLoaded) {
              if (state.orders.isEmpty) {
                return const Center(child: Text('Tidak ada pesanan masuk saat ini.'));
              }
              return _buildOrdersList(context, state.orders, currentProviderId);
            } else if (state is IncomingOrdersError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            // Handle specific action loading states so the main UI doesn't change to global loading
            final currentState = context.read<IncomingOrdersBloc>().state;
            if (currentState is IncomingOrdersLoaded) {
               return _buildOrdersList(context, currentState.orders, currentProviderId);
            }
            return const Center(child: Text('Memuat pesanan...'));
        },
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<Order> orders, String? providerId) {
    return RefreshIndicator(
      onRefresh: () async {
        if (providerId != null) {
          context.read<IncomingOrdersBloc>().add(FetchIncomingOrders(providerId: providerId));
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.serviceTitle ?? 'Service not available',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.person_outline, 'Customer: ${order.userName ?? 'N/A'}'),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.calendar_today_outlined, 'Order Date: ${DateFormat('d MMM yyyy, HH:mm').format(order.orderDate)}'),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.monetization_on_outlined, 'Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.totalPrice).replaceAll(',', '.')}'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showDeclineDialog(context, order, providerId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigasi ke halaman chat dengan customer
                            // Gunakan BlocProvider untuk ChatBloc agar konsisten dengan navigasi lainnya
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BlocProvider<ChatBloc>(
                                  create: (context) => di.sl<ChatBloc>(),
                                  child: ChatDetailScreen(
                                    otherUserId: order.userId,
                                    otherUserName: order.userName ?? 'Customer',
                                    userType: UserType.provider,
                                    // Ambil avatar_url dari userDetails jika ada
                                    profilePicture: order.userDetails != null ? 
                                      order.userDetails!['avatar_url'] as String? : null,
                                  ),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Hubungi'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showAcceptDialog(context, order, providerId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Terima'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }

  void _showAcceptDialog(BuildContext context, Order order, String? providerId) {
    final TextEditingController notesController = TextEditingController();
    // Simpan referensi bloc sebelum membuka dialog
    final incomingOrdersBloc = context.read<IncomingOrdersBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Terima Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menerima pesanan ini?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (providerId != null) {
                // Gunakan referensi bloc yang sudah disimpan
                incomingOrdersBloc.add(
                  AcceptIncomingOrder(
                    orderId: order.id.toString(),
                    providerId: providerId,
                    notes: notesController.text,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            child: const Text('Terima'),
          ),
        ],
      ),
    );
  }

  void _showDeclineDialog(BuildContext context, Order order, String? providerId) {
    final TextEditingController reasonController = TextEditingController();
    // Simpan referensi bloc sebelum membuka dialog
    final incomingOrdersBloc = context.read<IncomingOrdersBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menolak pesanan ini?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan (wajib)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Mohon berikan alasan penolakan')),
                );
                return;
              }
              Navigator.of(dialogContext).pop();
              if (providerId != null) {
                // Gunakan referensi bloc yang sudah disimpan
                incomingOrdersBloc.add(
                  DeclineIncomingOrder(
                    orderId: order.id.toString(),
                    providerId: providerId,
                    reason: reasonController.text,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }
}