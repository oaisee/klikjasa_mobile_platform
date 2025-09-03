import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'network_info.dart';

/// Implementasi konkret dari NetworkInfo
/// 
/// Kelas ini menggunakan connectivity_plus untuk memeriksa koneksi internet
/// dan melakukan ping test untuk memastikan koneksi benar-benar tersedia
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl({required this.connectivity});

  @override
  Future<bool> get isConnected async {
    try {
      // Cek status konektivitas
      final connectivityResult = await connectivity.checkConnectivity();
      
      // Jika tidak ada koneksi sama sekali
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // Lakukan ping test untuk memastikan koneksi internet benar-benar tersedia
      return await _hasInternetConnection();
    } catch (e) {
      return false;
    }
  }

  /// Melakukan ping test ke server yang reliable untuk memastikan koneksi internet
  Future<bool> _hasInternetConnection() async {
    try {
      // Ping ke Google DNS dengan timeout 5 detik
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Stream untuk mendengarkan perubahan status koneksi
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.asyncMap((_) async {
      return await isConnected;
    });
  }

  /// Mendapatkan jenis koneksi saat ini
  Future<List<ConnectivityResult>> get connectionType async {
    return await connectivity.checkConnectivity();
  }

  /// Mendapatkan informasi detail tentang koneksi
  Future<Map<String, dynamic>> get connectionInfo async {
    final connectivityResult = await connectivity.checkConnectivity();
    final hasInternet = await isConnected;
    
    return {
      'type': connectivityResult.toString(),
      'hasInternet': hasInternet,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
