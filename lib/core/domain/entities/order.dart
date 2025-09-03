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
  final String? feeType; // 'percentage' atau 'fixed'
  final DateTime orderDate;
  final DateTime? scheduledDate;
  final DateTime? completionDate;
  final String? userNotes;
  final String? providerNotes;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Tambahkan informasi tambahan yang mungkin berguna dari join tabel, jika diperlukan nanti
  // Misalnya: nama layanan, nama pemesan, dll.
  // Untuk saat ini, kita fokus pada kolom dari tabel 'orders'
  final String? serviceTitle; // Contoh: Diambil dari join dengan tabel services
  final String?
  userName; // Contoh: Diambil dari join dengan tabel profiles (user)

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
  ];

  static OrderStatus _parseOrderStatus(String? status) {
    return parseOrderStatus(status);
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    // Persiapan untuk join: jika data service atau user ada dalam json
    final serviceData =
        json['services']; // Asumsi nama tabel join adalah 'services'
    final userData =
        json['profiles']; // Asumsi nama tabel join adalah 'profiles' (untuk user_id)

    return Order(
      id: json['id'] is int ? json['id'] : 0,
      userId:
          json['user_id']?.toString() ?? '00000000-0000-0000-0000-000000000000',
      serviceId: json['service_id'] is int ? json['service_id'] : 0,
      providerId:
          json['provider_id']?.toString() ??
          '00000000-0000-0000-0000-000000000000',
      orderStatus: _parseOrderStatus(json['order_status']?.toString()),
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
      // Mengambil data dari join jika ada
      serviceTitle: serviceData != null && serviceData is Map<String, dynamic>
          ? serviceData['title']?.toString()
          : null,
      userName: userData != null && userData is Map<String, dynamic>
          ? userData['full_name']?.toString()
          : null,
      // Jika nama field di tabel profiles berbeda, sesuaikan 'full_name'
    );
  }

  // toJson method jika diperlukan untuk mengirim data ke Supabase (misalnya saat update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'service_id': serviceId,
      'provider_id': providerId,
      'order_status': orderStatusToString(
        orderStatus,
      ), // Menggunakan helper function
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
      // Kolom join tidak perlu dikirim balik biasanya
    };
  }
}
