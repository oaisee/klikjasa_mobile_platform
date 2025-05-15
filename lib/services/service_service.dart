import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service.dart';

class ServiceService {
  final SupabaseClient _supabase;

  ServiceService(this._supabase);

  Future<List<Service>> getServices({
    String? search,
    List<String>? areaLayanan,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    var query = _supabase
        .from('services')
        .select('*, providers:provider_id(name, rating)');

    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }

    if (areaLayanan != null && areaLayanan.isNotEmpty) {
      query = query.overlaps('area_layanan', areaLayanan);
    }

    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }

    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }

    if (minRating != null) {
      query = query.gte('rating', minRating);
    }

    final response = await query.order('created_at');
    return (response as List).map((item) => Service.fromJson(item)).toList();
  }

  Future<Service> getServiceById(String id) async {
    final response = await _supabase
        .from('services')
        .select('*, providers:provider_id(name, rating)')
        .eq('id', id)
        .single();

    return Service.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Service>> getServicesByProvider(String providerId) async {
    final response = await _supabase
        .from('services')
        .select('*, providers:provider_id(name, rating)')
        .eq('provider_id', providerId)
        .order('created_at');

    return (response as List).map((item) => Service.fromJson(item)).toList();
  }

  Future<Service> createService(Map<String, dynamic> serviceData) async {
    final response = await _supabase
        .from('services')
        .insert(serviceData)
        .select('*, providers:provider_id(name, rating)')
        .single();

    return Service.fromJson(response as Map<String, dynamic>);
  }

  Future<Service> updateService(String id, Map<String, dynamic> serviceData) async {
    final response = await _supabase
        .from('services')
        .update(serviceData)
        .eq('id', id)
        .select('*, providers:provider_id(name, rating)')
        .single();

    return Service.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteService(String id) async {
    await _supabase.from('services').delete().eq('id', id);
  }
}
