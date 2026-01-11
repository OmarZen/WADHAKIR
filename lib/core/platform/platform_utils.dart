import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform utilities for handling platform-specific features
class PlatformUtils {
  /// Check if the app is running on mobile (Android/iOS)
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  /// Check if the app is running on desktop (Windows/macOS/Linux)
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Check if the app is running on Windows
  static bool get isWindows => Platform.isWindows;

  /// Check if the app is running on macOS
  static bool get isMacOS => Platform.isMacOS;

  /// Check if the app is running on Linux
  static bool get isLinux => Platform.isLinux;

  /// Check if the app is running on Android
  static bool get isAndroid => Platform.isAndroid;

  /// Check if the app is running on iOS
  static bool get isIOS => Platform.isIOS;

  /// Check if the app is running on web
  static bool get isWeb => kIsWeb;

  /// Check if a specific plugin/feature is supported on current platform
  static bool isFeatureSupported(String feature) {
    switch (feature) {
      case 'home_widget':
        // Home widget only works on mobile
        return isMobile;

      case 'background_location':
        // Background location works better on mobile
        return isMobile;

      case 'system_tray':
        // System tray is desktop-only
        return isDesktop;

      case 'window_management':
        // Window management is desktop-only
        return isDesktop;

      case 'native_notifications':
        // All platforms support notifications
        return true;

      case 'location_services':
        // All platforms support location
        return true;

      case 'audio_playback':
        // All platforms support audio
        return true;

      case 'file_picker':
        // All platforms support file picking
        return true;

      default:
        return false;
    }
  }

  /// Get platform-specific app data directory path
  static String getAppDataDirectory() {
    if (isWindows) {
      return '${Platform.environment['APPDATA']}\\WADHAKIR';
    } else if (isMacOS) {
      return '${Platform.environment['HOME']}/Library/Application Support/WADHAKIR';
    } else if (isLinux) {
      return '${Platform.environment['HOME']}/.local/share/wadhakir';
    } else {
      return ''; // Mobile uses path_provider
    }
  }

  /// Check if the app should use desktop layout
  static bool shouldUseDesktopLayout() {
    return isDesktop;
  }

  /// Check if the app should use mobile layout
  static bool shouldUseMobileLayout() {
    return isMobile;
  }

  /// Get platform name for logging/analytics
  static String get platformName {
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWeb) return 'Web';
    return 'Unknown';
  }

  /// Check if platform requires elevation for certain operations
  static bool get requiresElevation {
    // Windows might require admin for some operations
    return isWindows;
  }

  /// Get default window size for desktop
  static Size getDefaultWindowSize() {
    if (isDesktop) {
      return const Size(1200, 800);
    }
    return const Size(0, 0); // Not applicable for mobile
  }

  /// Get minimum window size for desktop
  static Size getMinimumWindowSize() {
    if (isDesktop) {
      return const Size(800, 600);
    }
    return const Size(0, 0); // Not applicable for mobile
  }
}

/// Size class for window dimensions
class Size {
  final double width;
  final double height;

  const Size(this.width, this.height);
}

/// Extension methods for platform-specific widget building
extension PlatformWidgetExtensions on Widget {
  /// Conditionally show widget only on mobile
  Widget showOnMobile() {
    return PlatformUtils.isMobile ? this : const SizedBox.shrink();
  }

  /// Conditionally show widget only on desktop
  Widget showOnDesktop() {
    return PlatformUtils.isDesktop ? this : const SizedBox.shrink();
  }

  /// Conditionally show widget only on Windows
  Widget showOnWindows() {
    return PlatformUtils.isWindows ? this : const SizedBox.shrink();
  }
}

class Widget {}

class SizedBox {
  const SizedBox.shrink();
}
