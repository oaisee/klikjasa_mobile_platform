class Service {
  final String id;
  final String providerId;
  final String title;
  final String description;
  final double price;
  final int estimatedDuration; // dalam jam
  final List<String> areaLayanan; // list kode wilayah
  final List<String> images;
  final double rating;
  final int totalReviews;
  final DateTime createdAt;

  Service({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.price,
    required this.estimatedDuration,
    required this.areaLayanan,
    required this.images,
    this.rating = 0,
    this.totalReviews = 0,
    required this.createdAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      providerId: json['provider_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      estimatedDuration: json['estimated_duration'] as int,
      areaLayanan: List<String>.from(json['area_layanan'] as List),
      images: List<String>.from(json['images'] as List),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'title': title,
      'description': description,
      'price': price,
      'estimated_duration': estimatedDuration,
      'area_layanan': areaLayanan,
      'images': images,
      'rating': rating,
      'total_reviews': totalReviews,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
