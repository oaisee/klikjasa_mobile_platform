import 'package:connectivity_plus/connectivity_plus.dart';

/// Class untuk memeriksa koneksi internet
class NetworkInfo {
  final Connectivity _connectivity = Connectivity();

  /// Memeriksa apakah perangkat terhubung ke internet
  Future<bool> get isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}
