import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AppUser? _user;
  bool _isLoading = false;

  AuthProvider(this._authService) {
    _initializeUser();
  }

  AppUser? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    _user = await _authService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _authService.signIn(email: email, password: password);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUp({required String name, required String email, required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _authService.signUp(name: name, email: email, password: password);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _user = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (_user == null) {
      throw Exception('User tidak ditemukan');
    }

    try {
      _isLoading = true;
      notifyListeners();

      _user = await _authService.updateProfile(
        userId: _user!.id,
        name: name,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registerAsProvider({required String phoneNumber, required String address, String? ktpImageUrl}) async {
    if (_user == null) {
      throw Exception('User tidak ditemukan');
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _authService.registerAsProvider(
        userId: _user!.id,
        phoneNumber: phoneNumber,
        address: address,
        ktpImageUrl: ktpImageUrl,
      );

      // Update user role to pending_provider
      _user = await _authService.updateProfile(
        userId: _user!.id,
        name: _user!.name,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
