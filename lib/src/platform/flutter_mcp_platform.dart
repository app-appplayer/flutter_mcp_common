import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform detection and capability abstraction for Flutter MCP
///
/// This class provides a consistent way to detect the current platform
/// and determine available capabilities across different platforms.
class FlutterMcpPlatform {
  static FlutterMcpPlatform get instance => _instance;
  static final FlutterMcpPlatform _instance = _createPlatformInstance();

  /// Factory method to create the appropriate platform instance
  static FlutterMcpPlatform _createPlatformInstance() {
    return FlutterMcpPlatform._();
  }

  FlutterMcpPlatform._();

  /// Returns true if running on Android platform
  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Returns true if running on iOS platform
  bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Returns true if running on web platform
  bool get isWeb => kIsWeb;

  /// Returns true if running on desktop platform (Windows, macOS, Linux)
  bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Returns true if running on Windows desktop platform
  bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Returns true if running on macOS desktop platform
  bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Returns true if running on Linux desktop platform
  bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Returns true if the platform supports background execution
  bool get supportsBackgroundExecution {
    if (kIsWeb) return false;
    if (Platform.isAndroid || Platform.isIOS) return true;
    return false; // Desktop platforms don't support traditional background execution
  }

  /// Returns true if the platform supports system notifications
  bool get supportsNotifications {
    if (kIsWeb) {
      // Web notifications require permission & are not fully supported
      return false;
    }
    // All native platforms support notifications
    return true;
  }

  /// Returns true if running in debug mode
  bool get isDebugMode => kDebugMode;

  /// Returns true if running in release mode
  bool get isReleaseMode => kReleaseMode;

  /// Returns true if running in profile mode
  bool get isProfileMode => kProfileMode;

  /// Returns true if filesystem access is available
  bool get hasFileSystemAccess => !kIsWeb;

  /// Returns true if persistent storage is available
  bool get hasPersistentStorage => true;

  /// Returns true if secure storage is available
  bool get hasSecureStorage => true;

  /// Returns true if platform allows foreground services
  bool get supportsForegroundServices => isAndroid;

  /// Returns true if platform allows background fetch
  bool get supportsBackgroundFetch => isIOS;

  /// Initialize platform-specific configurations
  Future<void> initialize() async {
    // Perform platform-specific initializations if needed
  }
}
