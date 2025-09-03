import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/entities/provider_order.dart';

class ProviderOrderModel extends ProviderOrder {
  const ProviderOrderModel({
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
    required super.service,
    required super.user,
  });

  factory ProviderOrderModel.fromJson(Map<String, dynamic> json) {
    return ProviderOrderModel(
      id: json['id'],
      userId: json['user_id'],
      serviceId: json['service_id'],
      providerId: json['provider_id'],
      orderStatus: json['order_status'],
      quantity: json['quantity'],
      totalPrice: json['total_price'].toDouble(),
      feeAmount: json['fee_amount'] != null ? json['fee_amount'].toDouble() : 
                (json['application_fee'] != null ? json['application_fee'].toDouble() : 0.0),
      feePercentage: json['fee_percentage']?.toDouble(),
      feeType: json['fee_type'],
      orderDate: DateTime.parse(json['order_date']),
      scheduledDate: json['scheduled_date'] != null ? DateTime.parse(json['scheduled_date']) : null,
      completionDate: json['completion_date'] != null ? DateTime.parse(json['completion_date']) : null,
      userNotes: json['user_notes'],
      providerNotes: json['provider_notes'],
      cancellationReason: json['cancellation_reason'],
      service: json['service'] ?? {},
      user: json['user'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'service_id': serviceId,
      'provider_id': providerId,
      'order_status': orderStatus,
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
      'service': service,
      'user': user,
    };
  }
}
