import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  Future<void> init() async {
    // Initial check
    final results = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(results);

    // Listen to changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    bool hasNetwork = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    if (!hasNetwork) {
      _isConnected = false;
    } else {
      // Step 2: Verification with actual reachability (as per v2.1 requirement)
      _isConnected = await _checkRealReachability();
    }
    
    debugPrint('ConnectivityService: isConnected = $_isConnected');
  }

  Future<bool> _checkRealReachability() async {
    if (kIsWeb) {
      // On web, direct socket lookup is not supported.
      // We rely on the browser's network status provided by connectivity_plus.
      return true;
    }

    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      // Catch all exceptions on non-web to be safe
      return false;
    }
  }

  /// Manually trigger a reachability check
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    await _updateConnectionStatus(results);
    return _isConnected;
  }
}
