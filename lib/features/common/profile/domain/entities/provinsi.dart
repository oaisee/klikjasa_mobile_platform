class Provinsi {
  final String id;
  final String nama;

  Provinsi({
    required this.id,
    required this.nama,
  });

  factory Provinsi.fromJson(Map<String, dynamic> json) {
    return Provinsi(
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
    };
  }

  // Opsional: override equals dan hashCode jika Anda akan membandingkan objek Provinsi
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Provinsi && runtimeType == other.runtimeType && id == other.id && nama == other.nama;

  @override
  int get hashCode => id.hashCode ^ nama.hashCode;
}
