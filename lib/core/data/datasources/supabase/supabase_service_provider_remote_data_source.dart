import 'package:klik_jasa/core/data/datasources/supabase_data_source.dart';
import 'package:klik_jasa/features/provider_mode/services/data/datasources/service_provider_remote_data_source.dart';
import 'package:klik_jasa/features/provider_mode/services/data/models/service_model.dart';

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
      context: 'mengambil layanan provider',
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
      context: 'menambahkan layanan',
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
      context: 'memperbarui layanan',
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
      context: 'menghapus layanan',
    );
  }

  @override
  Future<Map<String, dynamic>> getServiceDetail(String serviceId) async {
    return handleSupabaseOperation(
      operation: () async {
        final response = await supabaseClient
            .from(_tableName)
            .select()
            .eq('id', serviceId)
            .single();

        return response;
      },
      context: 'mengambil detail layanan',
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
      context: 'memperbarui promosi layanan',
    );
  }
}
