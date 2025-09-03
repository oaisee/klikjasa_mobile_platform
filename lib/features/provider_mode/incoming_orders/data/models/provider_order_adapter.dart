import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';
import 'package:klik_jasa/core/data/models/order_model.dart' as model;

/// Adapter class untuk membantu migrasi dari ProviderOrder ke Order yang terkonsolidasi
/// Class ini akan dihapus setelah migrasi selesai
class ProviderOrderAdapter {
  /// Mengkonversi Order ke format yang diharapkan oleh kode yang masih menggunakan ProviderOrder
  static Map<String, dynamic> orderToProviderOrderJson(Order order) {
    return {
      'id': order.id,
      'user_id': order.userId,
      'service_id': order.serviceId,
      'provider_id': order.providerId,
      'order_status': orderStatusToString(order.orderStatus),
      'quantity': order.quantity,
      'total_price': order.totalPrice,
      'fee_amount': order.feeAmount,
      'fee_percentage': order.feePercentage,
      'fee_type': order.feeType,
      'order_date': order.orderDate.toIso8601String(),
      'scheduled_date': order.scheduledDate?.toIso8601String(),
      'completion_date': order.completionDate?.toIso8601String(),
      'user_notes': order.userNotes,
      'provider_notes': order.providerNotes,
      'cancellation_reason': order.cancellationReason,
      'service': order.serviceDetails ?? {},
      'user': order.userDetails ?? {},
    };
  }

  /// Mengkonversi JSON dari format ProviderOrder ke Order
  static Order providerOrderJsonToOrder(Map<String, dynamic> json) {
    return Order.fromJson({
      'id': json['id'],
      'user_id': json['user_id'],
      'service_id': json['service_id'],
      'provider_id': json['provider_id'],
      'order_status': json['order_status'],
      'quantity': json['quantity'],
      'total_price': json['total_price'],
      'fee_amount': json['fee_amount'] ?? json['application_fee'] ?? 0,
      'fee_percentage': json['fee_percentage'],
      'fee_type': json['fee_type'],
      'order_date': json['order_date'],
      'scheduled_date': json['scheduled_date'],
      'completion_date': json['completion_date'],
      'user_notes': json['user_notes'],
      'provider_notes': json['provider_notes'],
      'cancellation_reason': json['cancellation_reason'],
      'service': json['service'],
      'user': json['user'],
      'created_at': json['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': json['updated_at'] ?? DateTime.now().toIso8601String(),
    });
  }
}

/// Alias untuk kompatibilitas dengan kode yang sudah ada
/// Akan dihapus setelah migrasi selesai
class ProviderOrder extends Order {
  ProviderOrder({
    required super.id,
    required super.userId,
    required super.serviceId,
    required super.providerId,
    required super.orderStatus,
    required super.quantity,
    required super.totalPrice,
    required super.feeAmount,
    super.feePercentage,
    super.feeType,
    required super.orderDate,
    super.scheduledDate,
    super.completionDate,
    super.userNotes,
    super.providerNotes,
    super.cancellationReason,
    Map<String, dynamic>? service,
    Map<String, dynamic>? user,
  }) : super(
         createdAt: DateTime.now(),
         updatedAt: DateTime.now(),
         serviceDetails: service,
         userDetails: user,
       );

  factory ProviderOrder.fromJson(Map<String, dynamic> json) {
    return ProviderOrder(
      id: json['id'] is int ? json['id'] : 0,
      userId:
          json['user_id']?.toString() ?? '00000000-0000-0000-0000-000000000000',
      serviceId: json['service_id'] is int ? json['service_id'] : 0,
      providerId:
          json['provider_id']?.toString() ??
          '00000000-0000-0000-0000-000000000000',
      orderStatus: parseOrderStatus(json['order_status']?.toString()),
      quantity: json['quantity'] is int ? json['quantity'] : 0,
      totalPrice: json['total_price'] is num
          ? (json['total_price'] as num).toDouble()
          : 0.0,
      feeAmount: json['fee_amount'] is num
          ? (json['fee_amount'] as num).toDouble()
          : (json['application_fee'] is num
                ? (json['application_fee'] as num).toDouble()
                : 0.0),
      feePercentage: json['fee_percentage'] is num
          ? (json['fee_percentage'] as num).toDouble()
          : null,
      feeType: json['fee_type']?.toString(),
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'].toString())
          : DateTime.now(),
      scheduledDate: json['scheduled_date'] == null
          ? null
          : DateTime.parse(json['scheduled_date'].toString()),
      completionDate: json['completion_date'] == null
          ? null
          : DateTime.parse(json['completion_date'].toString()),
      userNotes: json['user_notes']?.toString(),
      providerNotes: json['provider_notes']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      service: json['service'] is Map
          ? Map<String, dynamic>.from(json['service'])
          : null,
      user: json['user'] is Map
          ? Map<String, dynamic>.from(json['user'])
          : null,
    );
  }
}

/// Alias untuk kompatibilitas dengan kode yang sudah ada
/// Akan dihapus setelah migrasi selesai
class ProviderOrderModel extends model.OrderModel {
  ProviderOrderModel({
    required super.id,
    required super.userId,
    required super.serviceId,
    required super.providerId,
    required super.orderStatus,
    required super.quantity,
    required super.totalPrice,
    required super.feeAmount,
    super.feePercentage,
    super.feeType,
    required super.orderDate,
    super.scheduledDate,
    super.completionDate,
    super.userNotes,
    super.providerNotes,
    super.cancellationReason,
    Map<String, dynamic>? service,
    Map<String, dynamic>? user,
  }) : super(
         createdAt: DateTime.now(),
         updatedAt: DateTime.now(),
         serviceDetails: service,
         userDetails: user,
       );

  factory ProviderOrderModel.fromJson(Map<String, dynamic> json) {
    return ProviderOrderModel(
      id: json['id'] is int ? json['id'] : 0,
      userId:
          json['user_id']?.toString() ?? '00000000-0000-0000-0000-000000000000',
      serviceId: json['service_id'] is int ? json['service_id'] : 0,
      providerId:
          json['provider_id']?.toString() ??
          '00000000-0000-0000-0000-000000000000',
      orderStatus: parseOrderStatus(json['order_status']?.toString()),
      quantity: json['quantity'] is int ? json['quantity'] : 0,
      totalPrice: json['total_price'] is num
          ? (json['total_price'] as num).toDouble()
          : 0.0,
      feeAmount: json['fee_amount'] is num
          ? (json['fee_amount'] as num).toDouble()
          : (json['application_fee'] is num
                ? (json['application_fee'] as num).toDouble()
                : 0.0),
      feePercentage: json['fee_percentage'] is num
          ? (json['fee_percentage'] as num).toDouble()
          : null,
      feeType: json['fee_type']?.toString(),
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'].toString())
          : DateTime.now(),
      scheduledDate: json['scheduled_date'] == null
          ? null
          : DateTime.parse(json['scheduled_date'].toString()),
      completionDate: json['completion_date'] == null
          ? null
          : DateTime.parse(json['completion_date'].toString()),
      userNotes: json['user_notes']?.toString(),
      providerNotes: json['provider_notes']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
      service: json['service'] is Map
          ? Map<String, dynamic>.from(json['service'])
          : null,
      user: json['user'] is Map
          ? Map<String, dynamic>.from(json['user'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'service_id': serviceId,
      'provider_id': providerId,
      'order_status': orderStatusToString(orderStatus),
      'quantity': quantity,
      'total_price': totalPrice,
      'fee_amount': feeAmount,
      'fee_percentage': feePercentage,
      'fee_type': feeType,
      'order_date': orderDate.toIso8601String(),
      'scheduled_date': scheduledDate?.toIso8601String(),
      'completion_date': completionDate?.toIso8601String(),
      'user_notes': userNotes,
      'provider_notes': providerNotes,
      'cancellation_reason': cancellationReason,
      'service': serviceDetails,
      'user': userDetails,
    };
  }
}
