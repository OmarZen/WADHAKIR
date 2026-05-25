import 'dart:convert';

/// Where the pill bar anchors itself on screen.
enum OverlayAnchor {
  topBar,
  bottomBar,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

extension OverlayAnchorX on OverlayAnchor {
  String get id => name;

  /// Decode a persisted anchor id. Corner anchors (`topLeft`, `topRight`,
  /// `bottomLeft`, `bottomRight`) are kept in the enum for compatibility
  /// with older saved settings but are no longer exposed in the picker —
  /// map them to the nearest top/bottom bar so the UI shows a real
  /// selection.
  static OverlayAnchor fromId(String? id) {
    switch (id) {
      case 'bottomBar':
      case 'bottomLeft':
      case 'bottomRight':
        return OverlayAnchor.bottomBar;
      case 'topBar':
      case 'topLeft':
      case 'topRight':
        return OverlayAnchor.topBar;
      default:
        return OverlayAnchor.topBar;
    }
  }
}

/// Which adhkar pool the overlay draws from.
enum DhikrSource { random, morning, evening, prayer, tasbih }

extension DhikrSourceX on DhikrSource {
  String get id => name;
  static DhikrSource fromId(String? id) => DhikrSource.values.firstWhere(
        (s) => s.name == id,
        orElse: () => DhikrSource.random,
      );
}

/// User preferences for the floating adhkar overlay. Persisted as JSON in
/// SharedPreferences under [FloatingDhikrSettings.prefsKey].
class FloatingDhikrSettings {
  static const String prefsKey = 'floating_dhikr_settings_v1';

  final bool enabled;
  final Duration interval;
  final OverlayAnchor position;
  final double opacity;
  final DhikrSource source;
  final Duration autoDismissAfter;
  final bool pauseDuringPrayer;
  final int? quietHoursStartMinutes; // minutes since midnight, null = off
  final int? quietHoursEndMinutes;

  const FloatingDhikrSettings({
    this.enabled = false,
    this.interval = const Duration(minutes: 10),
    this.position = OverlayAnchor.topBar,
    this.opacity = 0.92,
    this.source = DhikrSource.random,
    this.autoDismissAfter = const Duration(seconds: 10),
    this.pauseDuringPrayer = true,
    this.quietHoursStartMinutes = 23 * 60, // 23:00
    this.quietHoursEndMinutes = 5 * 60, // 05:00
  });

  FloatingDhikrSettings copyWith({
    bool? enabled,
    Duration? interval,
    OverlayAnchor? position,
    double? opacity,
    DhikrSource? source,
    Duration? autoDismissAfter,
    bool? pauseDuringPrayer,
    int? quietHoursStartMinutes,
    int? quietHoursEndMinutes,
    bool clearQuietHours = false,
  }) {
    return FloatingDhikrSettings(
      enabled: enabled ?? this.enabled,
      interval: interval ?? this.interval,
      position: position ?? this.position,
      opacity: opacity ?? this.opacity,
      source: source ?? this.source,
      autoDismissAfter: autoDismissAfter ?? this.autoDismissAfter,
      pauseDuringPrayer: pauseDuringPrayer ?? this.pauseDuringPrayer,
      quietHoursStartMinutes: clearQuietHours
          ? null
          : (quietHoursStartMinutes ?? this.quietHoursStartMinutes),
      quietHoursEndMinutes: clearQuietHours
          ? null
          : (quietHoursEndMinutes ?? this.quietHoursEndMinutes),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'interval_minutes': interval.inMinutes,
        'position': position.id,
        'opacity': opacity,
        'source': source.id,
        'auto_dismiss_seconds': autoDismissAfter.inSeconds,
        'pause_during_prayer': pauseDuringPrayer,
        'quiet_start_minutes': quietHoursStartMinutes,
        'quiet_end_minutes': quietHoursEndMinutes,
      };

  factory FloatingDhikrSettings.fromJson(Map<String, dynamic> json) {
    return FloatingDhikrSettings(
      enabled: json['enabled'] as bool? ?? false,
      interval: Duration(minutes: (json['interval_minutes'] as int?) ?? 10),
      position: OverlayAnchorX.fromId(json['position'] as String?),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.92,
      source: DhikrSourceX.fromId(json['source'] as String?),
      autoDismissAfter:
          Duration(seconds: (json['auto_dismiss_seconds'] as int?) ?? 10),
      pauseDuringPrayer: json['pause_during_prayer'] as bool? ?? true,
      quietHoursStartMinutes: json['quiet_start_minutes'] as int?,
      quietHoursEndMinutes: json['quiet_end_minutes'] as int?,
    );
  }

  String encode() => jsonEncode(toJson());

  static FloatingDhikrSettings decode(String raw) =>
      FloatingDhikrSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  /// Check whether the current local clock falls inside the configured quiet
  /// hours window. Handles overnight ranges (e.g. 23:00 → 05:00).
  bool isQuietNow(DateTime now) {
    final start = quietHoursStartMinutes;
    final end = quietHoursEndMinutes;
    if (start == null || end == null) return false;
    final m = now.hour * 60 + now.minute;
    if (start == end) return false;
    if (start < end) {
      return m >= start && m < end;
    }
    // Overnight window
    return m >= start || m < end;
  }
}
