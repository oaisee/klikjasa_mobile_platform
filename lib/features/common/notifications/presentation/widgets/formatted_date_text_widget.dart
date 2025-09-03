import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FormattedDateTextWidget extends StatelessWidget {
  final DateTime date;
  final TextStyle? style;

  const FormattedDateTextWidget({
    super.key,
    required this.date,
    this.style,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 5) {
      return 'Baru saja';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds} detik lalu';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays == 1) {
      final yesterday = now.subtract(const Duration(days: 1));
      if (date.day == yesterday.day && date.month == yesterday.month && date.year == yesterday.year) {
         return 'Kemarin, ${DateFormat('HH:mm').format(date)}';
      }
      // Fallback jika 'kemarin' tidak tepat karena perbedaan jam
      return DateFormat('dd MMM, HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu, ${DateFormat('HH:mm').format(date)}';
    } else if (date.year == now.year) {
      return DateFormat('dd MMM, HH:mm').format(date);
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDate(date),
      style: style ?? TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }
}
