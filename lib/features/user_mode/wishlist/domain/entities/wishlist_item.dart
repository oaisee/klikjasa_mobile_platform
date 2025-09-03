class WishlistItem {
  final String serviceId;
  final String serviceTitle;
  final String? serviceDescription;
  final double servicePrice;
  final String? servicePriceUnit;
  final List<String>? serviceImages;
  final double? serviceRating;
  final int? serviceRatingCount;
  final String providerId;
  final String providerName;
  final String? providerLocation;
  final DateTime addedAt;

  const WishlistItem({
    required this.serviceId,
    required this.serviceTitle,
    this.serviceDescription,
    required this.servicePrice,
    this.servicePriceUnit,
    this.serviceImages,
    this.serviceRating,
    this.serviceRatingCount,
    required this.providerId,
    required this.providerName,
    this.providerLocation,
    required this.addedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishlistItem && other.serviceId == serviceId;
  }

  @override
  int get hashCode => serviceId.hashCode;

  @override
  String toString() {
    return 'WishlistItem(serviceId: $serviceId, serviceTitle: $serviceTitle, providerId: $providerId, providerName: $providerName)';
  }
}