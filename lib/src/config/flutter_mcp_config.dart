import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global configuration for Flutter MCP packages
class FlutterMcpConfig {
  /// Default connection timeout (in seconds)
  static const int defaultConnectionTimeoutSeconds = 30;
  
  /// Default reconnect interval (in seconds)
  static const int defaultReconnectIntervalSeconds = 5;
  
  /// Default maximum concurrent operations
  static const int defaultMaxConcurrentOperations = 3;
  
  /// Default maximum memory usage (in MB)
  static const int defaultMaxMemoryUsageMB = 128;

  /// Connection timeout duration
  Duration connectionTimeout;
  
  /// Interval between reconnection attempts
  Duration reconnectInterval;
  
  /// Whether to enable detailed logging
  bool enableLogging;
  
  /// Log level for the application
  Level logLevel;
  
  /// Maximum number of concurrent operations
  int maxConcurrentOperations;
  
  /// Maximum memory usage in MB
  int maxMemoryUsageMB;
  
  /// Android-specific settings
  Map<String, dynamic> androidSettings;
  
  /// iOS-specific settings
  Map<String, dynamic> iosSettings;
  
  /// Web-specific settings
  Map<String, dynamic> webSettings;
  
  /// Desktop-specific settings
  Map<String, dynamic> desktopSettings;
  
  /// Create a new configuration with specified or default values
  FlutterMcpConfig({
    Duration? connectionTimeout,
    Duration? reconnectInterval,
    this.enableLogging = true,
    this.logLevel = Level.info,
    this.maxConcurrentOperations = defaultMaxConcurrentOperations,
    this.maxMemoryUsageMB = defaultMaxMemoryUsageMB,
    Map<String, dynamic>? androidSettings,
    Map<String, dynamic>? iosSettings,
    Map<String, dynamic>? webSettings,
    Map<String, dynamic>? desktopSettings,
  }) : 
    connectionTimeout = connectionTimeout ?? const Duration(seconds: defaultConnectionTimeoutSeconds),
    reconnectInterval = reconnectInterval ?? const Duration(seconds: defaultReconnectIntervalSeconds),
    androidSettings = androidSettings ?? _defaultAndroidSettings(),
    iosSettings = iosSettings ?? _defaultIOSSettings(),
    webSettings = webSettings ?? _defaultWebSettings(),
    desktopSettings = desktopSettings ?? _defaultDesktopSettings();
  
  /// Create configuration with default values
  factory FlutterMcpConfig.defaults() {
    return FlutterMcpConfig();
  }
  
  /// Load configuration from shared preferences
  static Future<FlutterMcpConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('flutter_mcp_config');
    
    if (configJson == null) {
      return FlutterMcpConfig.defaults();
    }
    
    try {
      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      return FlutterMcpConfig.fromJson(configMap);
    } catch (e) {
      // If config is corrupted, return defaults
      return FlutterMcpConfig.defaults();
    }
  }
  
  /// Save configuration to shared preferences
  Future<bool> save() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString('flutter_mcp_config', jsonEncode(toJson()));
  }
  
  /// Convert configuration to JSON map
  Map<String, dynamic> toJson() {
    return {
      'connectionTimeoutSeconds': connectionTimeout.inSeconds,
      'reconnectIntervalSeconds': reconnectInterval.inSeconds,
      'enableLogging': enableLogging,
      'logLevel': logLevel.index,
      'maxConcurrentOperations': maxConcurrentOperations,
      'maxMemoryUsageMB': maxMemoryUsageMB,
      'androidSettings': androidSettings,
      'iosSettings': iosSettings,
      'webSettings': webSettings,
      'desktopSettings': desktopSettings,
    };
  }
  
  /// Create configuration from JSON map
  factory FlutterMcpConfig.fromJson(Map<String, dynamic> json) {
    return FlutterMcpConfig(
      connectionTimeout: Duration(seconds: json['connectionTimeoutSeconds'] ?? defaultConnectionTimeoutSeconds),
      reconnectInterval: Duration(seconds: json['reconnectIntervalSeconds'] ?? defaultReconnectIntervalSeconds),
      enableLogging: json['enableLogging'] ?? true,
      logLevel: _levelFromIndex(json['logLevel']),
      maxConcurrentOperations: json['maxConcurrentOperations'] ?? defaultMaxConcurrentOperations,
      maxMemoryUsageMB: json['maxMemoryUsageMB'] ?? defaultMaxMemoryUsageMB,
      androidSettings: json['androidSettings'] ?? _defaultAndroidSettings(),
      iosSettings: json['iosSettings'] ?? _defaultIOSSettings(),
      webSettings: json['webSettings'] ?? _defaultWebSettings(),
      desktopSettings: json['desktopSettings'] ?? _defaultDesktopSettings(),
    );
  }
  
  /// Create a copy of this configuration with specified fields replaced
  FlutterMcpConfig copyWith({
    Duration? connectionTimeout,
    Duration? reconnectInterval,
    bool? enableLogging,
    Level? logLevel,
    int? maxConcurrentOperations,
    int? maxMemoryUsageMB,
    Map<String, dynamic>? androidSettings,
    Map<String, dynamic>? iosSettings,
    Map<String, dynamic>? webSettings,
    Map<String, dynamic>? desktopSettings,
  }) {
    return FlutterMcpConfig(
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      reconnectInterval: reconnectInterval ?? this.reconnectInterval,
      enableLogging: enableLogging ?? this.enableLogging,
      logLevel: logLevel ?? this.logLevel,
      maxConcurrentOperations: maxConcurrentOperations ?? this.maxConcurrentOperations,
      maxMemoryUsageMB: maxMemoryUsageMB ?? this.maxMemoryUsageMB,
      androidSettings: androidSettings ?? Map<String, dynamic>.from(this.androidSettings),
      iosSettings: iosSettings ?? Map<String, dynamic>.from(this.iosSettings),
      webSettings: webSettings ?? Map<String, dynamic>.from(this.webSettings),
      desktopSettings: desktopSettings ?? Map<String, dynamic>.from(this.desktopSettings),
    );
  }
  
  /// Default Android settings
  static Map<String, dynamic> _defaultAndroidSettings() {
    return {
      'useForegroundService': true,
      'foregroundServiceNotificationTitle': 'MCP Service',
      'foregroundServiceNotificationText': 'Running in background',
      'foregroundServiceNotificationImportance': 3, // NotificationImportance.DEFAULT
      'requestBatteryOptimizationExemption': true,
      'useWorkManager': true,
      'workManagerMinUpdateIntervalMinutes': 15,
    };
  }
  
  /// Default iOS settings
  static Map<String, dynamic> _defaultIOSSettings() {
    return {
      'backgroundModes': ['fetch', 'processing'],
      'minBackgroundFetchInterval': 900, // 15 minutes in seconds
      'usesBackgroundTasks': true,
      'backgroundTaskIdentifier': 'com.fluttermcp.backgroundRefresh',
    };
  }
  
  /// Default web settings
  static Map<String, dynamic> _defaultWebSettings() {
    return {
      'useServiceWorkers': true,
      'useIndexedDb': true,
      'serviceCacheVersion': '1.0.0',
      'maxCacheSize': 50, // In MB
    };
  }
  
  /// Default desktop settings
  static Map<String, dynamic> _defaultDesktopSettings() {
    return {
      'minimizeToSystemTray': true,
      'startOnSystemStartup': false,
      'useNativeNotifications': true,
    };
  }
  
  /// Convert index to log level
  static Level _levelFromIndex(int? index) {
    switch (index) {
      case 0: return Level.trace;
      case 1: return Level.debug;
      case 2: return Level.info;
      case 3: return Level.warning;
      case 4: return Level.error;
      case 5: return Level.fatal;
      default: return Level.info;
    }
  }
}
