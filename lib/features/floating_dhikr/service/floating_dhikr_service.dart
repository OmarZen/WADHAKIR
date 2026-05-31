import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../data/floating_dhikr_settings.dart';
import '../data/floating_dhikr_repository.dart';

const String _logName = 'FloatingDhikrService';

/// Coordinates the floating adhkar overlay. The actual ticker + overlay
/// drawing now live in a NATIVE Android foreground service
/// ([FloatingDhikrService.kt]) so the pill keeps appearing even when the app
/// is backgrounded or killed. This Dart singleton resolves the dhikr pool +
/// settings and drives the native service over a MethodChannel. Overlay
/// (SYSTEM_ALERT_WINDOW) permission is still checked via flutter_overlay_window.
class FloatingDhikrService {
  FloatingDhikrService._();
  static final FloatingDhikrService instance = FloatingDhikrService._();

  static const MethodChannel _channel = MethodChannel(
    'com.bloom.wadhakir/floating_dhikr',
  );

  final FloatingDhikrRepository _repo = FloatingDhikrRepository();
  FloatingDhikrSettings _settings = const FloatingDhikrSettings();
  List<String>? _dhikrPool;
  DhikrSource? _loadedPoolSource;

  /// iOS doesn't permit drawing over other apps.
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<FloatingDhikrSettings> getSettings() async {
    _settings = await _repo.load();
    return _settings;
  }

  /// Persist new settings and (re)start or stop the native service.
  Future<void> updateSettings(FloatingDhikrSettings s) async {
    _settings = s;
    if (_loadedPoolSource != s.source) {
      _dhikrPool = null;
      _loadedPoolSource = null;
    }
    await _repo.save(s);
    if (s.enabled && isSupported && await hasPermission()) {
      await _startNative();
    } else {
      await _stopNative();
    }
  }

  /// True if SYSTEM_ALERT_WINDOW (display over other apps) is granted — the
  /// same permission the native overlay needs.
  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      dev.log('hasPermission error: $e', name: _logName);
      return false;
    }
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      final granted = await FlutterOverlayWindow.requestPermission();
      return granted == true;
    } catch (e) {
      dev.log('requestPermission error: $e', name: _logName);
      return false;
    }
  }

  /// On app start, (re)start the native service if the user enabled it. The
  /// native service also auto-restarts on boot via BootReceiver, but this
  /// covers config refreshes and the case where it was stopped.
  Future<void> bootstrap() async {
    final s = await getSettings();
    if (!s.enabled || !isSupported) return;
    if (!await hasPermission()) {
      dev.log('bootstrap: enabled but no overlay permission', name: _logName);
      return;
    }
    await _startNative();
  }

  /// Force one immediate emission (the "test now" preview in settings).
  Future<FloatingDhikrEmitResult> emitOnce() async {
    if (!isSupported) return FloatingDhikrEmitResult.unsupported;
    if (!await hasPermission()) {
      return FloatingDhikrEmitResult.missingPermission;
    }
    final config = await _buildConfig();
    if ((config['dhikr'] as List).isEmpty) {
      return FloatingDhikrEmitResult.noContent;
    }
    try {
      await _channel.invokeMethod('emitNow', config);
      return FloatingDhikrEmitResult.ok;
    } catch (e) {
      dev.log('emitOnce error: $e', name: _logName);
      return FloatingDhikrEmitResult.platformError;
    }
  }

  /// Stop the native service (used when the user toggles the feature off).
  Future<void> closeOverlay() async => _stopNative();

  Future<void> _startNative() async {
    try {
      await _channel.invokeMethod('start', await _buildConfig());
      dev.log('native floating dhikr started', name: _logName);
    } catch (e) {
      dev.log('_startNative error: $e', name: _logName);
    }
  }

  Future<void> _stopNative() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      dev.log('_stopNative error: $e', name: _logName);
    }
  }

  /// Build the config map handed to the native service. Includes the resolved
  /// dhikr pool so native can cycle through it without reading Flutter assets.
  Future<Map<String, dynamic>> _buildConfig() async {
    final pool = await _resolvePool();
    return {
      'dhikr': pool,
      'intervalMinutes': _settings.interval.inMinutes,
      'dismissSeconds': _settings.autoDismissAfter.inSeconds,
      'anchor': _settings.position.id,
      'opacity': _settings.opacity,
      'isDark': false,
      'quietStart': _settings.quietHoursStartMinutes ?? -1,
      'quietEnd': _settings.quietHoursEndMinutes ?? -1,
    };
  }

  Future<List<String>> _resolvePool() async {
    if (_dhikrPool == null || _loadedPoolSource != _settings.source) {
      _dhikrPool = await _loadPool();
      _loadedPoolSource = _settings.source;
    }
    return _dhikrPool ?? const [];
  }

  Future<List<String>> _loadPool() async {
    try {
      final assetPath = _assetForSource(_settings.source);
      final raw = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(raw);
      final out = <String>[];
      void collect(dynamic node) {
        if (node is List) {
          for (final e in node) {
            collect(e);
          }
        } else if (node is Map) {
          if (node['text'] is String) {
            final text = node['text'] as String;
            // Skip very long entries — the pill can't display them gracefully.
            if (text.isNotEmpty && text.length < 220) out.add(text);
          }
          for (final v in node.values) {
            if (v is List || v is Map) collect(v);
          }
        }
      }

      collect(decoded);
      if (out.isEmpty) return _defaultDhikrPool;
      return out;
    } catch (e) {
      dev.log('_loadPool fallback (asset error: $e)', name: _logName);
      return _defaultDhikrPool;
    }
  }

  String _assetForSource(DhikrSource s) {
    switch (s) {
      case DhikrSource.prayer:
        return 'assets/json_data/pray_azkar.json';
      case DhikrSource.tasbih:
        return 'assets/json_data/tassbih.json';
      case DhikrSource.morning:
      case DhikrSource.evening:
      case DhikrSource.random:
        return 'assets/json_data/adhkar.json';
    }
  }

  static const List<String> _defaultDhikrPool = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
  ];
}

/// Outcome of an emission attempt — surfaced to the UI so we can show the
/// right error message instead of silently doing nothing.
enum FloatingDhikrEmitResult {
  ok,
  unsupported,
  missingPermission,
  noContent,
  platformError,
}
