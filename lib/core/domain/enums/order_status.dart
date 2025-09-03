import 'package:logger/logger.dart';

final _logger = Logger();

// Enum untuk status pesanan, sesuai dengan public.order_status_enum di Supabase
enum OrderStatus {
  pendingConfirmation,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rejected,
  unknown, // Untuk kasus default atau error parsing
}

// Helper function to convert OrderStatus enum to its string representation for DB
String orderStatusToString(OrderStatus status) {
  switch (status) {
    case OrderStatus.pendingConfirmation:
      return 'pending_confirmation';
    case OrderStatus
        .confirmed: // Diartikan sebagai pesanan diterima oleh penyedia
      return 'accepted_by_provider';
    case OrderStatus.inProgress:
      return 'in_progress';
    case OrderStatus
        .completed: // Diartikan sebagai pesanan selesai oleh penyedia
      return 'completed_by_provider';
    case OrderStatus
        .cancelled: // Dipetakan ke cancelled_by_user untuk sementara
      return 'cancelled_by_user';
    case OrderStatus
        .rejected: // Diartikan sebagai pesanan ditolak oleh penyedia
      return 'rejected_by_provider';
    case OrderStatus.unknown:
      return 'unknown';
  }
}

// Helper function to convert string to OrderStatus enum
OrderStatus parseOrderStatus(String? status) {
  if (status == null || status.isEmpty) {
    _logger.w(
      'Warning: Status string kosong atau null, menggunakan OrderStatus.unknown',
    );
    return OrderStatus.unknown;
  }

  final statusLower = status.toLowerCase().trim();

  switch (statusLower) {
    case 'pending_confirmation':
      return OrderStatus.pendingConfirmation;
    case 'accepted_by_provider':
      return OrderStatus.confirmed;
    case 'rejected_by_provider':
    case 'rejected': // Tambahan untuk menangani status 'rejected'
      return OrderStatus.rejected;
    case 'in_progress':
      return OrderStatus.inProgress;
    case 'completed_by_provider':
    case 'completed': // Tambahan untuk menangani status 'completed'
      return OrderStatus.completed;
    case 'cancelled_by_user':
    case 'cancelled_by_provider':
    case 'cancelled': // Tambahan untuk menangani status 'cancelled'
      return OrderStatus.cancelled;
    case 'disputed':
      return OrderStatus.unknown; // Sementara
    case 'unknown':
      return OrderStatus.unknown;
    default:
      // Log untuk debugging
      _logger.w(
        'Warning: Status string tidak dikenal: "$status", menggunakan OrderStatus.unknown',
      );
      return OrderStatus.unknown;
  }
}
