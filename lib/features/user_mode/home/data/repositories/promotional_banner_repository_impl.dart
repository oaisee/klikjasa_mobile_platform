import 'package:klik_jasa/features/user_mode/home/domain/entities/promotional_banner.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/promotional_banner_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromotionalBannerRepositoryImpl implements PromotionalBannerRepository {
  final SupabaseClient _supabaseClient;

  PromotionalBannerRepositoryImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  @override
  Future<List<PromotionalBanner>> getActiveBanners() async {
    try {
      final response = await _supabaseClient
          .from('promotional_banners')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((banner) => PromotionalBanner.fromJson(banner))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data banner promosi: $e');
    }
  }

  @override
  Stream<List<PromotionalBanner>> getActiveBannersStream() {
    return _supabaseClient
        .from('promotional_banners')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .map((data) => data
            .map((banner) => PromotionalBanner.fromJson(banner))
            .toList()
            .cast<PromotionalBanner>());
  }
}
