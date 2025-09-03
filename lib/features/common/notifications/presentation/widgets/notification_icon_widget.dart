import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

class NotificationIconWidget extends StatelessWidget {
  final String notificationType;
  final bool isRead;

  const NotificationIconWidget({
    super.key,
    required this.notificationType,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (notificationType) {
      case 'order': // Generic order type
      case 'order_created':
      case 'order_accepted':
      case 'order_rejected':
      case 'order_cancelled':
      case 'order_completed':
      case 'order_confirmed': // Untuk provider
      case 'order_updated':
        iconData = Icons.receipt_long_outlined;
        iconColor = Colors.blue;
        break;
      case 'chat':
        iconData = Icons.chat_bubble_outline_rounded;
        iconColor = Colors.orange;
        break;
      case 'payment_success':
      case 'payment_failed':
      case 'top_up_success':
      case 'top_up_failed':
      case 'payout_success':
      case 'payout_failed':
        iconData = Icons.payment_outlined;
        iconColor = Colors.green;
        break;
      case 'promo':
        iconData = Icons.local_offer_outlined;
        iconColor = Colors.purple;
        break;
      case 'balance_update': // Misal, setelah fee transaksi
      case 'saldo': // Tipe lama, bisa dipertimbangkan untuk migrasi
        iconData = Icons.account_balance_wallet_outlined;
        iconColor = Colors.teal;
        break;
      case 'complaint_new':
      case 'complaint_update':
        iconData = Icons.report_problem_outlined;
        iconColor = Colors.red;
        break;
      case 'verification_pending': // Untuk provider
      case 'verification_approved': // Untuk provider
      case 'verification_rejected': // Untuk provider
        iconData = Icons.verified_user_outlined;
        iconColor = Colors.cyan;
        break;
      case 'account_update':
      case 'password_changed':
        iconData = Icons.manage_accounts_outlined;
        iconColor = AppColors.info;
        break;
      case 'review_new':
        iconData = Icons.star_outline_rounded;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.notifications_outlined;
        iconColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead 
            ? iconColor.withAlpha((0.1 * 255).round()) 
            : iconColor.withAlpha((0.2 * 255).round()),
        shape: BoxShape.circle,
        boxShadow: isRead 
            ? null 
            : [
                BoxShadow(
                  color: iconColor.withAlpha((0.3 * 255).round()),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }
}
