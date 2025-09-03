import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';

class OrderModel extends Order {
  const OrderModel({
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
    required super.createdAt,
    required super.updatedAt,
    super.serviceTitle,
    super.userName,
    super.serviceDetails,
    super.userDetails,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
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
          : 0.0,
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
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      // Mengambil data dari join jika ada
      serviceTitle: _extractServiceTitle(json),
      userName: _extractUserName(json),
      // Menyimpan data lengkap jika diperlukan
      serviceDetails: _extractServiceDetails(json),
      userDetails: _extractUserDetails(json),
    );
  }

  // Helper methods untuk ekstraksi data
  static String? _extractServiceTitle(Map<String, dynamic> json) {
    final serviceData = json['services'] ?? json['service'];
    return serviceData != null && serviceData is Map<String, dynamic>
        ? serviceData['title']?.toString()
        : null;
  }

  static String? _extractUserName(Map<String, dynamic> json) {
    final userData = json['profiles'] ?? json['user'];
    return userData != null && userData is Map<String, dynamic>
        ? userData['full_name']?.toString()
        : null;
  }

  static Map<String, dynamic>? _extractServiceDetails(
    Map<String, dynamic> json,
  ) {
    final serviceData = json['services'] ?? json['service'];
    return serviceData is Map<String, dynamic>
        ? Map<String, dynamic>.from(serviceData)
        : null;
  }

  static Map<String, dynamic>? _extractUserDetails(Map<String, dynamic> json) {
    final userData = json['profiles'] ?? json['user'];
    return userData is Map<String, dynamic>
        ? Map<String, dynamic>.from(userData)
        : null;
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Factory method untuk membuat OrderModel dari entitas Order
  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      userId: order.userId,
      serviceId: order.serviceId,
      providerId: order.providerId,
      orderStatus: order.orderStatus,
      quantity: order.quantity,
      totalPrice: order.totalPrice,
      feeAmount: order.feeAmount,
      feePercentage: order.feePercentage,
      feeType: order.feeType,
      orderDate: order.orderDate,
      scheduledDate: order.scheduledDate,
      completionDate: order.completionDate,
      userNotes: order.userNotes,
      providerNotes: order.providerNotes,
      cancellationReason: order.cancellationReason,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      serviceTitle: order.serviceTitle,
      userName: order.userName,
      serviceDetails: order.serviceDetails,
      userDetails: order.userDetails,
    );
  }
}
