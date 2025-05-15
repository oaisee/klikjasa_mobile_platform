import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class StorageProvider extends ChangeNotifier {
  final StorageService _storageService;
  bool _isLoading = false;
  String? _error;

  StorageProvider(this._storageService);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<String> uploadKtpImage(
    File? imageFile, 
    Uint8List? imageBytes,
    String? imageName,
    String userId
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String imageUrl;
      
      if (kIsWeb && imageBytes != null) {
        // Web upload using bytes
        imageUrl = await _storageService.uploadKtpImageBytes(
          imageBytes, 
          imageName ?? 'ktp_$userId.jpg',
          userId
        );
      } else if (imageFile != null) {
        // Mobile upload using file
        imageUrl = await _storageService.uploadKtpImageFile(imageFile, userId);
      } else {
        throw Exception('No valid image data provided');
      }

      _isLoading = false;
      notifyListeners();

      return imageUrl;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final imageUrl = await _storageService.uploadProfileImageFile(imageFile, userId);

      _isLoading = false;
      notifyListeners();

      return imageUrl;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<String> uploadProfileImageBytes(Uint8List imageBytes, String fileName, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final imageUrl = await _storageService.uploadProfileImageBytes(imageBytes, fileName, userId);

      _isLoading = false;
      notifyListeners();

      return imageUrl;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> uploadServiceImage(File imageFile, String serviceId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final imageUrl = await _storageService.uploadServiceImage(imageFile, serviceId);

      _isLoading = false;
      notifyListeners();

      return imageUrl;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
