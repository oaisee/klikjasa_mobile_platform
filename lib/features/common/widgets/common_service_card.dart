import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

/// Widget kartu layanan yang dapat digunakan kembali di seluruh aplikasi
/// dengan berbagai konfigurasi tampilan
class CommonServiceCard extends StatelessWidget {
  /// Judul layanan
  final String title;
  
  /// Harga layanan
  final double price;
  
  /// URL gambar layanan (opsional)
  final List<String>? imageUrls;
  
  /// Lokasi layanan (opsional)
  final String? location;
  
  /// Rating layanan (opsional)
  final double? rating;
  
  /// Jumlah rating (opsional)
  final int? ratingCount;
  
  /// Nama penyedia layanan (opsional)
  final String? providerName;
  
  /// Apakah layanan dipromosikan
  final bool isPromoted;
  
  /// Fungsi yang dipanggil saat kartu ditekan
  final VoidCallback? onTap;
  
  /// Jenis tampilan kartu (grid atau list)
  final CardDisplayType displayType;

  const CommonServiceCard({
    super.key,
    required this.title,
    required this.price,
    this.imageUrls,
    this.location,
    this.rating,
    this.ratingCount,
    this.providerName,
    this.isPromoted = false,
    this.onTap,
    this.displayType = CardDisplayType.grid,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: displayType == CardDisplayType.grid 
          ? _buildGridCard(context) 
          : _buildListCard(context),
    );
  }

  /// Membangun tampilan kartu dalam bentuk grid
  Widget _buildGridCard(BuildContext context) {
    final String? imageUrl = imageUrls?.isNotEmpty == true 
        ? imageUrls!.first 
        : null;
        
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Mengatur agar column mengambil ukuran minimal
        mainAxisAlignment: MainAxisAlignment.start, // Memastikan konten dimulai dari atas
        children: [
          // Gambar layanan dengan gradasi
          AspectRatio(
            aspectRatio: 16/9, // Rasio aspek untuk gambar
            child: Stack(
              children: [
                // Gambar layanan
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: _buildServiceImage(imageUrl),
                ),
                // Gradasi di bagian bawah gambar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(153),
                        ],
                      ),
                    ),
                  ),
                ),
                // Badge promo jika dipromosikan
                if (isPromoted)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PROMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Informasi layanan
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), // Mengurangi padding vertikal
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Memastikan column mengambil ukuran minimal
              children: [
                // Judul layanan
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (providerName != null) ...[
                  const SizedBox(height: 2), // Mengurangi spacing
                  Text(
                    providerName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (location != null) ...[
                  const SizedBox(height: 2), // Mengurangi spacing
                  Text(
                    location!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4), // Mengurangi spacing 
                // Harga dan rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp${_formatPrice(price)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    if (rating != null) _buildRatingWidget(rating!, ratingCount),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun tampilan kartu dalam bentuk list
  Widget _buildListCard(BuildContext context) {
    final String? imageUrl = imageUrls?.isNotEmpty == true 
        ? imageUrls!.first 
        : null;
        
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar layanan
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: _buildServiceImage(imageUrl),
                  ),
                ),
                // Badge promo jika dipromosikan
                if (isPromoted)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PROMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Informasi layanan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul layanan
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Nama penyedia
                  if (providerName != null) ...[
                    Text(
                      providerName!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Rating dan ulasan
                  if (rating != null) ...[
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (ratingCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($ratingCount ulasan)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Harga dan lokasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp${_formatPrice(price)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      if (location != null)
                        Flexible(
                          child: Text(
                            location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun widget gambar layanan
  Widget _buildServiceImage(String? imageUrl) {
    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: double.infinity,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: double.infinity,
          color: Colors.grey[300],
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.grey,
          ),
        ),
      );
    } else {
      return Container(
        height: double.infinity,
        color: Colors.grey[300],
        child: const Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 40,
        ),
      );
    }
  }

  /// Membangun widget rating
  Widget _buildRatingWidget(double rating, int? count) {
    return Row(
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Format harga dengan pemisah ribuan
  String _formatPrice(double price) {
    final priceInt = price.toInt();
    final priceString = priceInt.toString();
    final buffer = StringBuffer();
    
    for (int i = 0; i < priceString.length; i++) {
      if ((priceString.length - i) % 3 == 0 && i > 0) {
        buffer.write('.');
      }
      buffer.write(priceString[i]);
    }
    
    return buffer.toString();
  }
}

/// Enum untuk jenis tampilan kartu
enum CardDisplayType {
  /// Tampilan grid (untuk halaman utama, kategori, dll)
  grid,
  
  /// Tampilan list (untuk hasil pencarian, dll)
  list,
}
