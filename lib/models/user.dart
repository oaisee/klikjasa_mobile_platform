class AppUser {
  final String id;
  final String email;
  final String name;
  final String role; // pengguna_jasa, penyedia_jasa, admin
  final double saldo;
  final String? phoneNumber;
  final String? profileImageUrl;
  
  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.saldo = 0,
    this.phoneNumber,
    this.profileImageUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] != null ? json['role'] as String : 'pengguna_jasa',
      saldo: json['saldo'] != null ? (json['saldo'] as num).toDouble() : 0.0,
      phoneNumber: json['phone_number'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'saldo': saldo,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
    };
  }
}
