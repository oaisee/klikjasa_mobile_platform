import 'package:equatable/equatable.dart';

enum PromotionStatus { none, scheduled, active, ended }

/// Entity untuk merepresentasikan layanan/jasa yang ditawarkan oleh provider.
/// Menggantikan entity Layanan yang lama dengan struktur yang lebih konsisten.
class Service extends Equatable {
  final String id;
  final String providerId;
  final int categoryId;
  final String? categoryName;
  final String title;
  final String description;
  final double price;
  final String? priceUnit;
  final String? locationText;
  final List<String>? imagesUrls;
  final bool isActive;
  final double? averageRating;
  final int? ratingCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isPromoted; // Menandakan apakah layanan sedang dipromosikan
  final DateTime? promotionStartDate; // Tanggal mulai promosi
  final DateTime? promotionEndDate; // Tanggal berakhir promosi
  final List<String>? serviceAreas; // Area layanan (ID kabupaten/kota)

  const Service({
    required this.id,
    required this.providerId,
    required this.categoryId,
    this.categoryName,
    required this.title,
    required this.description,
    required this.price,
    this.priceUnit,
    this.locationText,
    this.imagesUrls,
    required this.isActive,
    this.averageRating,
    this.ratingCount,
    this.createdAt,
    this.updatedAt,
    this.isPromoted = false,
    this.promotionStartDate,
    this.promotionEndDate,
    this.serviceAreas,
  });

  @override
  List<Object?> get props => [
    id,
    providerId,
    categoryId,
    categoryName,
    title,
    description,
    price,
    priceUnit,
    locationText,
    imagesUrls,
    isActive,
    averageRating,
    ratingCount,
    createdAt,
    updatedAt,
    isPromoted,
    promotionStartDate,
    promotionEndDate,
  ];

  /// Getter untuk mendapatkan harga yang sudah diformat
  String get formattedPrice {
    String unit = priceUnit != null && priceUnit!.isNotEmpty
        ? '/${priceUnit!}'
        : '';
    // Menggunakan regex yang lebih aman untuk format harga
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => '.')}$unit';
  }

  /// Getter untuk mendapatkan URL gambar pertama
  String? get firstImageUrl =>
      (imagesUrls != null && imagesUrls!.isNotEmpty) ? imagesUrls!.first : null;

  /// Menentukan status promosi berdasarkan tanggal saat ini
  PromotionStatus get promotionStatus {
    final now = DateTime.now();
    if (!isPromoted || promotionStartDate == null || promotionEndDate == null) {
      return PromotionStatus.none;
    }

    // Menambahkan 1 hari ke promotionEndDate untuk membuatnya inklusif sampai akhir hari
    final inclusiveEndDate = promotionEndDate!.add(const Duration(days: 1));

    if (now.isAfter(inclusiveEndDate)) {
      return PromotionStatus.ended;
    }
    if (now.isBefore(promotionStartDate!)) {
      return PromotionStatus.scheduled;
    }
    return PromotionStatus.active;
  }

  /// Membuat salinan Service dengan beberapa properti yang diubah
  Service copyWith({
    String? id,
    String? providerId,
    int? categoryId,
    String? categoryName,
    String? title,
    String? description,
    double? price,
    String? priceUnit,
    String? locationText,
    List<String>? imagesUrls,
    bool? isActive,
    double? averageRating,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPromoted,
    DateTime? promotionStartDate,
    DateTime? promotionEndDate,
  }) {
    return Service(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      locationText: locationText ?? this.locationText,
      imagesUrls: imagesUrls ?? this.imagesUrls,
      isActive: isActive ?? this.isActive,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPromoted: isPromoted ?? this.isPromoted,
      promotionStartDate: promotionStartDate ?? this.promotionStartDate,
      promotionEndDate: promotionEndDate ?? this.promotionEndDate,
    );
  }

  /// Konversi ke Map untuk serialisasi
  Map<String, dynamic> toMap() {
    final map = {
      'provider_id': providerId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'price_unit': priceUnit,
      'location_text': locationText,
      'images_urls': imagesUrls,
      'is_active': isActive,
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'is_promoted': isPromoted,
      'promotion_start_date': promotionStartDate?.toIso8601String(),
      'promotion_end_date': promotionEndDate?.toIso8601String(),
    };

    // Hanya sertakan 'id' jika tidak kosong (untuk update)
    if (id.isNotEmpty) {
      map['id'] = id;
    }

    // Hanya sertakan timestamp jika tidak null
    if (createdAt != null) {
      map['created_at'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toIso8601String();
    }

    return map;
  }

  /// Membuat Service dari Map (deserialisasi)
  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id']?.toString() ?? '00000000-0000-0000-0000-000000000000',
      providerId:
          map['provider_id']?.toString() ??
          '00000000-0000-0000-0000-000000000000',
      categoryId: map['category_id'] is int ? map['category_id'] : 0,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: map['price'] is num ? (map['price'] as num).toDouble() : 0.0,
      priceUnit: map['price_unit']?.toString(),
      locationText: map['location_text']?.toString(),
      imagesUrls: map['images_urls'] != null
          ? List<dynamic>.from(
              map['images_urls'],
            ).map((e) => e.toString()).toList()
          : null,
      isActive: map['is_active'] is bool ? map['is_active'] : true,
      averageRating: map['average_rating'] is num
          ? (map['average_rating'] as num).toDouble()
          : null,
      ratingCount: map['rating_count'] is int ? map['rating_count'] : null,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
      isPromoted: map['is_promoted'] is bool ? map['is_promoted'] : false,
      promotionStartDate: map['promotion_start_date'] == null
          ? null
          : DateTime.tryParse(map['promotion_start_date'].toString()),
      promotionEndDate: map['promotion_end_date'] == null
          ? null
          : DateTime.tryParse(map['promotion_end_date'].toString()),
    );
  }

  @override
  String toString() {
    return 'Service(id: $id, providerId: $providerId, categoryId: $categoryId, title: $title, description: $description, price: $price, priceUnit: $priceUnit, locationText: $locationText, imagesUrls: $imagesUrls, isActive: $isActive, averageRating: $averageRating, ratingCount: $ratingCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
