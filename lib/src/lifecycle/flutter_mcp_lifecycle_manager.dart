import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/flutter_mcp_platform.dart';

/// App resource usage mode based on app lifecycle
enum AppResourceMode {
  /// Full resource usage when app is in active use
  full,
  
  /// Reduced resource usage when app is in background but needs some functionality
  reduced,
  
  /// Minimal resource usage when app is in background and only essential tasks needed
  minimal,
  
  /// Suspended resource usage when app is fully inactive
  suspended
}

/// Manager for Flutter app lifecycle to coordinate MCP operations
class FlutterMcpLifecycleManager with WidgetsBindingObserver {
  static final FlutterMcpLifecycleManager _instance = FlutterMcpLifecycleManager._();
  
  /// Get singleton instance
  static FlutterMcpLifecycleManager get instance => _instance;
  
  /// Current app lifecycle state
  AppLifecycleState _currentState = AppLifecycleState.resumed;
  
  /// Stream controller for lifecycle state changes
  final _stateController = StreamController<AppLifecycleState>.broadcast();
  
  /// Resource mode controller
  final _resourceModeController = StreamController<AppResourceMode>.broadcast();
  
  /// Current resource mode
  AppResourceMode _resourceMode = AppResourceMode.full;
  
  FlutterMcpLifecycleManager._() {
    WidgetsBinding.instance.addObserver(this);
  }
  
  /// Get current lifecycle state
  AppLifecycleState get currentState => _currentState;
  
  /// Stream of lifecycle state changes
  Stream<AppLifecycleState> get lifecycleStateStream => _stateController.stream;
  
  /// Current resource usage mode
  AppResourceMode get resourceMode => _resourceMode;
  
  /// Stream of resource mode changes
  Stream<AppResourceMode> get resourceModeStream => _resourceModeController.stream;
  
  /// Returns true if app is currently in background
  bool get isInBackground => 
      _currentState == AppLifecycleState.paused || 
      _currentState == AppLifecycleState.detached || 
      _currentState == AppLifecycleState.hidden;
  
  /// Returns true if app is currently in foreground and active
  bool get isInForeground => _currentState == AppLifecycleState.resumed;
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentState = state;
    _stateController.add(state);
    
    // Update resource mode based on lifecycle state
    switch (state) {
      case AppLifecycleState.resumed:
        _setResourceMode(AppResourceMode.full);
        break;
      case AppLifecycleState.inactive:
        _setResourceMode(AppResourceMode.reduced);
        break;
      case AppLifecycleState.paused:
        _setResourceMode(AppResourceMode.minimal);
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _setResourceMode(AppResourceMode.suspended);
        break;
    }
  }
  
  /// Set the resource mode manually
  void setResourceMode(AppResourceMode mode) {
    _setResourceMode(mode);
  }
  
  void _setResourceMode(AppResourceMode mode) {
    if (_resourceMode != mode) {
      _resourceMode = mode;
      _resourceModeController.add(mode);
    }
  }
  
  /// Request battery optimization exemption (Android only)
  Future<bool> requestBatteryOptimizationExemption() async {
    if (!FlutterMcpPlatform.instance.isAndroid) {
      return false;
    }
    
    try {
      const platform = MethodChannel('flutter_mcp_common/battery_optimization');
      return await platform.invokeMethod('requestBatteryOptimizationExemption');
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  /// Enable background execution for the app
  Future<bool> enableBackgroundExecution() async {
    final platform = FlutterMcpPlatform.instance;
    
    if (!platform.supportsBackgroundExecution) {
      return false;
    }
    
    if (platform.isAndroid) {
      return _enableAndroidBackgroundExecution();
    } else if (platform.isIOS) {
      return _enableIOSBackgroundExecution();
    }
    
    return false;
  }
  
  Future<bool> _enableAndroidBackgroundExecution() async {
    try {
      const platform = MethodChannel('flutter_mcp_common/background_execution');
      return await platform.invokeMethod('enableBackgroundExecution');
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  Future<bool> _enableIOSBackgroundExecution() async {
    try {
      const platform = MethodChannel('flutter_mcp_common/background_execution');
      return await platform.invokeMethod('enableBackgroundExecution');
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  /// Clean up resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateController.close();
    _resourceModeController.close();
  }
}
