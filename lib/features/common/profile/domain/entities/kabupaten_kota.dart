class KabupatenKota {
  final String id;
  final String nama;
  final String provinsiId; // Relasi ke Provinsi

  KabupatenKota({
    required this.id,
    required this.nama,
    required this.provinsiId,
  });

  factory KabupatenKota.fromJson(Map<String, dynamic> json) {
    return KabupatenKota(
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      provinsiId: json['provinsi_id']?.toString() ?? '', // Sesuaikan dengan nama kolom di DB
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'provinsi_id': provinsiId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KabupatenKota &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nama == other.nama &&
          provinsiId == other.provinsiId;

  @override
  int get hashCode => id.hashCode ^ nama.hashCode ^ provinsiId.hashCode;
}
