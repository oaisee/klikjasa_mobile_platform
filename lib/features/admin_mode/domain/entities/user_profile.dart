import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String? email;
  final String? fullName;
  final String? role;
  final String?
  providerVerificationStatus; // Ditambahkan untuk status verifikasi
  final String? userStatus; // Status pengguna: active, blocked, inactive
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? avatarUrl;
  final String? phoneNumber;
  final bool? isProvider;
  final String? provinsi;
  final String? kabupatenKota;
  final String? kecamatan;
  final String? desaKelurahan;
  final String? addressDetail; // Dari kolom address_detail
  final String? postalCode; // Dari kolom postal_code
  final String? ktpUrl;
  final double? latitude;
  final double? longitude;
  final double? saldo; // Tambahan field saldo

  const UserProfile({
    required this.id,
    this.email,
    this.fullName,
    this.role,
    this.providerVerificationStatus,
    this.userStatus,
    this.createdAt,
    this.updatedAt,
    this.avatarUrl,
    this.phoneNumber,
    this.isProvider,
    this.provinsi,
    this.kabupatenKota,
    this.kecamatan,
    this.desaKelurahan,
    this.addressDetail,
    this.postalCode,
    this.ktpUrl,
    this.latitude,
    this.longitude,
    this.saldo, // Tambahan field saldo
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '00000000-0000-0000-0000-000000000000',
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString(),
      role: json['role']?.toString(),
      providerVerificationStatus: json['provider_verification_status']
          ?.toString(),
      userStatus: json['user_status']?.toString() ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      avatarUrl: json['avatar_url']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      isProvider: json['is_provider'] is bool ? json['is_provider'] : false,
      provinsi: json['provinsi']?.toString(),
      kabupatenKota: json['kabupaten_kota']?.toString(),
      kecamatan: json['kecamatan']?.toString(),
      desaKelurahan: json['desa_kelurahan']?.toString(),
      addressDetail: json['address_detail']?.toString(),
      postalCode: json['postal_code']?.toString(),
      ktpUrl: json['ktp_url']?.toString(),
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : null,
      saldo: json['saldo'] is num
          ? (json['saldo'] as num).toDouble()
          : null, // Tambahan field saldo
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    role,
    providerVerificationStatus,
    userStatus,
    createdAt,
    updatedAt,
    avatarUrl,
    phoneNumber,
    isProvider,
    provinsi,
    kabupatenKota,
    kecamatan,
    desaKelurahan,
    addressDetail,
    postalCode,
    ktpUrl,
    latitude,
    longitude,
    saldo, // Tambahan field saldo
  ];
}
