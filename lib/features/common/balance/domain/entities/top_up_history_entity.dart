import 'dart:convert';
import 'package:equatable/equatable.dart';

enum TopUpStatus { pending, completed, failed, cancelled }

class TopUpHistoryEntity extends Equatable {
  final int id;
  final String userId;
  final double amount;
  final TopUpStatus status;
  final String? paymentMethod;
  final Map<String, dynamic>? paymentDetails;
  final DateTime transactionTime;
  final String? externalTransactionId;
  final String? description;

  const TopUpHistoryEntity({
    this.id = 0,
    required this.userId,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.paymentDetails,
    required this.transactionTime,
    this.externalTransactionId,
    this.description,
  });

  factory TopUpHistoryEntity.fromJson(Map<String, dynamic> json) {
    return TopUpHistoryEntity(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '00000000-0000-0000-0000-000000000000',
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : json['amount'] ?? 0.0,
      status: _mapStringToTopUpStatus(json['status'] ?? 'pending'),
      paymentMethod: json['payment_method'],
      paymentDetails: _parsePaymentDetails(json['payment_details']),
      transactionTime: json['transaction_time'] != null
          ? DateTime.parse(json['transaction_time'])
          : DateTime.now(),
      externalTransactionId: json['external_transaction_id'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'status': status.toString().split('.').last,
      'payment_method': paymentMethod,
      'payment_details': paymentDetails,
      'transaction_time': transactionTime.toIso8601String(),
      'external_transaction_id': externalTransactionId,
      'description': description,
    };
  }

  static TopUpStatus _mapStringToTopUpStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return TopUpStatus.pending;
      case 'COMPLETED':
      case 'SUCCESS': // Menambahkan case untuk SUCCESS dari database
        return TopUpStatus.completed;
      case 'FAILED':
        return TopUpStatus.failed;
      case 'CANCELLED':
        return TopUpStatus.cancelled;
      case 'EXPIRED': // Menambahkan case untuk EXPIRED dari database
        return TopUpStatus.failed; // Map ke failed untuk kompatibilitas
      default:
        return TopUpStatus.pending;
    }
  }

  static Map<String, dynamic>? _parsePaymentDetails(dynamic paymentDetails) {
    if (paymentDetails == null) {
      return null;
    }

    // Jika sudah dalam bentuk Map, kembalikan langsung
    if (paymentDetails is Map<String, dynamic>) {
      return paymentDetails;
    }

    // Jika dalam bentuk String JSON, parse ke Map
    if (paymentDetails is String) {
      try {
        return jsonDecode(paymentDetails) as Map<String, dynamic>;
      } catch (e) {
        // Jika gagal parse, kembalikan null
        return null;
      }
    }

    // Jika tipe data tidak dikenali, kembalikan null
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    amount,
    status,
    paymentMethod,
    paymentDetails,
    transactionTime,
    externalTransactionId,
    description,
  ];
}
