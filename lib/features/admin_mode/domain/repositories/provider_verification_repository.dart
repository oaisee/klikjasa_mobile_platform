import 'package:klik_jasa/features/admin_mode/domain/entities/user_profile.dart';

abstract class ProviderVerificationRepository {
  Future<List<UserProfile>> getPendingProviderVerifications();
  Future<void> updateProviderVerificationStatus(String userId, String newStatus);
}
