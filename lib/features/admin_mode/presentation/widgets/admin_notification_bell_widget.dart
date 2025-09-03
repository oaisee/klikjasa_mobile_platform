import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/routes/app_router.dart';
import 'package:klik_jasa/core/utils/logger.dart';

/// Widget notifikasi untuk admin dashboard yang menampilkan jumlah notifikasi
/// terkait penyedia jasa yang menunggu verifikasi dan pesan yang belum dibaca.
class AdminNotificationBellWidget extends StatefulWidget {
  const AdminNotificationBellWidget({super.key});

  @override
  State<AdminNotificationBellWidget> createState() => _AdminNotificationBellWidgetState();
}

class _AdminNotificationBellWidgetState extends State<AdminNotificationBellWidget> {
  int _notificationCount = 0;
  bool _isLoading = true;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Mengambil jumlah notifikasi yang belum dibaca dan penyedia yang menunggu verifikasi
  Future<void> _fetchNotificationCount() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Mengambil jumlah penyedia yang menunggu verifikasi
      final providerVerificationResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('is_provider', true)
          .eq('provider_verification_status', 'pending');

      final int pendingProviders = providerVerificationResponse.length;

      // Mengambil jumlah notifikasi admin yang belum dibaca
      final notificationsResponse = await _supabase
          .from('notifications')
          .select('id')
          .eq('is_read', false)
          .eq('type', 'admin');

      final int unreadNotifications = notificationsResponse.length;
      
      // Mengambil jumlah pesan chat yang belum dibaca oleh admin
      final adminId = _supabase.auth.currentUser!.id;
      final unreadMessagesResponse = await _supabase
          .from('messages')
          .select('id')
          .eq('receiver_id', adminId)
          .eq('is_read', false);
          
      final int unreadMessages = unreadMessagesResponse.length;
      
      logger.d('Admin Notification Count: Pending Providers: $pendingProviders, Unread Notifications: $unreadNotifications, Unread Messages: $unreadMessages');

      // Total notifikasi (termasuk pesan chat yang belum dibaca)
      final totalCount = pendingProviders + unreadNotifications + unreadMessages;

      if (mounted) {
        setState(() {
          _notificationCount = totalCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error fetching notification count: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Menyiapkan listener untuk perubahan pada notifikasi
  void _setupNotificationListener() {
    try {
      // Menggunakan timer untuk polling notifikasi setiap 30 detik
      // Ini adalah alternatif yang lebih sederhana daripada menggunakan Realtime API
      // yang mungkin memerlukan konfigurasi tambahan di sisi server
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted) {
          _fetchNotificationCount();
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      logger.e('Error setting up notification listener: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigasi ke halaman notifikasi admin
        // Sekarang navigasi ke halaman manajemen pengguna karena verifikasi penyedia sudah diintegrasikan di sana
        context.go('${AppRouter.adminBaseRoute}/${AppRouter.adminUserManagementRoute}');
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
            if (_isLoading)
              const Positioned(
                top: 0,
                right: 0,
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            else if (_notificationCount > 0)
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
                    _notificationCount > 9 ? '9+' : _notificationCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
