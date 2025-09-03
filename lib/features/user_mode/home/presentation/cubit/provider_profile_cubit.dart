import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/provider_profile_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Cubit untuk mengelola state profil penyedia jasa
class ProviderProfileCubit extends Cubit<ProviderProfileState> {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  ProviderProfileCubit() : super(ProviderProfileInitial());

  /// Mengambil data profil penyedia jasa berdasarkan ID
  Future<void> fetchProviderProfile(String providerId) async {
    try {
      emit(ProviderProfileLoading());

      // Mengambil data profil penyedia jasa
      final profileResponse = await _supabase
          .from('profiles')
          .select('*, provider_details')
          .eq('id', providerId)
          .single();

      // Mengambil data layanan yang ditawarkan oleh penyedia jasa
      final servicesResponse = await _supabase
          .from('services')
          .select('*, service_categories(name)')
          .eq('provider_id', providerId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      // Mengambil data rating rata-rata
      final ratingResponse = await _supabase
          .from('reviews')
          .select('rating')
          .eq('provider_id', providerId)
          .eq('is_archived', false);

      // Menghitung rating rata-rata
      double averageRating = 0.0;
      if (ratingResponse.isNotEmpty) {
        final totalRating = ratingResponse.fold<double>(
            0, (sum, item) => sum + (item['rating'] as num).toDouble());
        averageRating = totalRating / ratingResponse.length;
      }

      // Emit state berhasil dengan data yang diambil
      emit(ProviderProfileLoaded(
        profileData: profileResponse,
        services: List<Map<String, dynamic>>.from(servicesResponse),
        averageRating: averageRating,
        reviewCount: ratingResponse.length,
      ));
    } catch (e) {
      _logger.e('Error fetching provider profile: $e');
      emit(ProviderProfileError(message: e.toString()));
    }
  }
}
