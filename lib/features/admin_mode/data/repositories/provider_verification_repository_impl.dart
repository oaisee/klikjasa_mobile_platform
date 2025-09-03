import 'package:klik_jasa/features/admin_mode/domain/entities/user_profile.dart';
import 'package:klik_jasa/features/admin_mode/domain/repositories/provider_verification_repository.dart';
import 'package:flutter/foundation.dart'; // Untuk debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';

class ProviderVerificationRepositoryImpl
    implements ProviderVerificationRepository {
  final SupabaseClient supabase;

  ProviderVerificationRepositoryImpl({required this.supabase});

  @override
  Future<List<UserProfile>> getPendingProviderVerifications() async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq(
            'provider_verification_status',
            'pending',
          ) // Fokus pada status verifikasi // Hanya yang statusnya 'pending'
          .order('created_at', ascending: true);

      // Supabase select() mengembalikan PostgrestResponse.
      // Data ada di response.data, error di response.error.
      // Jika tidak ada error, response.data akan berupa List<Map<String, dynamic>>.
      // Jika ada error, response.error akan berisi PostgrestError.

      // Tidak perlu lagi memeriksa tipe 'response' secara manual seperti sebelumnya.
      // Supabase client >v1.0.0 menangani ini secara internal.
      // Cukup periksa apakah ada data.
      final List<dynamic> data = List<dynamic>.from(response); // response dari select() adalah List<Map<String, dynamic>>
      debugPrint(
        'Raw pending verifications data from Supabase in getPendingProviderVerifications: $data',
      );

      return data
          .map((item) => UserProfile.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Error in getPendingProviderVerifications: $e');
      throw Exception(
        'Failed to fetch pending provider verifications: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateProviderVerificationStatus(
    String userId,
    String newStatus,
  ) async {
    try {
      // Metode update() di Supabase client >v1.0.0 tidak mengembalikan data secara default.
      // Jika terjadi error, ia akan melempar PostgrestException.
      // Jadi, kita tidak perlu memeriksa 'response.error' secara manual di sini,
      // cukup tangkap exception jika terjadi.
      await supabase
          .from('profiles')
          .update({'provider_verification_status': newStatus})
          .eq('id', userId);

      // Jika tidak ada exception, operasi dianggap berhasil.
    } catch (e) {
      debugPrint('Error in updateProviderVerificationStatus: $e');
      throw Exception(
        'Failed to update provider verification status: ${e.toString()}',
      );
    }
  }
}
