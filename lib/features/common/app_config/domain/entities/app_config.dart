import 'package:equatable/equatable.dart';

/// Entity untuk pengaturan aplikasi
class AppConfig extends Equatable {
  final String key;
  final String value;
  final String? description;
  final DateTime? updatedAt;
  final String? updatedBy;

  const AppConfig({
    required this.key,
    required this.value,
    this.description,
    this.updatedAt,
    this.updatedBy,
  });

  @override
  List<Object?> get props => [key, value, description, updatedAt, updatedBy];

  /// Mengkonversi nilai string ke double jika memungkinkan
  double? toDouble() {
    try {
      return double.parse(value);
    } catch (_) {
      return null;
    }
  }

  /// Mengkonversi nilai string ke int jika memungkinkan
  int? toInt() {
    try {
      return int.parse(value);
    } catch (_) {
      return null;
    }
  }

  /// Mengkonversi nilai string ke bool jika memungkinkan
  bool? toBool() {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    return null;
  }
}
