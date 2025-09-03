enum NotificationType {
  orderCreated('order_created'),
  orderAccepted('order_accepted'),
  orderCompleted('order_completed'),
  orderCancelled('order_cancelled'),
  chatMessage('chat_message'),
  providerVerified('provider_verified'),
  balanceUpdated('balance_updated'),
  promotion('promotion'),
  systemAlert('system_alert');

  const NotificationType(this.value);

  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.systemAlert,
    );
  }

  /// Mendapatkan NotificationType dari string value dengan fallback
  static NotificationType fromValue(String value) {
    for (NotificationType type in NotificationType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return NotificationType.systemAlert; // Default fallback
  }

  String get displayName {
    switch (this) {
      case NotificationType.orderCreated:
        return 'Pesanan Dibuat';
      case NotificationType.orderAccepted:
        return 'Pesanan Diterima';
      case NotificationType.orderCompleted:
        return 'Pesanan Selesai';
      case NotificationType.orderCancelled:
        return 'Pesanan Dibatalkan';
      case NotificationType.chatMessage:
        return 'Pesan Chat';
      case NotificationType.providerVerified:
        return 'Penyedia Terverifikasi';
      case NotificationType.balanceUpdated:
        return 'Saldo Diperbarui';
      case NotificationType.promotion:
        return 'Promosi';
      case NotificationType.systemAlert:
        return 'Peringatan Sistem';
    }
  }

  String get iconPath {
    switch (this) {
      case NotificationType.orderCreated:
        return 'assets/icons/order_created.svg';
      case NotificationType.orderAccepted:
        return 'assets/icons/order_accepted.svg';
      case NotificationType.orderCompleted:
        return 'assets/icons/order_completed.svg';
      case NotificationType.orderCancelled:
        return 'assets/icons/order_cancelled.svg';
      case NotificationType.chatMessage:
        return 'assets/icons/chat_message.svg';
      case NotificationType.providerVerified:
        return 'assets/icons/provider_verified.svg';
      case NotificationType.balanceUpdated:
        return 'assets/icons/balance_updated.svg';
      case NotificationType.promotion:
        return 'assets/icons/promotion.svg';
      case NotificationType.systemAlert:
        return 'assets/icons/system_alert.svg';
    }
  }

  bool get isHighPriority {
    switch (this) {
      case NotificationType.orderCreated:
      case NotificationType.orderAccepted:
      case NotificationType.orderCompleted:
      case NotificationType.orderCancelled:
      case NotificationType.systemAlert:
        return true;
      case NotificationType.chatMessage:
      case NotificationType.providerVerified:
      case NotificationType.balanceUpdated:
      case NotificationType.promotion:
        return false;
    }
  }

  bool get requiresAction {
    switch (this) {
      case NotificationType.orderCreated:
      case NotificationType.orderAccepted:
      case NotificationType.chatMessage:
        return true;
      case NotificationType.orderCompleted:
      case NotificationType.orderCancelled:
      case NotificationType.providerVerified:
      case NotificationType.balanceUpdated:
      case NotificationType.promotion:
      case NotificationType.systemAlert:
        return false;
    }
  }
}