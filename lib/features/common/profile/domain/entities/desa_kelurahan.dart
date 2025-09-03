class DesaKelurahan {
  final String id;
  final String nama;
  final String kecamatanId; // Relasi ke Kecamatan

  DesaKelurahan({
    required this.id,
    required this.nama,
    required this.kecamatanId,
  });

  factory DesaKelurahan.fromJson(Map<String, dynamic> json) {
    return DesaKelurahan(
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      kecamatanId: json['kecamatan_id']?.toString() ?? '', // Sesuaikan dengan nama kolom di DB
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'kecamatan_id': kecamatanId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesaKelurahan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nama == other.nama &&
          kecamatanId == other.kecamatanId;

  @override
  int get hashCode => id.hashCode ^ nama.hashCode ^ kecamatanId.hashCode;
}
