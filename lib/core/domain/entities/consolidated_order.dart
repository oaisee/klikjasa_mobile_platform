import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';

class Order extends Equatable {
  final int id;
  final String userId; // ID pengguna jasa (pemesan)
  final int serviceId;
  final String providerId; // ID penyedia jasa
  final OrderStatus orderStatus;
  final int quantity;
  final double totalPrice;
  final double feeAmount;
  final double? feePercentage;
  final String? feeType;
  final DateTime orderDate;
  final DateTime? scheduledDate;
  final DateTime? completionDate;
  final String? userNotes;
  final String? providerNotes;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Informasi tambahan dari join tabel
  final String? serviceTitle;
  final String? userName;
  final Map<String, dynamic>? serviceDetails;
  final Map<String, dynamic>? userDetails;

  const Order({
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
    required this.createdAt,
    required this.updatedAt,
    this.serviceTitle,
    this.userName,
    this.serviceDetails,
    this.userDetails,
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
    createdAt,
    updatedAt,
    serviceTitle,
    userName,
    serviceDetails,
    userDetails,
  ];

  // Factory constructor untuk membuat Order dari JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    // Persiapan untuk join: jika data service atau user ada dalam json
    final serviceData = json['services'] ?? json['service'];

    // Handle cases where joined data can be a map or a list of maps.
    Map<String, dynamic>? userData;
    final rawUserData = json['user'] ?? json['profiles'];
    if (rawUserData is Map<String, dynamic>) {
      userData = rawUserData;
    } else if (rawUserData is List && rawUserData.isNotEmpty) {
      // If it's a list, take the first element.
      userData = rawUserData.first as Map<String, dynamic>;
    }

    return Order(
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
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),

      // Mengambil data dari join jika ada.
      // The type check for serviceData is to ensure it's a map before accessing keys.
      serviceTitle: serviceData is Map<String, dynamic>
          ? serviceData['title']?.toString()
          : null,
      userName: userData?['full_name']?.toString(),

      // Menyimpan data lengkap jika diperlukan
      serviceDetails: serviceData is Map<String, dynamic>
          ? Map.from(serviceData)
          : null,
      userDetails: userData,
    );
  }

  // toJson method untuk mengirim data ke Supabase
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

  // Helper untuk membuat salinan dengan perubahan tertentu
  Order copyWith({
    int? id,
    String? userId,
    int? serviceId,
    String? providerId,
    OrderStatus? orderStatus,
    int? quantity,
    double? totalPrice,
    double? feeAmount,
    double? feePercentage,
    String? feeType,
    DateTime? orderDate,
    DateTime? scheduledDate,
    DateTime? completionDate,
    String? userNotes,
    String? providerNotes,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serviceTitle,
    String? userName,
    Map<String, dynamic>? serviceDetails,
    Map<String, dynamic>? userDetails,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      providerId: providerId ?? this.providerId,
      orderStatus: orderStatus ?? this.orderStatus,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      feeAmount: feeAmount ?? this.feeAmount,
      feePercentage: feePercentage ?? this.feePercentage,
      feeType: feeType ?? this.feeType,
      orderDate: orderDate ?? this.orderDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completionDate: completionDate ?? this.completionDate,
      userNotes: userNotes ?? this.userNotes,
      providerNotes: providerNotes ?? this.providerNotes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      userName: userName ?? this.userName,
      serviceDetails: serviceDetails ?? this.serviceDetails,
      userDetails: userDetails ?? this.userDetails,
    );
  }
}
