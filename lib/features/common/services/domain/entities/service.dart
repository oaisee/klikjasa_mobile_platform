import 'package:equatable/equatable.dart';

class Service extends Equatable {
  final int id;
  final String providerId;
  final int categoryId;
  final String title;
  final String description;
  final double price;
  final String? priceUnit;
  final String? locationText;
  final List<String>? imagesUrls;
  final double? averageRating;
  final int? ratingCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPromoted;
  final DateTime? promotionStartDate;
  final DateTime? promotionEndDate;

  const Service({
    required this.id,
    required this.providerId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    this.priceUnit,
    this.locationText,
    this.imagesUrls,
    this.averageRating,
    this.ratingCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.isPromoted = false,
    this.promotionStartDate,
    this.promotionEndDate,
  });

  Service copyWith({
    int? id,
    String? providerId,
    int? categoryId,
    String? title,
    String? description,
    double? price,
    String? priceUnit,
    String? locationText,
    List<String>? imagesUrls,
    double? averageRating,
    int? ratingCount,
    bool? isActive,
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
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      locationText: locationText ?? this.locationText,
      imagesUrls: imagesUrls ?? this.imagesUrls,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPromoted: isPromoted ?? this.isPromoted,
      promotionStartDate: promotionStartDate ?? this.promotionStartDate,
      promotionEndDate: promotionEndDate ?? this.promotionEndDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'provider_id': providerId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'price_unit': priceUnit,
      'location_text': locationText,
      'images_urls': imagesUrls,
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_promoted': isPromoted,
      'promotion_start_date': promotionStartDate?.toIso8601String(),
      'promotion_end_date': promotionEndDate?.toIso8601String(),
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] as int,
      providerId: map['provider_id'] as String,
      categoryId: map['category_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      price: map['price'] as double,
      priceUnit: map['price_unit'] as String?,
      locationText: map['location_text'] as String?,
      imagesUrls: map['images_urls'] != null ? List<String>.from(map['images_urls']) : null,
      averageRating: map['average_rating'] != null ? map['average_rating'] as double : null,
      ratingCount: map['rating_count'] != null ? map['rating_count'] as int : null,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isPromoted: map['is_promoted'] as bool? ?? false,
      promotionStartDate: map['promotion_start_date'] != null 
          ? DateTime.parse(map['promotion_start_date']) 
          : null,
      promotionEndDate: map['promotion_end_date'] != null 
          ? DateTime.parse(map['promotion_end_date']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id, 
    providerId, 
    categoryId, 
    title, 
    description, 
    price, 
    priceUnit, 
    locationText, 
    imagesUrls, 
    averageRating, 
    ratingCount, 
    isActive, 
    createdAt, 
    updatedAt,
    isPromoted,
    promotionStartDate,
    promotionEndDate,
  ];
}
