import 'package:klik_jasa/core/data/datasources/supabase_data_source.dart';
import 'package:klik_jasa/features/provider_mode/services/data/models/service_model.dart';
import 'service_provider_remote_data_source.dart';

/// Implementasi ServiceProviderRemoteDataSource menggunakan Supabase
/// 
/// Kelas ini mengimplementasikan operasi CRUD untuk layanan provider
/// menggunakan Supabase sebagai backend.
class SupabaseServiceProviderRemoteDataSource extends SupabaseDataSource implements ServiceProviderRemoteDataSource {
  final String _tableName = 'services';

  SupabaseServiceProviderRemoteDataSource({
    required super.supabaseClient,
  });

  @override
  Future<List<Map<String, dynamic>>> getProviderServices(String providerId) async {
    return handleSupabaseOperation(
      operation: () async {
        final response = await supabaseClient
            .from(_tableName)
            .select()
            .eq('provider_id', providerId)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      },
      context: 'Failed to get provider services',
    );
  }

  @override
  Future<Map<String, dynamic>> addService(ServiceModel serviceModel) async {
    return handleSupabaseOperation(
      operation: () async {
        final response = await supabaseClient
            .from(_tableName)
            .insert(serviceModel.toJson())
            .select()
            .single();

        return response;
      },
      context: 'Failed to add service',
    );
  }

  @override
  Future<Map<String, dynamic>> updateService(ServiceModel serviceModel) async {
    return handleSupabaseOperation(
      operation: () async {
        final response = await supabaseClient
            .from(_tableName)
            .update(serviceModel.toJson())
            .eq('id', serviceModel.id)
            .select()
            .single();

        return response;
      },
      context: 'Failed to update service',
    );
  }

  @override
  Future<void> deleteService(String serviceId) async {
    return handleSupabaseOperation(
      operation: () async {
        await supabaseClient
            .from(_tableName)
            .delete()
            .eq('id', serviceId);
      },
      context: 'Failed to delete service',
    );
  }

  @override
  Future<Map<String, dynamic>> getServiceDetail(String serviceId) async {
    return handleSupabaseOperation(
      operation: () async {
        final response = await supabaseClient
            .from(_tableName)
            .select('*, categories(name)')
            .eq('id', serviceId)
            .single();

        return response;
      },
      context: 'Failed to get service detail',
    );
  }

  @override
  Future<Map<String, dynamic>> updateServicePromotion({
    required String serviceId,
    required bool isPromoted,
    DateTime? promotionStartDate,
    DateTime? promotionEndDate,
  }) async {
    return handleSupabaseOperation(
      operation: () async {
        final updateData = <String, dynamic>{
          'is_promoted': isPromoted,
          'promotion_start_date': promotionStartDate?.toIso8601String(),
          'promotion_end_date': promotionEndDate?.toIso8601String(),
        };

        final response = await supabaseClient
            .from(_tableName)
            .update(updateData)
            .eq('id', serviceId)
            .select()
            .single();

        return response;
      },
      context: 'Failed to update service promotion',
    );
  }
}
