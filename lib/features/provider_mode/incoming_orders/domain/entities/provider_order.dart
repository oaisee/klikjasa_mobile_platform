import 'package:equatable/equatable.dart';

class ProviderOrder extends Equatable {
  final int id;
  final String userId;
  final int serviceId;
  final String providerId;
  final String orderStatus;
  final int quantity;
  final double totalPrice;
  final double feeAmount;
  final double? feePercentage;
  final String? feeType; // 'percentage' atau 'fixed'
  final DateTime orderDate;
  final DateTime? scheduledDate;
  final DateTime? completionDate;
  final String? userNotes;
  final String? providerNotes;
  final String? cancellationReason;
  final Map<String, dynamic> service;
  final Map<String, dynamic> user;

  const ProviderOrder({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.providerId,
    required this.orderStatus,
    required this.quantity,
    required this.totalPrice,
    required this.feeAmount,
    this.feePercentage,
    this.feeType,
    required this.orderDate,
    this.scheduledDate,
    this.completionDate,
    this.userNotes,
    this.providerNotes,
    this.cancellationReason,
    required this.service,
    required this.user,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        serviceId,
        providerId,
        orderStatus,
        quantity,
        totalPrice,
        feeAmount,
        feePercentage,
        feeType,
        orderDate,
        scheduledDate,
        completionDate,
        userNotes,
        providerNotes,
        cancellationReason,
        service,
        user,
      ];
}
