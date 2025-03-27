import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../platform/flutter_mcp_platform.dart';

/// Abstract base class for platform-specific background services
abstract class FlutterMcpBackgroundService {
  /// Register a background task with the given ID and callback
  Future<bool> register(String taskId, Function callback);
  
  /// Start the background service
  Future<bool> startService();
  
  /// Stop the background service
  Future<bool> stopService();
  
  /// Check if the background service is running
  Future<bool> isRunning();
  
  /// Schedule a periodic task to run at the specified interval
  Future<bool> schedulePeriodicTask(Duration interval, String taskId);
  
  /// Factory to create platform-specific background service implementation
  factory FlutterMcpBackgroundService() {
    final platform = FlutterMcpPlatform.instance;
    
    if (platform.isAndroid) {
      return _AndroidBackgroundService();
    } else if (platform.isIOS) {
      return _IOSBackgroundService();
    } else if (platform.isWeb) {
      throw UnsupportedError('Background services are not supported on Web platform');
    } else {
      return _DesktopBackgroundService();
    }
  }
}

/// Android implementation of background service
class _AndroidBackgroundService implements FlutterMcpBackgroundService {
  final _service = FlutterBackgroundService();
  final _registeredTasks = <String, Function>{};
  
  @override
  Future<bool> register(String taskId, Function callback) async {
    _registeredTasks[taskId] = callback;
    return true;
  }
  
  @override
  Future<bool> startService() async {
    final isRunning = await _service.isRunning();
    
    if (isRunning) {
      return true;
    }
    
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'flutter_mcp_notification',
        initialNotificationTitle: 'MCP Service',
        initialNotificationContent: 'Running in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
    
    return await _service.startService();
  }
  
  @override
  Future<bool> stopService() async {
    _service.invoke('stopService');
    return true;
  }
  
  @override
  Future<bool> isRunning() async {
    return await _service.isRunning();
  }
  
  @override
  Future<bool> schedulePeriodicTask(Duration interval, String taskId) async {
    _service.invoke('scheduleTask', {
      'taskId': taskId,
      'intervalInSeconds': interval.inSeconds,
    });
    return true;
  }
  
  // Background entry point for Android
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    
    service.on('executeTask').listen((event) {
      final taskId = event?['taskId'] as String?;
      
      if (taskId != null) {
        // Execute the task
        // For actual implementation, we need a way to access registered tasks
        // This is simplified for example purposes
      }
    });
    
    service.on('scheduleTask').listen((event) {
      final taskId = event?['taskId'] as String?;
      final intervalInSeconds = event?['intervalInSeconds'] as int?;
      
      if (taskId != null && intervalInSeconds != null) {
        // Schedule periodic task
        Timer.periodic(Duration(seconds: intervalInSeconds), (timer) {
          service.invoke('executeTask', {'taskId': taskId});
        });
      }
    });
  }
}

/// iOS background service implementation
class _IOSBackgroundService implements FlutterMcpBackgroundService {
  final _registeredTasks = <String, Function>{};
  final _methodChannel = const MethodChannel('flutter_mcp_common/background_service');
  
  @override
  Future<bool> register(String taskId, Function callback) async {
    _registeredTasks[taskId] = callback;
    
    try {
      return await _methodChannel.invokeMethod('registerBackgroundTask', {
        'taskId': taskId,
      });
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  @override
  Future<bool> startService() async {
    try {
      return await _methodChannel.invokeMethod('startBackgroundService');
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  @override
  Future<bool> stopService() async {
    try {
      return await _methodChannel.invokeMethod('stopBackgroundService');
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  @override
  Future<bool> isRunning() async {
    try {
      return await _methodChannel.invokeMethod('isBackgroundServiceRunning');
    } on PlatformException catch (_) {
      return false;
    }
  }
  
  @override
  Future<bool> schedulePeriodicTask(Duration interval, String taskId) async {
    try {
      return await _methodChannel.invokeMethod('schedulePeriodicTask', {
        'taskId': taskId,
        'intervalInSeconds': interval.inSeconds,
      });
    } on PlatformException catch (_) {
      return false;
    }
  }
}

// iOS background handler
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

/// Desktop background service implementation
class _DesktopBackgroundService implements FlutterMcpBackgroundService {
  final _registeredTasks = <String, Function>{};
  final _taskTimers = <String, Timer>{};
  bool _isRunning = false;
  
  @override
  Future<bool> register(String taskId, Function callback) async {
    _registeredTasks[taskId] = callback;
    return true;
  }
  
  @override
  Future<bool> startService() async {
    if (_isRunning) {
      return true;
    }
    
    _isRunning = true;
    return true;
  }
  
  @override
  Future<bool> stopService() async {
    if (!_isRunning) {
      return true;
    }
    
    // Cancel all timers
    for (final timer in _taskTimers.values) {
      timer.cancel();
    }
    _taskTimers.clear();
    
    _isRunning = false;
    return true;
  }
  
  @override
  Future<bool> isRunning() async {
    return _isRunning;
  }
  
  @override
  Future<bool> schedulePeriodicTask(Duration interval, String taskId) async {
    if (!_isRunning) {
      return false;
    }
    
    // Cancel existing timer for this task if any
    _taskTimers[taskId]?.cancel();
    
    // Create new timer
    _taskTimers[taskId] = Timer.periodic(interval, (_) {
      final callback = _registeredTasks[taskId];
      if (callback != null && callback is Function()) {
        callback();
      }
    });
    
    return true;
  }
}
