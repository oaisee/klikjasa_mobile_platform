import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/service_service.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceService _serviceService;
  List<Service> _services = [];
  bool _isLoading = false;
  String? _error;

  ServiceProvider(this._serviceService) {
    loadServices();
  }

  List<Service> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadServices({
    String? search,
    List<String>? areaLayanan,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _services = await _serviceService.getServices(
        search: search,
        areaLayanan: areaLayanan,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Service?> getServiceById(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final service = await _serviceService.getServiceById(id);
      
      _isLoading = false;
      notifyListeners();
      return service;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Service>> getServicesByProvider(String providerId) async {
    try {
      return await _serviceService.getServicesByProvider(providerId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<Service?> createService(Map<String, dynamic> serviceData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final service = await _serviceService.createService(serviceData);

      // Refresh services list
      await loadServices();

      _isLoading = false;
      notifyListeners();

      return service;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Service?> updateService(String id, Map<String, dynamic> serviceData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final service = await _serviceService.updateService(id, serviceData);

      if (service != null) {
        // Update service in list
        final index = _services.indexWhere((s) => s.id == id);
        if (index != -1) {
          _services[index] = service;
        }
      }

      _isLoading = false;
      notifyListeners();

      return service;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteService(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _serviceService.deleteService(id);

      if (success) {
        // Remove service from list
        _services.removeWhere((service) => service.id == id);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
