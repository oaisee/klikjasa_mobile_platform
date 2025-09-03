class PromotionalBanner {
  final int id;
  final String imageUrl;
  final String? title;
  final String? targetUrl;
  final bool isActive;
  final int sortOrder;
  final String? description; // Menambahkan deskripsi jika ada di DB
  final DateTime? createdAt; // Opsional, jika ingin ditampilkan/digunakan
  final DateTime? updatedAt; // Opsional
  final String? uploadedBy; // UUID String, opsional

  PromotionalBanner({
    required this.id,
    required this.imageUrl,
    this.title,
    this.targetUrl,
    required this.isActive,
    required this.sortOrder,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.uploadedBy,
  });

  factory PromotionalBanner.fromJson(Map<String, dynamic> json) {
    return PromotionalBanner(
      id: json['id'] is int ? json['id'] : 0,
      imageUrl: json['image_url']?.toString() ?? '',
      title: json['title']?.toString(),
      targetUrl: json['target_url']?.toString(),
      isActive: json['is_active'] is bool ? json['is_active'] : false,
      sortOrder: json['sort_order'] is int ? json['sort_order'] : 0,
      description: json['description']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      uploadedBy: json['uploaded_by']?.toString(),
    );
  }

  // Opsional: toJson method jika diperlukan untuk mengirim data (meskipun saat ini tidak digunakan untuk update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'title': title,
      'target_url': targetUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'uploaded_by': uploadedBy,
    };
  }
}
