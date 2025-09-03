import 'package:klik_jasa/features/common/app_config/domain/entities/app_config.dart';

/// Model untuk pengaturan aplikasi
class AppConfigModel extends AppConfig {
  const AppConfigModel({
    required super.key,
    required super.value,
    super.description,
    super.updatedAt,
    super.updatedBy,
  });

  /// Membuat model dari JSON
  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      key: json['key'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      updatedBy: json['updated_by'] as String?,
    );
  }

  /// Mengkonversi model ke JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      if (description != null) 'description': description,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (updatedBy != null) 'updated_by': updatedBy,
    };
  }

  /// Membuat salinan model dengan nilai baru
  AppConfigModel copyWith({
    String? key,
    String? value,
    String? description,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AppConfigModel(
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
