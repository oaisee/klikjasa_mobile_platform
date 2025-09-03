import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

class NotificationStatusChipWidget extends StatelessWidget {
  final String notificationType;
  final bool isRead;

  const NotificationStatusChipWidget({
    super.key,
    required this.notificationType,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    if (isRead) {
      return const SizedBox.shrink();
    }

    String statusText = 'Baru';
    Color statusColor = AppColors.primary;
    IconData statusIcon = Icons.fiber_new_outlined;

    switch (notificationType) {
      case 'order_created':
      case 'order_confirmed': // Untuk provider
        statusText = 'Pesanan Baru';
        statusColor = Colors.orange;
        statusIcon = Icons.shopping_bag_outlined;
        break;
      case 'order_accepted':
        statusText = 'Pesanan Diterima';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'order_rejected':
      case 'order_cancelled':
        statusText = 'Pesanan Dibatalkan';
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'order_completed':
        statusText = 'Pesanan Selesai';
        statusColor = AppColors.success;
        statusIcon = Icons.task_alt_outlined;
        break;
      case 'chat':
        statusText = 'Pesan Baru';
        statusColor = Colors.blue;
        statusIcon = Icons.message_outlined;
        break;
      case 'payment_success':
      case 'top_up_success':
        statusText = 'Pembayaran Berhasil';
        statusColor = Colors.green;
        statusIcon = Icons.credit_score_outlined;
        break;
      case 'payout_success':
        statusText = 'Penarikan Berhasil';
        statusColor = Colors.green;
        statusIcon = Icons.price_check_outlined;
        break;
      case 'balance_update':
      case 'saldo':
        statusText = 'Update Saldo';
        statusColor = Colors.teal;
        statusIcon = Icons.account_balance_wallet_outlined;
        break;
      case 'complaint_new':
      case 'complaint_update':
        statusText = 'Update Keluhan';
        statusColor = Colors.red;
        statusIcon = Icons.report_problem_outlined;
        break;
      case 'verification_pending':
        statusText = 'Verifikasi Diproses';
        statusColor = Colors.orange;
        statusIcon = Icons.pending_outlined;
        break;
      case 'verification_approved':
        statusText = 'Akun Terverifikasi';
        statusColor = Colors.cyan;
        statusIcon = Icons.verified_user_outlined;
        break;
      case 'review_new':
        statusText = 'Ulasan Baru';
        statusColor = Colors.amber;
        statusIcon = Icons.star_outline_rounded;
        break;
      // Tambahkan case lain jika diperlukan
    }

    return Container(
      margin: const EdgeInsets.only(top: 6, right: 4), // Sedikit margin agar tidak terlalu rapat
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withAlpha((0.3 * 255).round())),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: 12,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
