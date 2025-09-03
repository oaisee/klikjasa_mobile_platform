import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/utils/logger.dart';

class ServiceWithLocation extends Equatable {
  final int id;
  final String providerId;
  final String providerName;
  final String title;
  final String description;
  final double price;
  final String? priceUnit;
  final String? locationText;
  final List<String>? imagesUrls;
  final double averageRating;
  final int ratingCount;
  final bool isActive;
  final bool isPromoted;
  final String? provinsi;
  final String? kabupatenKota;
  final String? kecamatan;
  final String? desaKelurahan;
  final String? kodePos;
  final String? avatarUrl;

  const ServiceWithLocation({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.title,
    required this.description,
    required this.price,
    this.priceUnit,
    this.locationText,
    this.imagesUrls,
    required this.averageRating,
    required this.ratingCount,
    required this.isActive,
    this.isPromoted = false,
    this.provinsi,
    this.kabupatenKota,
    this.kecamatan,
    this.desaKelurahan,
    this.kodePos,
    this.avatarUrl,
  });

  /// Factory constructor untuk membuat instance dari map (misalnya, dari respons Supabase).
  factory ServiceWithLocation.fromMap(Map<String, dynamic> map) {
    // Debug: Print raw data untuk debugging
    logger.d('ServiceWithLocation.fromMap - Raw data: ${map.toString()}');

    // Ambil data profil dari 'profiles' atau 'provider' (untuk mendukung kedua format query)
    Map<String, dynamic>? profileData;
    if (map['profiles'] != null) {
      profileData = map['profiles'] as Map<String, dynamic>?;
    } else if (map['provider'] != null) {
      profileData = map['provider'] as Map<String, dynamic>?;
    }
    profileData ??= {}; // Default ke map kosong jika tidak ada data profil

    // Safely parse price, handle int or double
    num priceNum = map['price'] ?? 0;
    double price = priceNum.toDouble();

    // Safely parse average_rating, handle int or double
    num ratingNum = map['average_rating'] ?? 0.0;
    double averageRating = ratingNum.toDouble();

    // Debug: Periksa provider_id dari map
    logger.d(
      'ServiceWithLocation.fromMap - map["provider_id"]: ${map['provider_id']}',
    );
    logger.d(
      'ServiceWithLocation.fromMap - map["provider_id"] type: ${map['provider_id'].runtimeType}',
    );

    // Validasi provider_id
    String providerId =
        map['provider_id']?.toString() ??
        '00000000-0000-0000-0000-000000000000';
    logger.d(
      'ServiceWithLocation.fromMap - Provider ID after toString(): $providerId',
    );
    logger.d(
      'ServiceWithLocation.fromMap - Provider ID isEmpty check: ${providerId.isEmpty}',
    );

    // Jika provider_id kosong atau null, gunakan UUID kosong
    if (providerId.isEmpty) {
      logger.d(
        'ServiceWithLocation.fromMap - Provider ID was empty, changing to default UUID',
      );
      providerId = '00000000-0000-0000-0000-000000000000';
    }

    logger.d('ServiceWithLocation.fromMap - Final Provider ID: $providerId');

    return ServiceWithLocation(
      id: map['id'] ?? 0,
      providerId: providerId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: price,
      priceUnit: map['price_unit'] ?? '',
      imagesUrls: map['images_urls'] != null
          ? List<String>.from(map['images_urls'])
          : [],
      averageRating: averageRating,
      ratingCount: map['rating_count'] ?? 0,
      isActive: map['is_active'] ?? false,
      isPromoted: map['is_promoted'] ?? false,
      // from profiles table (which contains location)
      provinsi: profileData['provinsi'] as String?,
      kabupatenKota: profileData['kabupaten_kota'] as String?,
      kecamatan: profileData['kecamatan'] as String?,
      desaKelurahan: profileData['desa_kelurahan'] as String?,
      kodePos: profileData['postal_code'] as String?,
      locationText: profileData['address_detail'] as String?,
      // from profiles table
      providerName: profileData['full_name'] ?? 'Nama Penyedia Tidak Tersedia',
      avatarUrl: profileData['avatar_url'] as String?,
    );
  }

  // Metode untuk serialisasi ke JSON (digunakan oleh GoRouter codec)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id':
          providerId, // Gunakan provider_id untuk konsistensi dengan fromMap
      'providerName': providerName,
      'title': title,
      'description': description,
      'price': price,
      'priceUnit': priceUnit,
      'locationText': locationText,
      'imagesUrls': imagesUrls,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'isActive': isActive,
      'isPromoted': isPromoted,
      'provinsi': provinsi,
      'kabupatenKota': kabupatenKota,
      'kecamatan': kecamatan,
      'desaKelurahan': desaKelurahan,
      'kodePos': kodePos,
      'avatarUrl': avatarUrl,
    };
  }

  // Metode untuk deserialisasi dari JSON (digunakan oleh GoRouter codec)
  factory ServiceWithLocation.fromJson(Map<String, dynamic> json) {
    return ServiceWithLocation(
      id: json['id'] as int,
      providerId:
          json['provider_id']
              as String, // Gunakan provider_id untuk konsistensi
      providerName: json['providerName'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] as double,
      priceUnit: json['priceUnit'] as String?,
      locationText: json['locationText'] as String?,
      imagesUrls: json['imagesUrls'] != null
          ? List<String>.from(json['imagesUrls'])
          : null,
      averageRating: json['averageRating'] as double,
      ratingCount: json['ratingCount'] as int,
      isActive: json['isActive'] as bool,
      isPromoted: json['isPromoted'] as bool? ?? false,
      provinsi: json['provinsi'] as String?,
      kabupatenKota: json['kabupatenKota'] as String?,
      kecamatan: json['kecamatan'] as String?,
      desaKelurahan: json['desaKelurahan'] as String?,
      kodePos: json['kodePos'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    providerId,
    title,
    price,
    averageRating,
    isPromoted,
    provinsi,
    kabupatenKota,
  ];

  // Metode untuk membuat salinan objek dengan beberapa properti yang diubah
  ServiceWithLocation copyWith({
    int? id,
    String? providerId,
    String? providerName,
    String? title,
    String? description,
    double? price,
    String? priceUnit,
    String? locationText,
    List<String>? imagesUrls,
    double? averageRating,
    int? ratingCount,
    bool? isActive,
    bool? isPromoted,
    String? provinsi,
    String? kabupatenKota,
    String? kecamatan,
    String? desaKelurahan,
    String? kodePos,
    String? avatarUrl,
  }) {
    return ServiceWithLocation(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      priceUnit: priceUnit ?? this.priceUnit,
      locationText: locationText ?? this.locationText,
      imagesUrls: imagesUrls ?? this.imagesUrls,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      isActive: isActive ?? this.isActive,
      isPromoted: isPromoted ?? this.isPromoted,
      provinsi: provinsi ?? this.provinsi,
      kabupatenKota: kabupatenKota ?? this.kabupatenKota,
      kecamatan: kecamatan ?? this.kecamatan,
      desaKelurahan: desaKelurahan ?? this.desaKelurahan,
      kodePos: kodePos ?? this.kodePos,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
