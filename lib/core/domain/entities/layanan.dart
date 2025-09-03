import 'package:equatable/equatable.dart';

class Layanan extends Equatable {
  final String id;
  final String providerId;
  final int categoryId;
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

  const Layanan({
    required this.id,
    required this.providerId,
    required this.categoryId,
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
  });

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
        isActive,
        averageRating,
        ratingCount,
        createdAt,
        updatedAt,
      ];

  String get formattedPrice {
    String unit = priceUnit != null && priceUnit!.isNotEmpty ? '/${priceUnit!}' : '';
    // Menggunakan regex yang lebih aman untuk format harga
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => '.')}$unit';
  }

  String? get firstImageUrl => (imagesUrls != null && imagesUrls!.isNotEmpty) ? imagesUrls!.first : null;

  factory Layanan.fromJson(Map<String, dynamic> json) {
    String serviceId;
    if (json['id'] is int) {
      serviceId = (json['id'] as int).toString();
    } else if (json['id'] is String) {
      serviceId = json['id'] as String;
    } else {
      // Default ke string kosong atau handle error jika id tidak ada atau tipe tidak valid
      serviceId = json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(); // Fallback ID jika null
      // Sebaiknya ada error handling yang lebih baik di sini jika id krusial dan selalu diharapkan
    }

    List<String>? imageUrlsFromJson;
    if (json['images_urls'] != null && json['images_urls'] is List) {
      imageUrlsFromJson = List<String>.from(
          (json['images_urls'] as List).map((item) => item is String ? item : item.toString()));
    }

    return Layanan(
      id: serviceId,
      providerId: json['provider_id'] is String ? json['provider_id'] : '',
      categoryId: json['category_id'] is int ? json['category_id'] : 0,
      title: json['title'] is String ? json['title'] : '',
      description: json['description'] is String ? json['description'] : '',
      price: json['price'] is num ? json['price'].toDouble() : 0.0,
      priceUnit: json['price_unit'] is String ? json['price_unit'] : null,
      locationText: json['location_text'] is String ? json['location_text'] : null,
      imagesUrls: imageUrlsFromJson,
      isActive: json['is_active'] is bool ? json['is_active'] : true, // Default ke true jika null
      averageRating: json['average_rating'] is num ? json['average_rating'].toDouble() : null,
      ratingCount: json['rating_count'] is int ? json['rating_count'] : null,
      createdAt: json['created_at'] == null
          ? null
          : json['created_at'] is String ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] == null
          ? null
          : json['updated_at'] is String ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Biasanya tidak dikirim saat create/update jika auto-generated atau sudah ada di path
      'provider_id': providerId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'price_unit': priceUnit,
      'location_text': locationText,
      'images_urls': imagesUrls,
      'is_active': isActive,
      // averageRating dan ratingCount biasanya dihitung server
      // createdAt dan updatedAt juga biasanya dihandle server
    };
  }

  Layanan copyWith({
    String? id,
    String? providerId,
    int? categoryId,
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
  }) {
    return Layanan(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      categoryId: categoryId ?? this.categoryId,
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
    );
  }
}
