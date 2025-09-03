import 'package:equatable/equatable.dart';

class KategoriLayanan extends Equatable {
  final String id;
  final String namaKategori;
  final String? deskripsi;
  final String? iconUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const KategoriLayanan({
    required this.id,
    required this.namaKategori,
    this.deskripsi,
    this.iconUrl,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        namaKategori,
        deskripsi,
        iconUrl,
        createdAt,
        updatedAt,
      ];

  factory KategoriLayanan.fromJson(Map<String, dynamic> json) {
    return KategoriLayanan(
      id: json['id']?.toString() ?? '',
      namaKategori: json['nama_kategori']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString(),
      iconUrl: json['icon_url']?.toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Biasanya di-generate server
      'nama_kategori': namaKategori,
      'deskripsi': deskripsi,
      'icon_url': iconUrl,
    };
  }

  KategoriLayanan copyWith({
    String? id,
    String? namaKategori,
    String? deskripsi,
    String? iconUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KategoriLayanan(
      id: id ?? this.id,
      namaKategori: namaKategori ?? this.namaKategori,
      deskripsi: deskripsi ?? this.deskripsi,
      iconUrl: iconUrl ?? this.iconUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
