import 'package:flutter/material.dart';

/// Windows-specific configuration and constants
class WindowsConfig {
  // Window Management
  static const String appTitle = 'WADHAKIR - واذكر';
  static const Size defaultWindowSize = Size(1200, 800);
  static const Size minWindowSize = Size(800, 600);
  static const Size maxWindowSize = Size(1920, 1080);

  // System Tray
  static const String trayIconPath = 'assets/icons/tray_icon.ico';
  static const String trayTooltip = 'WADHAKIR';

  // Notifications
  static const String notificationAppId = 'com.wadhakir.desktop';
  static const Duration notificationDuration = Duration(seconds: 10);
  static const bool enableNotificationSound = true;

  // Storage
  static const String databaseName = 'wadhakir_windows.db';
  static const String settingsFileName = 'settings.json';
  static const String cacheDirectoryName = 'cache';
  static const String logsDirectoryName = 'logs';

  // Performance
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxLogFiles = 10;
  static const Duration backgroundSyncInterval = Duration(minutes: 15);

  // UI Constants
  static const double sidebarWidth = 280;
  static const double sidebarCollapsedWidth = 60;
  static const double titleBarHeight = 32;
  static const double statusBarHeight = 24;

  // Keyboard Shortcuts
  static const Map<String, String> keyboardShortcuts = {
    'Ctrl+N': 'New Prayer Time',
    'Ctrl+S': 'Settings',
    'Ctrl+Q': 'Quit',
    'Ctrl+M': 'Minimize to Tray',
    'Ctrl+R': 'Refresh',
    'Ctrl+,': 'Preferences',
    'F11': 'Fullscreen',
    'Esc': 'Close Dialog',
  };

  // Window States
  static const String windowStatePersistenceKey = 'window_state';

  // Features
  static const bool enableSystemTray = true;
  static const bool enableStartupOnBoot = true;
  static const bool enableAutoUpdate = true;
  static const bool enableCrashReporting = true;

  // URLs
  static const String updateCheckUrl =
      'https://api.github.com/repos/OmarZen/WADHAKIR/releases/latest';
  static const String websiteUrl = 'https://wadhakir.app';
  static const String supportUrl = 'https://github.com/OmarZen/WADHAKIR/issues';

  // Plugin Configuration
  static const Map<String, bool> pluginSupport = {
    'home_widget': false, // Not supported on Windows
    'background_location': false, // Limited on Windows
    'system_tray': true,
    'window_management': true,
    'native_notifications': true,
    'location_services': true,
    'audio_playback': true,
    'file_picker': true,
  };

  // Audio Configuration
  static const double defaultVolume = 0.8;
  static const bool enableAudioFade = true;
  static const Duration audioFadeDuration = Duration(milliseconds: 500);

  // Location Services
  static const Duration locationUpdateInterval = Duration(minutes: 30);
  static const double locationAccuracyThreshold = 1000.0; // meters

  // Prayer Times
  static const Duration prayerNotificationBefore = Duration(minutes: 15);
  static const Duration prayerNotificationRepeat = Duration(minutes: 5);

  // Theme
  static const bool useSystemTheme = true;
  static const bool enableAnimations = true;
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Debug
  static const bool debugMode = false;
  static const bool verboseLogging = false;
  static const bool showPerformanceOverlay = false;
}

/// Windows-specific feature flags
class WindowsFeatures {
  static bool get isSystemTraySupported => true;
  static bool get isWindowManagementSupported => true;
  static bool get isStartupOnBootSupported => true;
  static bool get isAutoUpdateSupported => true;
  static bool get isNativeNotificationsSupported => true;
  static bool get isHomeWidgetSupported => false;
  static bool get isBackgroundLocationSupported => false;
}
