import 'package:klik_jasa/features/user_mode/home/domain/entities/promotional_banner.dart';

abstract class PromotionalBannerRepository {
  /// Mengambil daftar banner promosi yang aktif
  Future<List<PromotionalBanner>> getActiveBanners();
  
  /// Mengambil stream banner promosi untuk realtime updates
  Stream<List<PromotionalBanner>> getActiveBannersStream();
}
