import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:klik_jasa/core/network/network_info.dart';

/// Implementasi NetworkInfo untuk memeriksa koneksi internet
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity = Connectivity();

  /// Memeriksa apakah perangkat terhubung ke internet
  @override
  Future<bool> get isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}
