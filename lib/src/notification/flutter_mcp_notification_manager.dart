import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../platform/flutter_mcp_platform.dart';

/// Manager for cross-platform notification capabilities
class FlutterMcpNotificationManager {
  static final FlutterMcpNotificationManager _instance = FlutterMcpNotificationManager._();
  
  /// Get singleton instance
  static FlutterMcpNotificationManager get instance => _instance;
  
  /// Local notifications plugin
  final _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  /// Channel for tapped notification payload
  final _selectNotificationController = StreamController<String?>.broadcast();
  
  /// Stream of notification taps
  Stream<String?> get onNotificationTapped => _selectNotificationController.stream;
  
  /// Whether notifications have been initialized
  bool _initialized = false;
  
  /// Private constructor
  FlutterMcpNotificationManager._();
  
  /// Initialize notification systems
  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }
    
    if (!_isPlatformSupported()) {
      _initialized = false;
      return false;
    }
    
    try {
      // Initialize settings for each platform
      final initSettings = InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
        ),
        macOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        linux: const LinuxInitializationSettings(
          defaultActionName: 'Open',
        ),
      );
      
      // Initialize the plugin
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );
      
      _initialized = true;
      return true;
    } catch (e) {
      _initialized = false;
      return false;
    }
  }
  
  /// Request permission to show notifications
  Future<bool> requestPermission() async {
    if (!_isPlatformSupported()) {
      return false;
    }
    
    if (!_initialized) {
      await initialize();
    }
    
    try {
      if (FlutterMcpPlatform.instance.isIOS || FlutterMcpPlatform.instance.isMacOS) {
        final settings = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return settings ?? false;
      } else if (FlutterMcpPlatform.instance.isAndroid) {
        final granted = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestPermission();
        return granted ?? false;
      }
      
      return true; // Other platforms don't need permission
    } catch (e) {
      return false;
    }
  }
  
  /// Check if app has notification permission
  Future<bool> checkPermission() async {
    if (!_isPlatformSupported()) {
      return false;
    }
    
    try {
      if (FlutterMcpPlatform.instance.isAndroid) {
        final plugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await plugin?.areNotificationsEnabled() ?? false;
      }
      
      // For iOS, permission check requires platform channel
      if (FlutterMcpPlatform.instance.isIOS) {
        const channel = MethodChannel('flutter_mcp_common/notifications');
        return await channel.invokeMethod('checkNotificationPermission');
      }
      
      return true; // Default to true for other platforms
    } catch (e) {
      return false;
    }
  }
  
  /// Create a notification channel (Android only)
  Future<void> createChannel(String id, String name, String description, {
    int importance = 3, // NotificationImportance.DEFAULT
    bool enableVibration = true,
    bool enableLights = true,
  }) async {
    if (!FlutterMcpPlatform.instance.isAndroid) {
      return;
    }
    
    if (!_initialized) {
      await initialize();
    }
    
    final androidNotificationChannel = AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: Importance.values[importance.clamp(0, 5)],
      enableVibration: enableVibration,
      enableLights: enableLights,
    );
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }
  
  /// Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
    int id = 0,
    int importance = 3, // NotificationImportance.DEFAULT
  }) async {
    if (!_isPlatformSupported()) {
      return;
    }
    
    if (!_initialized) {
      await initialize();
    }
    
    // Create notification details for each platform
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      'MCP Notifications',
      channelDescription: 'MCP notification channel',
      importance: Importance.values[importance.clamp(0, 5)],
      priority: Priority.high,
    );
    
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
  
  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    if (!_isPlatformSupported() || !_initialized) {
      return;
    }
    
    await _notificationsPlugin.cancelAll();
  }
  
  /// Clear a specific notification
  Future<void> clearNotification(int id) async {
    if (!_isPlatformSupported() || !_initialized) {
      return;
    }
    
    await _notificationsPlugin.cancel(id);
  }
  
  /// Handle local notifications for iOS (deprecated but needed for older iOS versions)
  Future<void> _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    _selectNotificationController.add(payload);
  }
  
  /// Handle notification response for newer versions
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _selectNotificationController.add(response.payload);
  }
  
  /// Check if platform supports notifications
  bool _isPlatformSupported() {
    if (kIsWeb) {
      return false; // Web notifications not supported by flutter_local_notifications
    }
    
    return Platform.isAndroid || 
           Platform.isIOS || 
           Platform.isMacOS || 
           Platform.isLinux;
  }
  
  /// Dispose resources
  void dispose() {
    _selectNotificationController.close();
  }
}
