import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';

/// Widget untuk menampilkan gambar dari network dengan optimasi performa
/// menggunakan CachedNetworkImage untuk menggantikan Image.network
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Duration fadeInDuration;
  final Duration placeholderFadeInDuration;
  final bool useOldImageOnUrlChange;
  final Map<String, String>? httpHeaders;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.placeholderFadeInDuration = const Duration(milliseconds: 300),
    this.useOldImageOnUrlChange = false,
    this.httpHeaders,
  });

  /// Factory constructor untuk avatar dengan style circular
  factory OptimizedNetworkImage.avatar({
    required String imageUrl,
    double size = 50,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return OptimizedNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size / 2),
      placeholder: placeholder ?? _buildDefaultAvatarPlaceholder(size),
      errorWidget: errorWidget ?? _buildDefaultAvatarError(size),
    );
  }

  /// Factory constructor untuk thumbnail dengan style rounded
  factory OptimizedNetworkImage.thumbnail({
    required String imageUrl,
    double width = 80,
    double height = 80,
    double borderRadius = 8,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return OptimizedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(borderRadius),
      placeholder: placeholder ?? _buildDefaultThumbnailPlaceholder(width, height),
      errorWidget: errorWidget ?? _buildDefaultThumbnailError(width, height),
    );
  }

  /// Factory constructor untuk banner dengan style wide
  factory OptimizedNetworkImage.banner({
    required String imageUrl,
    double? width,
    double height = 200,
    double borderRadius = 12,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return OptimizedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(borderRadius),
      placeholder: placeholder ?? _buildDefaultBannerPlaceholder(width, height),
      errorWidget: errorWidget ?? _buildDefaultBannerError(width, height),
    );
  }

  /// Factory constructor untuk service image dengan style card
  factory OptimizedNetworkImage.serviceImage({
    required String imageUrl,
    double? width,
    double height = 150,
    double borderRadius = 8,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return OptimizedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(borderRadius),
      placeholder: placeholder ?? _buildDefaultServicePlaceholder(width, height),
      errorWidget: errorWidget ?? _buildDefaultServiceError(width, height),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Validasi URL
    if (imageUrl.isEmpty || !_isValidUrl(imageUrl)) {
      return _buildErrorWidget();
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      placeholderFadeInDuration: placeholderFadeInDuration,
      useOldImageOnUrlChange: useOldImageOnUrlChange,
      httpHeaders: httpHeaders,
      placeholder: (context, url) => _buildPlaceholderWidget(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      // Optimasi memory dan cache
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );

    // Apply border radius jika ada
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Validasi URL gambar
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Build placeholder widget
  Widget _buildPlaceholderWidget() {
    if (placeholder != null) {
      return placeholder!;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    if (errorWidget != null) {
      return errorWidget!;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  // Static helper methods untuk default widgets
  static Widget _buildDefaultAvatarPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  static Widget _buildDefaultAvatarError(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.person, color: Colors.grey),
      ),
    );
  }

  static Widget _buildDefaultThumbnailPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  static Widget _buildDefaultThumbnailError(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }

  static Widget _buildDefaultBannerPlaceholder(double? width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  static Widget _buildDefaultBannerError(double? width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
      ),
    );
  }

  static Widget _buildDefaultServicePlaceholder(double? width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  static Widget _buildDefaultServiceError(double? width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.work_outline, color: Colors.grey, size: 32),
      ),
    );
  }
}
