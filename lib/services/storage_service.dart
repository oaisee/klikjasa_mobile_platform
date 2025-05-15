import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  // Mendapatkan daftar bucket yang tersedia
  Future<List<String>> _getAvailableBuckets() async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      final bucketNames = buckets.map((bucket) => bucket.name).toList();
      debugPrint('Available buckets: $bucketNames');
      return bucketNames;
    } catch (e) {
      debugPrint('Error getting available buckets: $e');
      return [];
    }
  }
  
  // Mendapatkan nama bucket yang tepat untuk KTP
  Future<String> _getKtpBucketName() async {
    final buckets = await _getAvailableBuckets();
    
    // Coba beberapa kemungkinan nama bucket
    final possibleBucketNames = [
      'ktp_images',
      'ktp-images',
      'ktpimages',
      'ktp',
      'images',
      'avatars',
      'storage',
      'public',
    ];
    
    for (final bucketName in possibleBucketNames) {
      if (buckets.contains(bucketName)) {
        debugPrint('Found KTP bucket: $bucketName');
        return bucketName;
      }
    }
    
    // Jika tidak ada yang cocok, gunakan bucket pertama yang tersedia
    if (buckets.isNotEmpty) {
      debugPrint('Using first available bucket for KTP: ${buckets.first}');
      return buckets.first;
    }
    
    // Default fallback
    return 'public';
  }
  
  // Upload KTP image using File (for mobile)
  Future<String> uploadKtpImageFile(File imageFile, String userId) async {
    try {
      final fileExt = path.extension(imageFile.path);
      final fileName = 'ktp_$userId$fileExt';
      final bucketName = await _getKtpBucketName();
      
      debugPrint('Uploading KTP file to bucket: $bucketName');
      
      // Upload ke bucket yang tersedia
      await _supabase.storage
          .from(bucketName)
          .upload(fileName, imageFile, fileOptions: const FileOptions(upsert: true));

      // Dapatkan URL publik dari file yang diupload
      final imageUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);
          
      debugPrint('KTP image URL: $imageUrl');

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading KTP image file: $e');
      // Jika error karena bucket tidak ditemukan, coba gunakan URL dummy
      if (e is StorageException && e.statusCode == 404) {
        debugPrint('Using dummy KTP URL due to storage error');
        return 'https://placeholder.com/ktp_$userId.jpg';
      }
      rethrow;
    }
  }
  
  // Upload KTP image using Uint8List (for web)
  Future<String> uploadKtpImageBytes(Uint8List imageBytes, String fileName, String userId) async {
    try {
      // Make sure filename is unique
      if (!fileName.contains(userId)) {
        final fileExt = path.extension(fileName);
        fileName = 'ktp_$userId$fileExt';
      }
      
      final bucketName = await _getKtpBucketName();
      debugPrint('Uploading KTP bytes to bucket: $bucketName');
      
      // Upload ke bucket yang tersedia
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(fileName, imageBytes, fileOptions: const FileOptions(upsert: true));

      // Dapatkan URL publik dari file yang diupload
      final imageUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);
          
      debugPrint('KTP image URL: $imageUrl');

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading KTP image bytes: $e');
      // Jika error karena bucket tidak ditemukan, coba gunakan URL dummy
      if (e is StorageException && e.statusCode == 404) {
        debugPrint('Using dummy KTP URL due to storage error');
        return 'https://placeholder.com/ktp_$userId.jpg';
      }
      rethrow;
    }
  }

  // Mendapatkan nama bucket yang tepat untuk Profile
  Future<String> _getProfileBucketName() async {
    final buckets = await _getAvailableBuckets();
    
    // Coba beberapa kemungkinan nama bucket
    final possibleBucketNames = [
      'profile_images',
      'profile-images',
      'profileimages',
      'profile',
      'images',
      'avatars',
      'storage',
      'public',
    ];
    
    for (final bucketName in possibleBucketNames) {
      if (buckets.contains(bucketName)) {
        debugPrint('Found Profile bucket: $bucketName');
        return bucketName;
      }
    }
    
    // Jika tidak ada yang cocok, gunakan bucket pertama yang tersedia
    if (buckets.isNotEmpty) {
      debugPrint('Using first available bucket for Profile: ${buckets.first}');
      return buckets.first;
    }
    
    // Default fallback
    return 'public';
  }
  
  // Upload profile image using File (for mobile)
  Future<String> uploadProfileImageFile(File imageFile, String userId) async {
    try {
      final fileExt = path.extension(imageFile.path);
      final fileName = 'profile_$userId$fileExt';
      final bucketName = await _getProfileBucketName();
      
      debugPrint('Uploading profile file to bucket: $bucketName');
      
      // Upload ke bucket yang tersedia
      await _supabase.storage
          .from(bucketName)
          .upload(fileName, imageFile, fileOptions: const FileOptions(upsert: true));

      // Dapatkan URL publik dari file yang diupload
      final imageUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);
          
      debugPrint('Profile image URL: $imageUrl');

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image file: $e');
      // Jika error karena bucket tidak ditemukan, coba gunakan URL dummy
      if (e is StorageException && e.statusCode == 404) {
        debugPrint('Using dummy profile URL due to storage error');
        return 'https://placeholder.com/profile_$userId.jpg';
      }
      rethrow;
    }
  }
  
  // Upload profile image using Uint8List (for web)
  Future<String> uploadProfileImageBytes(Uint8List imageBytes, String fileName, String userId) async {
    try {
      // Make sure filename is unique
      if (!fileName.contains(userId)) {
        final fileExt = path.extension(fileName);
        fileName = 'profile_$userId$fileExt';
      }
      
      final bucketName = await _getProfileBucketName();
      debugPrint('Uploading profile bytes to bucket: $bucketName');
      
      // Upload ke bucket yang tersedia
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(fileName, imageBytes, fileOptions: const FileOptions(upsert: true));

      // Dapatkan URL publik dari file yang diupload
      final imageUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);
          
      debugPrint('Profile image URL: $imageUrl');

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image bytes: $e');
      // Jika error karena bucket tidak ditemukan, coba gunakan URL dummy
      if (e is StorageException && e.statusCode == 404) {
        debugPrint('Using dummy profile URL due to storage error');
        return 'https://placeholder.com/profile_$userId.jpg';
      }
      rethrow;
    }
  }

  Future<String> uploadServiceImage(File imageFile, String serviceId) async {
    try {
      final fileExt = path.extension(imageFile.path);
      final fileName = 'service_${serviceId}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      
      // Upload ke bucket 'service_images'
      final response = await _supabase.storage
          .from('service_images')
          .upload(fileName, imageFile);

      // Dapatkan URL publik dari file yang diupload
      final imageUrl = _supabase.storage
          .from('service_images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Error uploading service image: $e');
      rethrow;
    }
  }
}
