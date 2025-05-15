import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegionModel {
  final String id;
  final String name;

  RegionModel({required this.id, required this.name});

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    return RegionModel(
      id: json['id'],
      name: json['name'],
    );
  }
}

class RegionService {
  static const String _baseUrl = 'https://www.emsifa.com/api-wilayah-indonesia/api';
  
  // Cache keys
  static const String _provincesKey = 'provinces_cache';
  static const String _citiesPrefixKey = 'cities_cache_';
  static const String _districtsPrefixKey = 'districts_cache_';
  static const String _villagesPrefixKey = 'villages_cache_';

  // Get all provinces
  static Future<List<RegionModel>> getProvinces() async {
    try {
      // Try to get from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_provincesKey);
      
      if (cachedData != null) {
        final List<dynamic> decodedData = json.decode(cachedData);
        final provinces = decodedData.map((item) => RegionModel.fromJson(item)).toList();
        
        // Sort alphabetically by name
        provinces.sort((a, b) => formatRegionName(a.name).compareTo(formatRegionName(b.name)));
        return provinces;
      }
      
      // If not in cache, fetch from API
      final response = await http.get(Uri.parse('$_baseUrl/provinces.json'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final provinces = data.map((json) => RegionModel.fromJson(json)).toList();
        
        // Sort alphabetically by name
        provinces.sort((a, b) => formatRegionName(a.name).compareTo(formatRegionName(b.name)));
        
        // Save to cache
        await prefs.setString(_provincesKey, response.body);
        
        return provinces;
      } else {
        debugPrint('Failed to load provinces: ${response.statusCode}');
        throw Exception('Failed to load provinces: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching provinces: $e');
      throw Exception('Failed to load provinces: $e');
    }
  }

  // Get cities/regencies by province ID
  static Future<List<RegionModel>> getCities(String provinceId) async {
    try {
      // Try to get from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_citiesPrefixKey$provinceId');
      
      if (cachedData != null) {
        final List<dynamic> decodedData = json.decode(cachedData);
        final cities = decodedData.map((item) => RegionModel.fromJson(item)).toList();
        
        // Sort alphabetically by formatted name (without 'Kabupaten' prefix)
        cities.sort((a, b) => formatRegionName(a.name).compareTo(formatRegionName(b.name)));
        return cities;
      }
      
      // If not in cache, fetch from API
      final response = await http.get(Uri.parse('$_baseUrl/regencies/$provinceId.json'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final cities = data.map((json) => RegionModel.fromJson(json)).toList();
        
        // Sort alphabetically by formatted name (without 'Kabupaten' prefix)
        cities.sort((a, b) => formatRegionName(a.name).compareTo(formatRegionName(b.name)));
        
        // Save to cache
        await prefs.setString('$_citiesPrefixKey$provinceId', response.body);
        
        return cities;
      } else {
        debugPrint('Failed to load cities: ${response.statusCode}');
        throw Exception('Failed to load cities: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching cities: $e');
      throw Exception('Failed to load cities: $e');
    }
  }

  // Get districts by city/regency ID
  static Future<List<RegionModel>> getDistricts(String cityId) async {
    try {
      // Try to get from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_districtsPrefixKey$cityId');
      
      if (cachedData != null) {
        final List<dynamic> decodedData = json.decode(cachedData);
        final districts = decodedData.map((item) => RegionModel.fromJson(item)).toList();
        
        // Sort alphabetically by name
        districts.sort((a, b) => formatRegionName(a.name).compareTo(formatRegionName(b.name)));
        return districts;
      }
      
      // If not in cache, fetch from API
      final response = await http.get(Uri.parse('$_baseUrl/districts/$cityId.json'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final districts = data.map((json) => RegionModel.fromJson(json)).toList();
        
        // Sort alphabetically by name
        districts.sort((a, b) => formatRegionName(a.name).compareTo(formatRegionName(b.name)));
        
        // Save to cache
        await prefs.setString('$_districtsPrefixKey$cityId', response.body);
        
        return districts;
      } else {
        debugPrint('Failed to load districts: ${response.statusCode}');
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching districts: $e');
      throw Exception('Failed to load districts: $e');
    }
  }

  // Get villages by district ID
  static Future<List<RegionModel>> getVillages(String districtId) async {
    try {
      // Try to get from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_villagesPrefixKey$districtId');
      
      if (cachedData != null) {
        final List<dynamic> decodedData = json.decode(cachedData);
        final villages = decodedData.map((item) => RegionModel.fromJson(item)).toList();
        
        // Sort alphabetically by name
        villages.sort((a, b) => formatRegionName(a.name).compareTo(formatRegionName(b.name)));
        return villages;
      }
      
      // If not in cache, fetch from API
      final response = await http.get(Uri.parse('$_baseUrl/villages/$districtId.json'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final villages = data.map((json) => RegionModel.fromJson(json)).toList();
        
        // Sort alphabetically by name
        villages.sort((a, b) => formatRegionName(a.name).compareTo(formatRegionName(b.name)));
        
        // Save to cache
        await prefs.setString('$_villagesPrefixKey$districtId', response.body);
        
        return villages;
      } else {
        debugPrint('Failed to load villages: ${response.statusCode}');
        throw Exception('Failed to load villages: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching villages: $e');
      throw Exception('Failed to load villages: $e');
    }
  }
  
  // Format region name to remove prefixes like "Kabupaten"
  static String formatRegionName(String name) {
    List<String> prefixesToRemove = [
      'KABUPATEN ', 
      'KAB. ',
      'KOTA ', 
      'KEC. ', 
      'KEL. ',
      'DESA '
    ];
    
    // Convert to title case first (from all caps)
    String titleCaseName = name.split(' ').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return '';
    }).join(' ');
    
    // Remove prefixes
    for (var prefix in prefixesToRemove) {
      String titleCasePrefix = prefix.split(' ').map((word) {
        if (word.isNotEmpty) {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }
        return '';
      }).join(' ');
      
      if (titleCaseName.startsWith(titleCasePrefix)) {
        return titleCaseName.substring(titleCasePrefix.length);
      }
    }
    
    return titleCaseName;
  }
  
  // Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_provincesKey);
      
      // Remove all cities, districts and villages caches
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_citiesPrefixKey) || 
            key.startsWith(_districtsPrefixKey) || 
            key.startsWith(_villagesPrefixKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
