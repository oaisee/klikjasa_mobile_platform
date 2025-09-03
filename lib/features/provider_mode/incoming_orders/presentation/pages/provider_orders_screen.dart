import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/profile/presentation/pages/top_up_screen.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/presentation/bloc/provider_orders/provider_orders_bloc.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/presentation/widgets/order_list_by_status.dart';
import 'package:klik_jasa/injection_container.dart';
import 'provider_orders_realtime_handler.dart';

class ProviderOrdersScreen extends StatelessWidget {
  const ProviderOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          return BlocProvider(
            create: (context) => sl<ProviderOrdersBloc>()
              ..add(FetchAllProviderOrders(providerId: authState.user.id)),
            child: ProviderOrdersView(providerId: authState.user.id),
          );
        } else {
          return const Scaffold(
            body: Center(
              child: Text('Silakan login untuk melihat pesanan.'),
            ),
          );
        }
      },
    );
  }
}

class ProviderOrdersView extends StatefulWidget {
  final String providerId;
  
  const ProviderOrdersView({super.key, required this.providerId});

  @override
  State<ProviderOrdersView> createState() => _ProviderOrdersViewState();
}


class _ProviderOrdersViewState extends State<ProviderOrdersView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProviderOrdersRealtimeHandler? _realtimeHandler;
  final Map<String, Map<String, dynamic>> _tabs = {
    'pending_confirmation': {
      'label': 'Baru',
      'icon': Icons.hourglass_empty,
      'color': AppColors.warning,
    },
    'accepted_by_provider': {
      'label': 'Dikonfirmasi',
      'icon': Icons.thumb_up_outlined,
      'color': AppColors.info,
    },
    'in_progress': {
      'label': 'Dikerjakan',
      'icon': Icons.engineering,
      'color': AppColors.primary,
    },
    'completed': {
      'label': 'Selesai',
      'icon': Icons.check_circle_outline,
      'color': AppColors.success,
    },
    'cancelled': {
      'label': 'Dibatalkan',
      'icon': Icons.cancel_outlined,
      'color': AppColors.error,
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Baca query parameter untuk menentukan tab aktif
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queryParams = GoRouterState.of(context).uri.queryParameters;
      final tabParam = queryParams['tab'];
      
      if (tabParam != null) {
        int? targetIndex;
        
        // Map parameter tab ke index yang sesuai
        switch (tabParam) {
          case 'baru':
            targetIndex = _tabs.keys.toList().indexOf('pending_confirmation');
            break;
          case 'dikonfirmasi':
            targetIndex = _tabs.keys.toList().indexOf('accepted_by_provider');
            break;
          case 'dikerjakan':
            targetIndex = _tabs.keys.toList().indexOf('in_progress');
            break;
          case 'completed':
          case 'selesai':
            targetIndex = _tabs.keys.toList().indexOf('completed');
            break;
          case 'dibatalkan':
            targetIndex = _tabs.keys.toList().indexOf('cancelled');
            break;
        }
        
        if (targetIndex != null && targetIndex >= 0 && targetIndex < _tabs.length) {
          _tabController.animateTo(targetIndex);
        }
      }
    });
    
    // Inisialisasi subscription realtime
    _realtimeHandler = ProviderOrdersRealtimeHandler(
      context: context,
      providerId: widget.providerId,
    );
    _realtimeHandler!.start();
  }

  @override
  void dispose() {
    _realtimeHandler?.stop();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pesanan'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProviderOrdersBloc>().add(
                    FetchAllProviderOrders(providerId: widget.providerId),
                  );
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorColor: Colors.white,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          tabs: _tabs.entries.map((entry) {
            final tabInfo = entry.value;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tabInfo['icon'] as IconData, size: 18),
                  const SizedBox(width: 8),
                  Text(tabInfo['label'] as String),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: BlocConsumer<ProviderOrdersBloc, ProviderOrdersState>(
        listener: (context, state) {
          if (state is ProviderOrdersError) {
            // Cek apakah error terkait saldo tidak cukup
            if (state.message.startsWith('INSUFFICIENT_BALANCE:')) {
              // Ekstrak pesan error asli (tanpa prefix)
              final originalMessage = state.message.replaceFirst('INSUFFICIENT_BALANCE:', '');
              
              // Ekstrak nilai minimal saldo yang diperlukan dari pesan error
              final RegExp regExp = RegExp(r'Rp\s*(\d+(?:[.,]\d+)?)\b');
              final match = regExp.firstMatch(originalMessage);
              final String minimalSaldo = match != null ? match.group(1) ?? '50.000' : '50.000';
              
              // Tampilkan dialog khusus untuk error saldo tidak cukup
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.red),
                      const SizedBox(width: 10),
                      const Text('Saldo Tidak Cukup'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Anda tidak mencukupi untuk melakukan transaksi ini. '
                        'Silakan lakukan top up saldo terlebih dahulu.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Informasi Saldo:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Minimal Saldo yang Diperlukan: Rp $minimalSaldo',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigasi ke halaman top up saldo
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => const TopUpScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Top Up Sekarang'),
                    ),
                  ],
                ),
              );
            } else {
              // Tampilkan snackbar untuk error lainnya
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Coba Lagi',
                    onPressed: () {
                      context.read<ProviderOrdersBloc>().add(
                            FetchAllProviderOrders(providerId: widget.providerId),
                          );
                    },
                  ),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is ProviderOrdersLoading || state is ProviderOrdersInitial) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Memuat pesanan...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (state is ProviderOrdersError) {
            // Cek apakah error terkait saldo tidak cukup
            if (state.message.startsWith('INSUFFICIENT_BALANCE:')) {
              // Ekstrak pesan error asli (tanpa prefix)
              final originalMessage = state.message.replaceFirst('INSUFFICIENT_BALANCE:', '');
              
              // Tampilkan pesan error khusus untuk saldo tidak cukup
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.orange,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Saldo Tidak Mencukupi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Anda memerlukan saldo yang cukup untuk mengkonfirmasi pesanan.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Detail: $originalMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => const TopUpScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Top-Up Saldo'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          context.read<ProviderOrdersBloc>().add(
                                FetchAllProviderOrders(
                                  providerId: widget.providerId,
                                ),
                              );
                        },
                        child: const Text('Refresh Data'),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Tampilkan pesan error umum dengan tombol refresh
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Gagal memuat pesanan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<ProviderOrdersBloc>().add(
                              FetchAllProviderOrders(providerId: widget.providerId),
                            );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is ProviderOrdersLoaded || state is ProviderOrdersUpdating) {
            // Ambil allOrders dari state yang sesuai
            final allOrders = state is ProviderOrdersLoaded
                ? state.allOrders
                : (state as ProviderOrdersUpdating).allOrders;
                
            // Kelompokkan pesanan berdasarkan kategori status
            final Map<String, List<Order>> groupedOrders = {
              'pending_confirmation': [],
              'accepted_by_provider': [],
              'in_progress': [],
              'completed': [],
              'cancelled': [],
            };
            
            // Jumlah status dalam allOrders
            // Keys dalam allOrders
            
            // Kelompokkan pesanan berdasarkan kategori status
            allOrders.forEach((status, ordersList) {
              // Status dan jumlah pesanan
              
              if (status == 'pending_confirmation') {
                // Menambahkan pesanan ke tab Baru
                groupedOrders['pending_confirmation']!.addAll(ordersList);
              } else if (status == 'accepted_by_provider') {
                groupedOrders['accepted_by_provider']!.addAll(ordersList);
              } else if (status == 'in_progress') {
                groupedOrders['in_progress']!.addAll(ordersList);
              } else if (status == 'completed_by_provider') {
                groupedOrders['completed']!.addAll(ordersList);
              } else if (status == 'cancelled_by_user' || status == 'cancelled_by_provider' || 
                         status == 'rejected_by_provider' || status == 'cancelled' || status == 'rejected') {
                groupedOrders['cancelled']!.addAll(ordersList);
              }
            });
            
            // Log jumlah pesanan di setiap tab untuk debugging
            groupedOrders.forEach((key, value) {
              // Tab dan jumlah pesanan
            });
            
            return TabBarView(
              controller: _tabController,
              children: _tabs.keys.map((status) {
                final orders = groupedOrders[status] ?? [];
                return OrderListByStatus(status: status, orders: orders);
              }).toList(),
            );
          }
          return const Center(child: Text('Terjadi kesalahan.'));
        },
      ),
    );
  }
}
