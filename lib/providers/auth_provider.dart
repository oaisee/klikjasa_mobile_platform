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
}
