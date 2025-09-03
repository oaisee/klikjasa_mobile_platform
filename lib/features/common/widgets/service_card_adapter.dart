import 'package:flutter/material.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service.dart';
import 'package:klik_jasa/features/common/widgets/common_service_card.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';

/// Adapter untuk menggunakan CommonServiceCard dengan berbagai tipe data layanan
class ServiceCardAdapter {
  /// Membuat CommonServiceCard dari entity Service
  static CommonServiceCard fromService({
    required Service service,
    VoidCallback? onTap,
    CardDisplayType displayType = CardDisplayType.grid,
  }) {
    return CommonServiceCard(
      title: service.title,
      price: service.price,
      imageUrls: service.imagesUrls,
      location: service.locationText,
      rating: service.averageRating,
      ratingCount: service.ratingCount,
      isPromoted: service.isPromoted == true,
      onTap: onTap,
      displayType: displayType,
    );
  }

  /// Membuat CommonServiceCard dari entity ServiceWithLocation
  static CommonServiceCard fromServiceWithLocation({
    required ServiceWithLocation service,
    VoidCallback? onTap,
    CardDisplayType displayType = CardDisplayType.grid,
  }) {
    return CommonServiceCard(
      title: service.title,
      price: service.price,
      imageUrls: service.imagesUrls,
      location: service.locationText,
      rating: service.averageRating,
      ratingCount: service.ratingCount,
      providerName: service.providerName,
      isPromoted: service.isPromoted == true,
      onTap: onTap,
      displayType: displayType,
    );
  }

  /// Membuat CommonServiceCard dari Map (biasanya dari Supabase)
  static CommonServiceCard fromMap({
    required Map<String, dynamic> serviceMap,
    VoidCallback? onTap,
    CardDisplayType displayType = CardDisplayType.grid,
    bool isListView = false,
  }) {
    // Ekstrak data dari Map
    final title = serviceMap['title'] as String? ?? 'Tidak ada judul';
    final price = (serviceMap['price'] as num?)?.toDouble() ?? 0.0;
    
    List<String>? imageUrls;
    if (serviceMap['images_urls'] != null) {
      if (serviceMap['images_urls'] is List) {
        imageUrls = (serviceMap['images_urls'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (serviceMap['images_urls'] is String) {
        // Jika disimpan sebagai string dengan format tertentu
        final imagesString = serviceMap['images_urls'] as String;
        if (imagesString.startsWith('[') && imagesString.endsWith(']')) {
          imageUrls = imagesString
              .substring(1, imagesString.length - 1)
              .split(',')
              .map((e) => e.trim().replaceAll('"', ''))
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    }
    
    final location = serviceMap['location_text'] as String?;
    final rating = (serviceMap['average_rating'] as num?)?.toDouble();
    final ratingCount = (serviceMap['rating_count'] as num?)?.toInt();
    final providerName = serviceMap['provider_name'] as String?;
    final isPromoted = serviceMap['is_promoted'] as bool? ?? false;
    
    return CommonServiceCard(
      title: title,
      price: price,
      imageUrls: imageUrls,
      location: location,
      rating: rating,
      ratingCount: ratingCount,
      providerName: providerName,
      isPromoted: isPromoted,
      onTap: onTap,
      displayType: displayType,
    );
  }
}
