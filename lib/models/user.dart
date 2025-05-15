class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // pengguna_jasa, penyedia_jasa, admin
  final double saldo;
  
  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.saldo = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] != null ? json['role'] as String : 'pengguna_jasa',
      saldo: json['saldo'] != null ? (json['saldo'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'saldo': saldo,
    };
  }
}
