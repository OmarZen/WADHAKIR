import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:wadhakir/core/reading/reading_comfort.dart';
import 'app_lock_settings_model.dart';
import 'notification_settings_model.dart';

class AppSettingsModel extends Equatable {
  final ThemeMode themeMode;
  final String languageCode;
  final bool showBasmala;
  final NotificationSettingsModel notificationSettings;
  final AppLockSettingsModel appLockSettings;
  final bool onboardingCompleted;

  /// The user's first name, used to personalize the home greeting. Empty
  /// string means "not set" (default for fresh installs and existing users
  /// who haven't entered it yet).
  final String userName;

  /// User-chosen text scale, applied on top of the OS setting.
  ///
  /// 1.0 is the app's design size. Clamped to [minTextScale]..[maxTextScale] on
  /// read so a corrupt or hand-edited value can never render the UI unusable.
  /// PRODUCT.md names elder users who rely on large text as a primary audience;
  /// before this, nothing in 60k lines read `textScaler` at all.
  final double textScale;

  /// Bounds for [textScale]. The ceiling is deliberately below the OS maximum:
  /// past ~1.6 the fixed-height cards in this app start clipping, and clipped
  /// text is worse than small text.
  static const double minTextScale = 0.9;
  static const double maxTextScale = 1.6;

  /// Line spacing and font choice for reading surfaces — roadmap #24.
  ///
  /// Separate from [textScale] on purpose. Size shipped in R1 and applies to
  /// the whole app through the OS scaler; this applies only where somebody is
  /// reading rather than operating, and defaults to leaving every surface
  /// exactly as it renders today.
  final ReadingComfort readingComfort;

  const AppSettingsModel({
    required this.themeMode,
    required this.languageCode,
    required this.showBasmala,
    required this.notificationSettings,
    required this.appLockSettings,
    this.onboardingCompleted = false,
    this.userName = '',
    this.textScale = 1.0,
    this.readingComfort = ReadingComfort.defaults,
  });

  factory AppSettingsModel.defaultSettings() {
    return AppSettingsModel(
      themeMode: ThemeMode.light,
      languageCode: 'ar',
      showBasmala: true,
      notificationSettings: NotificationSettingsModel.defaultSettings(),
      appLockSettings: AppLockSettingsModel.defaultSettings(),
      onboardingCompleted: false,
      userName: '',
      textScale: 1.0,
      readingComfort: ReadingComfort.defaults,
    );
  }

  AppSettingsModel copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    bool? showBasmala,
    NotificationSettingsModel? notificationSettings,
    AppLockSettingsModel? appLockSettings,
    bool? onboardingCompleted,
    String? userName,
    double? textScale,
    ReadingComfort? readingComfort,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      showBasmala: showBasmala ?? this.showBasmala,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      appLockSettings: appLockSettings ?? this.appLockSettings,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      userName: userName ?? this.userName,
      textScale: textScale ?? this.textScale,
      readingComfort: readingComfort ?? this.readingComfort,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    languageCode,
    showBasmala,
    notificationSettings,
    appLockSettings,
    onboardingCompleted,
    userName,
    textScale,
    readingComfort,
  ];
}
