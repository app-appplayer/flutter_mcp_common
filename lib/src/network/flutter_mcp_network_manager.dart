import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

import '../platform/flutter_mcp_platform.dart';

/// Network quality assessment
enum NetworkQuality {
  /// No connectivity available
  none,
  
  /// Poor network quality
  poor,
  
  /// Medium network quality
  medium,
  
  /// Good network quality
  good,
  
  /// Excellent network quality
  excellent
}

/// Manager for monitoring network connectivity and status
class FlutterMcpNetworkManager {
  static final FlutterMcpNetworkManager _instance = FlutterMcpNetworkManager._();
  
  /// Get singleton instance
  static FlutterMcpNetworkManager get instance => _instance;
  
  /// Connectivity instance for network monitoring
  final Connectivity _connectivity = Connectivity();
  
  /// Current connectivity result
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  
  /// Method channel for platform-specific methods
  static const MethodChannel _channel = MethodChannel('flutter_mcp_common/network');
  
  /// Stream controller for connectivity changes
  final _connectivityController = StreamController<ConnectivityResult>.broadcast();
  
  /// Private constructor
  FlutterMcpNetworkManager._() {
    _initConnectivity();
    _setupConnectivityStream();
  }
  
  /// Initialize connectivity with current status
  Future<void> _initConnectivity() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
      _connectivityController.add(_connectionStatus);
    } on PlatformException catch (_) {
      _connectionStatus = ConnectivityResult.none;
      _connectivityController.add(_connectionStatus);
    }
  }
  
  /// Set up stream for connectivity changes
  void _setupConnectivityStream() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _connectionStatus = result;
      _connectivityController.add(result);
    });
  }
  
  /// Check current connectivity
  Future<ConnectivityResult> checkConnectivity() async {
    try {
      return await _connectivity.checkConnectivity();
    } on PlatformException catch (_) {
      return ConnectivityResult.none;
    }
  }
  
  /// Stream of connectivity changes
  Stream<ConnectivityResult> get onConnectivityChanged => _connectivityController.stream;
  
  /// Returns true if currently on mobile network
  bool get isOnMobile => _connectionStatus == ConnectivityResult.mobile;
  
  /// Returns true if currently on WiFi network
  bool get isOnWifi => _connectionStatus == ConnectivityResult.wifi;
  
  /// Returns true if currently on wired ethernet
  bool get isOnEthernet => _connectionStatus == ConnectivityResult.ethernet;
  
  /// Returns true if any network connection is available
  bool get isConnected => _connectionStatus != ConnectivityResult.none;
  
  /// Returns true if on a metered connection (mobile)
  bool get isOnMeteredConnection => isOnMobile;
  
  /// Returns true if on an unmetered connection (WiFi, ethernet)
  bool get isOnUnmeteredConnection => isOnWifi || isOnEthernet;
  
  /// Measure network quality
  Future<NetworkQuality> measureNetworkQuality() async {
    if (!isConnected) {
      return NetworkQuality.none;
    }
    
    // Basic implementation based on connection type
    if (isOnEthernet) {
      return NetworkQuality.excellent;
    } else if (isOnWifi) {
      return NetworkQuality.good;
    } else if (isOnMobile) {
      // Try to determine mobile network quality
      try {
        return await _getMobileNetworkQuality();
      } catch (_) {
        return NetworkQuality.medium;
      }
    }
    
    return NetworkQuality.poor;
  }
  
  /// Check if device is in low-data mode (iOS) or data saver mode (Android)
  Future<bool> get isLowDataMode async {
    if (!FlutterMcpPlatform.instance.isAndroid && !FlutterMcpPlatform.instance.isIOS) {
      return false;
    }
    
    try {
      return await _channel.invokeMethod('isLowDataMode');
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  /// Check if device is in battery saver mode
  Future<bool> get isBatterySaverMode async {
    if (!FlutterMcpPlatform.instance.isAndroid && !FlutterMcpPlatform.instance.isIOS) {
      return false;
    }
    
    try {
      return await _channel.invokeMethod('isBatterySaverMode');
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  /// Check if server at URL is reachable
  Future<bool> isServerReachable(String url, {Duration timeout = const Duration(seconds: 5)}) async {
    if (!isConnected) {
      return false;
    }
    
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      client.connectionTimeout = timeout;
      
      final request = await client.getUrl(uri);
      final response = await request.close();
      
      await response.drain<void>();
      client.close();
      
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
  
  /// Get detailed mobile network quality information
  Future<NetworkQuality> _getMobileNetworkQuality() async {
    try {
      final quality = await _channel.invokeMethod<String>('getMobileNetworkType');
      
      switch (quality) {
        case '2g':
          return NetworkQuality.poor;
        case '3g':
          return NetworkQuality.medium;
        case '4g':
          return NetworkQuality.good;
        case '5g':
          return NetworkQuality.excellent;
        default:
          return NetworkQuality.medium;
      }
    } on PlatformException catch (_) {
      return NetworkQuality.medium;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _connectivityController.close();
  }
}
