class PromotionalBanner {
  final int id;
  final String imageUrl;
  final String? targetUrl;
  final String? title;
  final String? description;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  PromotionalBanner({
    required this.id,
    required this.imageUrl,
    this.targetUrl,
    this.title,
    this.description,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PromotionalBanner.fromJson(Map<String, dynamic> json) {
    return PromotionalBanner(
      id: json['id'],
      imageUrl: json['image_url'],
      targetUrl: json['target_url'],
      title: json['title'],
      description: json['description'],
      isActive: json['is_active'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'target_url': targetUrl,
      'title': title,
      'description': description,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
