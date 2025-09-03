class Kecamatan {
  final String id;
  final String nama;
  final String kabupatenKotaId; // Relasi ke KabupatenKota

  Kecamatan({
    required this.id,
    required this.nama,
    required this.kabupatenKotaId,
  });

  factory Kecamatan.fromJson(Map<String, dynamic> json) {
    return Kecamatan(
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      kabupatenKotaId: json['kabupaten_kota_id']?.toString() ?? '', // Sesuaikan dengan nama kolom di DB
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'kabupaten_kota_id': kabupatenKotaId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Kecamatan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nama == other.nama &&
          kabupatenKotaId == other.kabupatenKotaId;

  @override
  int get hashCode => id.hashCode ^ nama.hashCode ^ kabupatenKotaId.hashCode;
}
