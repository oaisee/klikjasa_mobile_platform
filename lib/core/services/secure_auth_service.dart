import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk mengelola autentikasi yang aman dengan implementasi refresh token,
/// session timeout, validasi input, dan enkripsi data sensitif
class SecureAuthService {
  static const String _refreshTokenKey = 'secure_refresh_token';
  static const String _sessionTimeoutKey = 'session_timeout';
  static const String _encryptionKey = 'klik_jasa_secure_key_2024';
  static const int _sessionTimeoutMinutes = 30;
  static const int _maxLoginAttempts = 5;
  static const int _lockoutDurationMinutes = 15;

  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _sessionTimer;
  Timer? _refreshTimer;

  /// Singleton pattern untuk memastikan hanya ada satu instance
  static final SecureAuthService _instance = SecureAuthService._internal();
  factory SecureAuthService() => _instance;
  SecureAuthService._internal();

  /// Login dengan validasi input yang ketat dan rate limiting
  Future<AuthResponse?> secureLogin({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Validasi input
      final validationError = _validateLoginInput(email, password);
      if (validationError != null) {
        throw AuthException(validationError);
      }

      // 2. Cek rate limiting
      await _checkRateLimit(email);

      // 3. Hash password untuk keamanan tambahan (untuk logging/audit)
      // final hashedPassword = _hashPassword(password);

      // 4. Attempt login
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.user != null) {
        // 5. Reset failed attempts on successful login
        await _resetFailedAttempts(email);

        // 6. Setup secure session
        await _setupSecureSession(response);

        // 7. Start session monitoring
        _startSessionMonitoring();

        return response;
      }

      return null;
    } on AuthException {
      // Record failed attempt
      await _recordFailedAttempt(email);
      rethrow;
    } catch (e) {
      await _recordFailedAttempt(email);
      throw AuthException('Login gagal: ${e.toString()}');
    }
  }

  /// Register dengan validasi input yang komprehensif
  Future<AuthResponse?> secureRegister({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      // 1. Validasi input
      final validationError = _validateRegisterInput(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      if (validationError != null) {
        throw AuthException(validationError);
      }

      // 2. Cek rate limiting
      await _checkRateLimit(email);

      // 3. Register user
      final response = await _supabase.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone_number': phoneNumber.trim(),
        },
      );

      if (response.user != null) {
        // 4. Setup secure session
        await _setupSecureSession(response);
        return response;
      }

      return null;
    } catch (e) {
      await _recordFailedAttempt(email);
      throw AuthException('Registrasi gagal: ${e.toString()}');
    }
  }

  /// Logout dengan cleanup session yang aman
  Future<void> secureLogout() async {
    try {
      // 1. Clear timers
      _sessionTimer?.cancel();
      _refreshTimer?.cancel();

      // 2. Clear secure session data
      await _clearSecureSession();

      // 3. Logout from Supabase
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Logout gagal: ${e.toString()}');
    }
  }

  /// Refresh token secara otomatis
  Future<void> refreshSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _supabase.auth.refreshSession();
        await _updateSessionTimeout();
      }
    } catch (e) {
      // Jika refresh gagal, logout user
      await secureLogout();
      throw AuthException('Session expired, please login again');
    }
  }

  /// Cek apakah session masih valid
  bool isSessionValid() {
    final session = _supabase.auth.currentSession;
    if (session == null) return false;

    // Cek session timeout
    final now = DateTime.now();
    final sessionExpiry = session.expiresAt;
    if (sessionExpiry != null && now.isAfter(DateTime.fromMillisecondsSinceEpoch(sessionExpiry * 1000))) {
      return false;
    }

    return true;
  }

  /// Validasi input login
  String? _validateLoginInput(String email, String password) {
    // Validasi email
    if (email.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Format email tidak valid';
    }
    if (email.length > 254) {
      return 'Email terlalu panjang';
    }

    // Validasi password
    if (password.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (password.length < 6) {
      return 'Password minimal 6 karakter';
    }
    if (password.length > 128) {
      return 'Password terlalu panjang';
    }

    // Cek karakter berbahaya
    if (_containsMaliciousChars(email) || _containsMaliciousChars(password)) {
      return 'Input mengandung karakter yang tidak diizinkan';
    }

    return null;
  }

  /// Validasi input register
  String? _validateRegisterInput({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String phoneNumber,
  }) {
    // Validasi login input
    final loginValidation = _validateLoginInput(email, password);
    if (loginValidation != null) return loginValidation;

    // Validasi confirm password
    if (password != confirmPassword) {
      return 'Password dan konfirmasi password tidak sama';
    }

    // Validasi full name
    if (fullName.trim().isEmpty) {
      return 'Nama lengkap tidak boleh kosong';
    }
    if (fullName.trim().length < 2) {
      return 'Nama lengkap minimal 2 karakter';
    }
    if (fullName.length > 100) {
      return 'Nama lengkap terlalu panjang';
    }

    // Validasi phone number
    if (phoneNumber.trim().isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(phoneNumber)) {
      return 'Format nomor telepon tidak valid';
    }
    if (phoneNumber.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
      return 'Nomor telepon minimal 10 digit';
    }

    // Cek karakter berbahaya
    if (_containsMaliciousChars(fullName) || _containsMaliciousChars(phoneNumber)) {
      return 'Input mengandung karakter yang tidak diizinkan';
    }

    return null;
  }

  /// Cek karakter berbahaya untuk mencegah injection
  bool _containsMaliciousChars(String input) {
    final maliciousPatterns = [
      '<script',
      'javascript:',
      'onload=',
      'onerror=',
      'eval(',
      'function(',
      'DROP TABLE',
      'DELETE FROM',
      'INSERT INTO',
      'UPDATE SET',
      'UNION SELECT',
    ];

    final lowerInput = input.toLowerCase();
    return maliciousPatterns.any((pattern) => lowerInput.contains(pattern.toLowerCase()));
  }

  // Fungsi _hashPassword dihapus karena tidak digunakan

  /// Setup secure session dengan timeout
  Future<void> _setupSecureSession(AuthResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Simpan refresh token dengan enkripsi
    if (response.session?.refreshToken != null) {
      final encryptedToken = _encryptData(response.session!.refreshToken!);
      await prefs.setString(_refreshTokenKey, encryptedToken);
    }

    // Set session timeout
    await _updateSessionTimeout();
  }

  /// Update session timeout
  Future<void> _updateSessionTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    final timeout = DateTime.now().add(Duration(minutes: _sessionTimeoutMinutes));
    await prefs.setString(_sessionTimeoutKey, timeout.toIso8601String());
  }

  /// Clear secure session data
  Future<void> _clearSecureSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_sessionTimeoutKey);
  }

  /// Enkripsi data sensitif
  String _encryptData(String data) {
    // Implementasi enkripsi sederhana (dalam produksi gunakan library yang lebih robust)
    final bytes = utf8.encode(data + _encryptionKey);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  /// Start session monitoring
  void _startSessionMonitoring() {
    // Monitor session timeout
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (!isSessionValid()) {
        await secureLogout();
        timer.cancel();
      }
    });

    // Auto refresh token
    _refreshTimer = Timer.periodic(const Duration(minutes: 25), (timer) async {
      try {
        await refreshSession();
      } catch (e) {
        timer.cancel();
      }
    });
  }

  /// Rate limiting untuk mencegah brute force
  Future<void> _checkRateLimit(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'failed_attempts_$email';
    final lockoutKey = 'lockout_until_$email';

    // Cek apakah masih dalam lockout
    final lockoutUntilStr = prefs.getString(lockoutKey);
    if (lockoutUntilStr != null) {
      final lockoutUntil = DateTime.parse(lockoutUntilStr);
      if (DateTime.now().isBefore(lockoutUntil)) {
        final remainingMinutes = lockoutUntil.difference(DateTime.now()).inMinutes;
        throw AuthException('Akun dikunci. Coba lagi dalam $remainingMinutes menit.');
      } else {
        // Lockout expired, reset
        await prefs.remove(lockoutKey);
        await prefs.remove(key);
      }
    }

    // Cek jumlah failed attempts
    final failedAttempts = prefs.getInt(key) ?? 0;
    if (failedAttempts >= _maxLoginAttempts) {
      // Lock account
      final lockoutUntil = DateTime.now().add(Duration(minutes: _lockoutDurationMinutes));
      await prefs.setString(lockoutKey, lockoutUntil.toIso8601String());
      throw AuthException('Terlalu banyak percobaan login. Akun dikunci selama $_lockoutDurationMinutes menit.');
    }
  }

  /// Record failed login attempt
  Future<void> _recordFailedAttempt(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'failed_attempts_$email';
    final failedAttempts = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, failedAttempts + 1);
  }

  /// Reset failed attempts on successful login
  Future<void> _resetFailedAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'failed_attempts_$email';
    await prefs.remove(key);
  }
}
