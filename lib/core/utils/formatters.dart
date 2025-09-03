import 'package:intl/intl.dart';

/// Utility class untuk formatting berbagai jenis data
/// 
/// Berisi fungsi-fungsi untuk memformat currency, date, phone number, dll.
class Formatters {
  /// Format currency ke format Rupiah
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format currency dengan decimal
  static String formatCurrencyWithDecimal(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format number dengan separator ribuan
  static String formatNumber(int number) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(number);
  }

  /// Format date ke format Indonesia (dd MMMM yyyy)
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd MMMM yyyy', 'id_ID');
    return formatter.format(date);
  }

  /// Format date ke format pendek (dd/MM/yyyy)
  static String formatDateShort(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  /// Format datetime ke format lengkap (dd MMMM yyyy, HH:mm)
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    return formatter.format(dateTime);
  }

  /// Format time ke format HH:mm
  static String formatTime(DateTime time) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(time);
  }

  /// Format nomor telepon Indonesia
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.startsWith('08')) {
      // Format: 0812-3456-7890
      if (cleanNumber.length >= 10) {
        return '${cleanNumber.substring(0, 4)}-${cleanNumber.substring(4, 8)}-${cleanNumber.substring(8)}';
      }
    } else if (cleanNumber.startsWith('628')) {
      // Format: +62 812-3456-7890
      if (cleanNumber.length >= 12) {
        return '+62 ${cleanNumber.substring(3, 6)}-${cleanNumber.substring(6, 10)}-${cleanNumber.substring(10)}';
      }
    }
    
    return phoneNumber; // Return original if can't format
  }

  /// Format file size ke format human readable
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Format duration ke format human readable
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} hari';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} jam';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} menit';
    } else {
      return '${duration.inSeconds} detik';
    }
  }

  /// Format relative time (berapa lama yang lalu)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Truncate text dengan ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Format percentage
  static String formatPercentage(double value, {int decimalPlaces = 1}) {
    return '${(value * 100).toStringAsFixed(decimalPlaces)}%';
  }

  /// Format rating (1.0 - 5.0)
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Format distance dalam meter/kilometer
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}