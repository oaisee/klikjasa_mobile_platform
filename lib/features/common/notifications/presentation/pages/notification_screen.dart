import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/constants/app_strings.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart'
    as notification_entity;
import 'package:klik_jasa/features/common/notifications/domain/entities/notification_type.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_bloc.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_event.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_state.dart';
import 'package:klik_jasa/features/common/notifications/presentation/widgets/provider_notification_item.dart';
import 'package:klik_jasa/features/common/notifications/presentation/widgets/notification_item.dart';
import 'package:klik_jasa/injection_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  final String mode; // 'user' or 'provider'

  const NotificationScreen({
    super.key,
    required this.userId,
    required this.mode,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  late NotificationBloc _notificationBloc;

  late AnimationController _newNotificationAnimationController;
  late Animation<double> _newNotificationAnimation;

  final Set<int> _newNotificationIds = {};

  bool _isSelectionMode = false;
  final Set<int> _selectedNotificationIds = {};

  @override
  void initState() {
    super.initState();
    _notificationBloc = sl<NotificationBloc>();

    _newNotificationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _newNotificationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _newNotificationAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  void _initializeNotifications() {
    _notificationBloc.add(
      GetNotificationsEvent(userId: widget.userId, page: 1, limit: 10),
    );

    // Timer auto-read dihapus - notifikasi hanya ditandai dibaca saat user mengklik
  }

  // Fungsi auto-read dihapus - notifikasi hanya ditandai dibaca saat user mengklik notifikasi

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    _newNotificationAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final currentState = _notificationBloc.state;
      if (currentState is NotificationsLoaded &&
          !currentState.isLoadingMore &&
          !currentState.hasReachedMax) {
        _notificationBloc.add(
          GetNotificationsEvent(
            userId: widget.userId,
            page: currentState.currentPage + 1,
            limit: 10,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(notification_entity.Notification notification) {
    logger.i(
      'Notification tapped: id=${notification.id}, type=${notification.type}, isRead=${notification.isRead}',
    );

    // Tandai sebagai dibaca jika belum dibaca
    if (!notification.isRead) {
      _notificationBloc.add(MarkAsReadEvent(notificationId: notification.id));
    }

    // Navigasi berdasarkan mode
    if (widget.mode == 'provider') {
      _handleProviderNavigation(notification);
    } else {
      _handleUserNotification(notification);
    }
  }

  void _handleProviderNavigation(
    notification_entity.Notification notification,
  ) {
    final type = notification.type;
    final entityType = notification.relatedEntityType;
    final entityId = notification.relatedEntityId;

    logger.i(
      'Provider notification tapped: id=${notification.id}, type=$type, entityType=$entityType, entityId=$entityId',
    );

    // Berikan feedback haptic saat notifikasi ditap
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      logger.w('Haptic feedback error: $e');
    }

    bool navigationSuccessful = false;

    try {
      // Navigasi berdasarkan tipe notifikasi provider
      if (type.value == 'new_order' || type.value == 'order_created' || type.value == 'order') {
        // Navigasi ke halaman pesanan provider
        context.goNamed('providerOrders');
        navigationSuccessful = true;
      } else if (type.value == 'order_update' && entityId != null) {
        // Navigasi ke detail pesanan provider
        if (_isValidUUID(entityId)) {
          context.goNamed(
            'providerOrderDetails',
            pathParameters: {'orderId': entityId},
          );
          navigationSuccessful = true;
        } else {
          logger.w('Invalid order ID format: $entityId');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format ID pesanan tidak valid'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if ((type.value == 'chat_message' || type.value == 'chat') &&
          entityId != null) {
        // Navigasi ke halaman detail chat provider
        if (_isValidUUID(entityId)) {
          context.go('/provider-chat/detail?userId=$entityId');
          navigationSuccessful = true;
        } else {
          logger.w('Invalid user ID format: $entityId');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format ID pengguna tidak valid'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (type.value == 'rating_received') {
        // Navigasi ke halaman profil provider untuk melihat rating
        context.goNamed('providerProfile');
        navigationSuccessful = true;
      } else if (type.value == 'service_approved' || type.value == 'service_rejected') {
        // Navigasi ke halaman manajemen layanan provider
        context.goNamed('providerServiceManagement');
        navigationSuccessful = true;
      } else if (type.value == 'verification_success' ||
          type.value == 'verification_failed') {
        // Navigasi ke halaman status provider
        final providerStatus =
            type.value == 'verification_success' ? 'approved' : 'rejected';
        context.goNamed(
          'providerStatus',
          extra: {'providerStatus': providerStatus},
        );
        navigationSuccessful = true;
      } else if (type.value == 'balance') {
        // Navigasi ke halaman top-up saldo
        context.goNamed('topUp');
        navigationSuccessful = true;
      } else {
        logger.i(
          'Provider notification tapped with no specific navigation: type=$type, entityType=$entityType',
        );
        // Tampilkan pesan informatif untuk notifikasi yang tidak memiliki navigasi khusus
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notifikasi "${notification.title}" telah dibaca'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        navigationSuccessful =
            true; // Anggap berhasil untuk notifikasi tanpa navigasi
      }
    } catch (e) {
      logger.e('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka notifikasi: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Tandai notifikasi sebagai sudah dibaca hanya jika navigasi berhasil
    if (navigationSuccessful) {
      _notificationBloc.add(MarkAsReadEvent(notificationId: notification.id));
    }
  }

  void _handleUserNotification(
    notification_entity.Notification notification,
  ) async {
    final String? entityId = notification.relatedEntityId;
    final String type = notification.type.value;

    // Cek apakah ini notifikasi yang seharusnya untuk provider mode
    if (_isProviderNotification(notification.type)) {
      await _showModeSwithDialog(notification);
      return;
    }

    switch (type) {
      case 'order':
      case 'order_update':
        context.push('/orders-user');
        break;
      case 'chat':
        if (entityId != null && _isValidUUID(entityId)) {
          // Ambil data pengguna untuk chat detail
          try {
            final supabase = Supabase.instance.client;
            final response = await supabase
                .from('profiles')
                .select('full_name, avatar_url')
                .eq('id', entityId)
                .single();

            String otherUserName = response['full_name'] ?? 'Pengguna';
            String? profilePicture = response['avatar_url'];

            if (mounted) {
              context.goNamed(
                'userChatDetail',
                pathParameters: {'otherUserId': entityId},
                extra: {
                  'otherUserName': otherUserName,
                  'profilePicture': profilePicture,
                },
              );
            }
          } catch (e) {
            Logger().e('Error fetching user data: $e');
            // Fallback jika gagal mengambil data
            if (mounted) {
              context.goNamed(
                'userChatDetail',
                pathParameters: {'otherUserId': entityId},
                extra: {'otherUserName': 'Pengguna', 'profilePicture': null},
              );
            }
          }
        } else {
          logger.w('Invalid UUID for chat notification: $entityId');
          // Tampilkan pesan error atau abaikan notifikasi
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifikasi chat tidak valid'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        break;
      case 'balance':
        context.push('/top-up');
        break;
      default:
        logger.i('User notification tapped with no specific navigation: $type');
        break;
    }
  }

  // Helper method untuk validasi UUID
  bool _isValidUUID(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(uuid);
  }

  // Helper method untuk mengecek apakah notifikasi adalah untuk provider
  bool _isProviderNotification(NotificationType type) {
    return type.value == 'new_order' ||
        type.value == 'order_created' ||
        type.value == 'verification' ||
        type.value.startsWith('provider_');
  }

  // Dialog untuk konfirmasi beralih ke provider mode
  Future<void> _showModeSwithDialog(
    notification_entity.Notification notification,
  ) async {
    final bool? shouldSwitch = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Beralih ke Mode Provider'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifikasi ini khusus untuk mode penyedia jasa. Apakah Anda ingin beralih ke mode provider untuk melihat detail pesanan?',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Beralih ke Provider'),
            ),
          ],
        );
      },
    );

    if (shouldSwitch == true) {
      // Beralih ke provider mode dan navigasi ke halaman yang sesuai
      await _switchToProviderMode(notification);
    }
  }

  // Method untuk beralih ke provider mode dan navigasi
  Future<void> _switchToProviderMode(
    notification_entity.Notification notification,
  ) async {
    try {
      // Tandai notifikasi sebagai dibaca
      if (!notification.isRead) {
        _notificationBloc.add(MarkAsReadEvent(notificationId: notification.id));
      }

      // Berikan feedback haptic
      try {
        HapticFeedback.lightImpact();
      } catch (e) {
        logger.w('Haptic feedback error: $e');
      }

      // Navigasi berdasarkan tipe notifikasi
      final type = notification.type;
      final entityId = notification.relatedEntityId;

      if (type.value == 'new_order' ||
          type.value == 'order_created' ||
          type.value == 'order') {
        // Navigasi ke halaman pesanan provider dengan mode switch
        context.go('/provider-orders');
      } else if (type.value == 'order_update' && entityId != null) {
        // Navigasi ke detail pesanan provider
        if (_isValidUUID(entityId)) {
          context.go('/provider-orders/details/$entityId');
        } else {
          logger.w('Invalid order ID format: $entityId');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format ID pesanan tidak valid'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Default ke dashboard provider
        context.go('/provider-dashboard');
      }

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil beralih ke mode provider'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      logger.e('Error switching to provider mode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal beralih ke mode provider: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildNotificationItem(notification_entity.Notification notification) {
    final bool isNew = _newNotificationIds.contains(notification.id);
    final bool isSelected = _selectedNotificationIds.contains(notification.id);

    Widget item;
    if (widget.mode == 'provider') {
      item = ProviderNotificationItem(
        notification: notification,
        onTap: () {
          if (_isSelectionMode) {
            // Dalam selection mode, tap untuk toggle selection
            _handleSelectionTap(notification);
          } else {
            // Tap normal untuk navigasi
            _handleNotificationTap(notification);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            // Long press untuk memulai selection mode
            _enableSelectionMode(notification);
          }
        },
        isHighlighted: isSelected, // Highlight only based on selection
      );
    } else {
      // For user mode, NotificationItem doesn't have isHighlighted.
      // The new status is handled by the animation wrapper.
      item = NotificationItem(
        notification: notification,
        onTap: () => _handleNotificationTap(notification),
        onMarkAsRead: () {
          _notificationBloc.add(
            MarkAsReadEvent(notificationId: notification.id),
          );
        },
      );
    }

    if (_isSelectionMode && widget.mode == 'provider') {
      item = _buildSelectableNotificationItem(notification, isSelected, item);
    }

    if (isNew) {
      return FadeTransition(opacity: _newNotificationAnimation, child: item);
    }

    return item;
  }

  void _enableSelectionMode(notification_entity.Notification notification) {
    if (widget.mode != 'provider') return; // Selection mode only for provider
    setState(() {
      _isSelectionMode = true;
      _selectedNotificationIds.add(notification.id);
    });
  }

  void _handleSelectionTap(notification_entity.Notification notification) {
    setState(() {
      if (_selectedNotificationIds.contains(notification.id)) {
        _selectedNotificationIds.remove(notification.id);
        if (_selectedNotificationIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNotificationIds.add(notification.id);
      }
    });
  }

  void _cancelSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNotificationIds.clear();
    });
  }

  // Fungsi untuk menganimasikan efek visual saat semua notifikasi ditandai sebagai dibaca
  void _animateAllNotificationsRead() {
    if (_notificationBloc.state is NotificationsLoaded) {
      final state = _notificationBloc.state as NotificationsLoaded;
      final unreadNotifications =
          state.notifications.where((n) => !n.isRead).toList();

      if (unreadNotifications.isNotEmpty) {
        // Tampilkan feedback setelah proses selesai
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${unreadNotifications.length} notifikasi telah ditandai dibaca',
                ),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        });
      }
    }
  }

  Widget _buildSelectableNotificationItem(
    notification_entity.Notification notification,
    bool isSelected,
    Widget child,
  ) {
    return Stack(
      children: [
        child, // The actual ProviderNotificationItem
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => _handleSelectionTap(notification),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? AppColors.primary : Colors.grey.withAlpha(76),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  void _markSelectedAsRead() {
    if (_notificationBloc.state is NotificationsLoaded) {
      final state = _notificationBloc.state as NotificationsLoaded;
      final selectedNotifications = state.notifications
          .where((n) => _selectedNotificationIds.contains(n.id))
          .toList();

      final unreadIds = selectedNotifications
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toList();
      if (unreadIds.isNotEmpty) {
        _notificationBloc.add(
          ProcessMarkAsReadBatchEvent(notificationIds: unreadIds),
        );
      }

      _cancelSelectionMode();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(AppStrings.notifikasi),
      actions: [
        if (widget.mode == 'provider')
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () {
              // Tampilkan loading indicator
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 20),
                      Text('Menandai semua notifikasi sebagai dibaca...'),
                    ],
                  ),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              // Tambahkan efek visual pada notifikasi
              _animateAllNotificationsRead();

              // Tandai semua sebagai dibaca
              _notificationBloc.add(MarkAllAsReadEvent(userId: widget.userId));
            },
            tooltip: 'Tandai semua sebagai dibaca',
          )
        else
          TextButton(
            onPressed: () {
              _notificationBloc.add(MarkAllAsReadEvent(userId: widget.userId));
            },
            child: const Text(
              AppStrings.tandaiSemuaDibaca,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _cancelSelectionMode,
      ),
      title: Text('${_selectedNotificationIds.length} dipilih'),
      actions: [
        if (_selectedNotificationIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _markSelectedAsRead,
            tooltip: 'Tandai sebagai dibaca',
          ),
      ],
    );
  }

  Future<void> _onRefresh() async {
    _notificationBloc.add(
      GetNotificationsEvent(userId: widget.userId, page: 1, limit: 10),
    );
    await _notificationBloc.stream.firstWhere(
      (state) => state is NotificationsLoaded || state is NotificationError,
    );
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == DateTime(now.year, now.month, now.day)) {
      return 'Hari Ini';
    } else if (dateToCheck == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    }
  }

  Map<String, List<notification_entity.Notification>> _groupNotificationsByDate(
    List<notification_entity.Notification> notifications,
  ) {
    final Map<String, List<notification_entity.Notification>>
        groupedNotifications = {};
    for (var notification in notifications) {
      final date = DateFormat('yyyy-MM-dd').format(notification.createdAt);
      if (!groupedNotifications.containsKey(date)) {
        groupedNotifications[date] = [];
      }
      groupedNotifications[date]!.add(notification);
    }
    return groupedNotifications;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _notificationBloc,
      child: Scaffold(
        appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildAppBar(),
        body: BlocConsumer<NotificationBloc, NotificationState>(
          listenWhen: (previous, current) {
            // Only listen for state changes that might introduce new notifications or show errors.
            return current is NotificationsLoaded ||
                current is NotificationError;
          },
          listener: (context, state) {
            if (state is NotificationError) {
              // Show snackbar only if there's an error message.
              if (state.message.isNotEmpty) {
                final snackBar = SnackBar(content: Text(state.message));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            } else if (state is NotificationsLoaded) {
              // Compare new list with already known new notifications to find brand new ones.
              final incomingIds = state.notifications.map((n) => n.id).toSet();
              final brandNewIds = incomingIds.difference(_newNotificationIds);

              if (brandNewIds.isNotEmpty) {
                setState(() {
                  _newNotificationIds.addAll(brandNewIds);
                });
                // Animate the new items in.
                _newNotificationAnimationController.forward(from: 0.0);
              }
            }
          },
          builder: (context, state) {
            // Show full-screen loader only on initial load.
            if (state is NotificationLoading && state.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show error message if loading fails and there's no data to show.
            if (state is NotificationError && state.notifications.isEmpty) {
              return Center(child: Text(state.message));
            }

            // Show empty message if there are no notifications at all.
            if (state.notifications.isEmpty) {
              return const Center(child: Text('Tidak ada notifikasi'));
            }

            // If we are here, we have notifications to display.
            final notifications = state.notifications;
            final groupedNotifications = _groupNotificationsByDate(
              notifications,
            );
            final sortedDates = groupedNotifications.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final notificationsForDate = groupedNotifications[date]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          _formatGroupDate(
                            notificationsForDate.first.createdAt,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ...notificationsForDate.map((notification) {
                        // Use ValueKey to ensure Flutter correctly identifies and animates items.
                        return Container(
                          key: ValueKey(notification.id),
                          child: _buildNotificationItem(notification),
                        );
                      }),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
