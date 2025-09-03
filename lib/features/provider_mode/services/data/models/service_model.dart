import 'package:klik_jasa/core/domain/entities/service.dart';

/// Model untuk Service yang mengextend entity Service.
/// Digunakan untuk konversi data dari/ke layer data (database, API, dll).
class ServiceModel extends Service {
  const ServiceModel({
    super.categoryName,
    required super.id,
    required super.providerId,
    required super.categoryId,
    required super.title,
    required super.description,
    required super.price,
    super.priceUnit,
    super.locationText,
    super.imagesUrls,
    required super.isActive,
    super.averageRating,
    super.ratingCount,
    super.createdAt,
    super.updatedAt,
    super.isPromoted = false,
    super.promotionStartDate,
    super.promotionEndDate,
  });

  /// Factory constructor untuk membuat ServiceModel dari JSON
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '00000000-0000-0000-0000-000000000000',
      providerId:
          json['provider_id']?.toString() ??
          '00000000-0000-0000-0000-000000000000',
      categoryId: json['category_id'] is int ? json['category_id'] : 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price'] is num ? (json['price'] as num).toDouble() : 0.0,
      priceUnit: json['price_unit']?.toString(),
      locationText: json['location_text']?.toString(),
      imagesUrls: json['images_urls'] != null
          ? List<dynamic>.from(
              json['images_urls'],
            ).map((e) => e.toString()).toList()
          : null,
      isActive: json['is_active'] is bool ? json['is_active'] : true,
      averageRating: json['average_rating'] is num
          ? (json['average_rating'] as num).toDouble()
          : null,
      ratingCount: json['rating_count'] is int ? json['rating_count'] : null,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
      isPromoted: json['is_promoted'] is bool ? json['is_promoted'] : false,
      promotionStartDate: json['promotion_start_date'] == null
          ? null
          : DateTime.tryParse(json['promotion_start_date'].toString()),
      promotionEndDate: json['promotion_end_date'] == null
          ? null
          : DateTime.tryParse(json['promotion_end_date'].toString()),
      categoryName: json['categories'] != null && json['categories'] is Map
          ? json['categories']['name']?.toString()
          : null,
    );
  }

  /// Factory constructor untuk membuat ServiceModel dari entity Service
  factory ServiceModel.fromEntity(Service service) {
    return ServiceModel(
      id: service.id,
      providerId: service.providerId,
      categoryId: service.categoryId,
      categoryName: service.categoryName,
      title: service.title,
      description: service.description,
      price: service.price,
      priceUnit: service.priceUnit,
      locationText: service.locationText,
      imagesUrls: service.imagesUrls,
      isActive: service.isActive,
      averageRating: service.averageRating,
      ratingCount: service.ratingCount,
      createdAt: service.createdAt,
      updatedAt: service.updatedAt,
      isPromoted: service.isPromoted,
      promotionStartDate: service.promotionStartDate,
      promotionEndDate: service.promotionEndDate,
    );
  }

  /// Konversi ServiceModel ke JSON
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'provider_id': providerId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'price_unit': priceUnit,
      'location_text': locationText,
      'images_urls': imagesUrls ?? [],
      'is_active': isActive,
      'average_rating': averageRating ?? 0.0,
      'rating_count': ratingCount ?? 0,
      'is_promoted': isPromoted,
      'promotion_start_date': promotionStartDate?.toIso8601String(),
      'promotion_end_date': promotionEndDate?.toIso8601String(),
    };

    // Tambahkan id hanya jika tidak kosong (untuk operasi update)
    if (id.isNotEmpty) {
      result['id'] = id;
    }

    // Jangan sertakan timestamp jika null, biarkan DB menggunakan default
    if (createdAt != null) {
      result['created_at'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      result['updated_at'] = updatedAt!.toIso8601String();
    }

    return result;
  }

  /// Konversi ServiceModel ke entity Service
  Service toEntity() {
    return Service(
      id: id,
      providerId: providerId,
      categoryId: categoryId,
      title: title,
      description: description,
      price: price,
      priceUnit: priceUnit,
      locationText: locationText,
      imagesUrls: imagesUrls,
      isActive: isActive,
      averageRating: averageRating,
      ratingCount: ratingCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPromoted: isPromoted,
      promotionStartDate: promotionStartDate,
      promotionEndDate: promotionEndDate,
    );
  }

  /// Membuat salinan ServiceModel dengan beberapa properti yang diubah
  @override
  ServiceModel copyWith({
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
    return ServiceModel(
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
}
