import 'package:equatable/equatable.dart';

/// Entity untuk kategori layanan
class ServiceCategory extends Equatable {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final String? iconName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.iconName,
    this.createdAt,
    this.updatedAt,
  });

  /// Membuat ServiceCategory dari Map (biasanya dari Supabase)
  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    return ServiceCategory(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      iconName: map['icon_name'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  /// Mengkonversi ServiceCategory ke Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'icon_name': iconName,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
  
  /// Alias untuk fromMap untuk kompatibilitas dengan kode yang menggunakan fromJson
  factory ServiceCategory.fromJson(Map<String, dynamic> json) => ServiceCategory.fromMap(json);
  
  /// Alias untuk toMap untuk kompatibilitas dengan kode yang menggunakan toJson
  Map<String, dynamic> toJson() => toMap();

  @override
  List<Object?> get props => [id, name, description, isActive, iconName, createdAt, updatedAt];
}
