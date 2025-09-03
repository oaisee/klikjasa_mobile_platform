import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/user_entity.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_bloc.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_event.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_state.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/data/datasources/provider_order_remote_data_source.dart';
import 'package:klik_jasa/core/network/network_info.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/injection_container.dart' as di;

/// A widget that displays a notification bell icon for service providers.
/// 
/// This widget shows a notification bell icon and displays a badge
/// indicating the number of unread notifications for the provider.
class NotificationBellWidget extends StatefulWidget {
  const NotificationBellWidget({super.key});

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget> {
  late NotificationBloc _notificationBloc;
  late ProviderOrderRemoteDataSource _orderDataSource;
  UserEntity? _currentUser;
  Timer? _pollingTimer;
  int _pendingOrdersCount = 0;
  bool _isLoadingOrders = false;
  int _errorCount = 0; // Menghitung jumlah error berturut-turut

  @override
  void initState() {
    super.initState();
    _notificationBloc = di.sl<NotificationBloc>();
    _orderDataSource = di.sl<ProviderOrderRemoteDataSource>();
    _getCurrentUser();
    _fetchPendingOrdersCount();
    _setupPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
  
  void _getCurrentUser() {
    final authState = BlocProvider.of<AuthBloc>(context).state;
    if (authState is AuthAuthenticated) {
      _currentUser = authState.user;
      if (_currentUser != null) {
        _notificationBloc.add(GetNotificationsEvent(userId: _currentUser!.id, page: 1, limit: 10));
      }
    }
  }

  /// Mengambil jumlah pesanan yang tertunda
  Future<void> _fetchPendingOrdersCount() async {
    if (!mounted) return;
    
    // Jangan melakukan fetch jika sedang loading
    if (_isLoadingOrders) return;

    setState(() {
      _isLoadingOrders = true;
    });

    try {
      final String? providerId = Supabase.instance.client.auth.currentUser?.id;
      if (providerId == null) {
        setState(() {
          _isLoadingOrders = false;
          _pendingOrdersCount = 0;
        });
        return;
      }
      
      // Periksa koneksi internet terlebih dahulu
      final NetworkInfo networkInfo = di.sl<NetworkInfo>();
      final bool isConnected = await networkInfo.isConnected;
      
      if (!isConnected) {
        if (mounted) {
          setState(() {
            _isLoadingOrders = false;
          });
        }
        debugPrint('Tidak ada koneksi internet saat mengambil jumlah pesanan');
        return;
      }
      
      // Tambahkan timeout untuk menghindari blocking terlalu lama
      final pendingOrders = await _orderDataSource.getPendingOrdersCount(providerId)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException(message: 'Waktu permintaan habis. Silakan coba lagi nanti.');
      });
      
      // Reset error counter jika berhasil
      _errorCount = 0;
      
      if (mounted) {
        setState(() {
          _pendingOrdersCount = pendingOrders;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
      }
      
      String errorMessage = 'Gagal mengambil jumlah pesanan';
      
      if (e is TimeoutException) {
        errorMessage = e.message;
        debugPrint('Timeout error: ${e.message}');
      } else if (e is ServerException) {
        errorMessage = e.message;
        debugPrint('Server error: ${e.message}, code: ${e.code}');
      } else {
        debugPrint('Error fetching pending orders count: $e');
      }
      
      // Tampilkan snackbar jika error terjadi berulang kali
      if (_errorCount > 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _errorCount = 0;
      } else {
        _errorCount++;
      }
    }
  }

  /// Menyiapkan polling untuk pesanan setiap 30 detik
  void _setupPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Periksa koneksi internet terlebih dahulu
      try {
        final NetworkInfo networkInfo = di.sl<NetworkInfo>();
        final bool isConnected = await networkInfo.isConnected;

        if (!isConnected) {
          debugPrint('Tidak ada koneksi internet saat polling');
          return; // Lewati polling ini, tapi jangan batalkan timer
        }

        _fetchPendingOrdersCount();
      } catch (e) {
        debugPrint('Error saat polling: $e');
        // Jangan batalkan timer, biarkan mencoba lagi pada interval berikutnya
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _notificationBloc,
      child: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          int unreadCount = 0;
          bool isLoading = false;
          if (state is NotificationsLoaded) {
            unreadCount = state.unreadCount;
          } else if (state is NotificationLoading && state.notifications.isNotEmpty) {
            // Show previous count while loading
            unreadCount = state.notifications.where((n) => !n.isRead).length;
          } else if (state is NotificationLoading) {
            isLoading = true;
          }
          
          // Total notifikasi = notifikasi yang belum dibaca + pesanan yang belum dikonfirmasi
          final totalCount = unreadCount + _pendingOrdersCount;
          
          return InkWell(
            onTap: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                context.goNamed('providerNotifications');
              } else {
                // Handle guest user case, e.g., show login screen
                context.goNamed('login');
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  if (isLoading || _isLoadingOrders)
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  else if (totalCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          totalCount > 9 ? '9+' : totalCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}