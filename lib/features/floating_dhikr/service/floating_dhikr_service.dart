import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../data/floating_dhikr_settings.dart';
import '../data/floating_dhikr_repository.dart';

const String _logName = 'FloatingDhikrService';

/// Coordinates the floating adhkar overlay: permission, scheduling, content
/// pick, and emission. Designed as a singleton so any caller can start/stop
/// the feature without juggling state.
class FloatingDhikrService {
  FloatingDhikrService._();
  static final FloatingDhikrService instance = FloatingDhikrService._();

  final FloatingDhikrRepository _repo = FloatingDhikrRepository();
  Timer? _ticker;
  FloatingDhikrSettings _settings = const FloatingDhikrSettings();
  List<String>? _dhikrPool;
  DhikrSource? _loadedPoolSource;

  /// iOS doesn't permit drawing over other apps. The feature should hide
  /// or disable itself there.
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Read current settings. Cached after first read.
  Future<FloatingDhikrSettings> getSettings() async {
    _settings = await _repo.load();
    dev.log(
      'getSettings → enabled=${_settings.enabled} interval=${_settings.interval.inMinutes}m '
      'position=${_settings.position.name} source=${_settings.source.name}',
      name: _logName,
    );
    return _settings;
  }

  /// Persist new settings and re-apply (start/stop ticker as needed).
  Future<void> updateSettings(FloatingDhikrSettings s) async {
    _settings = s;
    if (_loadedPoolSource != s.source) {
      // Invalidate pool so we re-load from the right asset.
      _dhikrPool = null;
      _loadedPoolSource = null;
    }
    await _repo.save(s);
    if (s.enabled && isSupported) {
      await _startTicker();
    } else {
      await _stopTicker();
    }
  }

  /// True if the user has already granted SYSTEM_ALERT_WINDOW.
  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      final granted = await FlutterOverlayWindow.isPermissionGranted();
      dev.log('hasPermission → $granted', name: _logName);
      return granted;
    } catch (e) {
      dev.log('hasPermission error: $e', name: _logName);
      return false;
    }
  }

  /// Open the system permission screen. Returns true if granted.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      final granted = await FlutterOverlayWindow.requestPermission();
      dev.log('requestPermission → $granted', name: _logName);
      return granted == true;
    } catch (e) {
      dev.log('requestPermission error: $e', name: _logName);
      return false;
    }
  }

  /// Boot at app start: if the user previously enabled the feature, resume
  /// the ticker (assuming permission is still granted).
  Future<void> bootstrap() async {
    final s = await getSettings();
    if (!s.enabled || !isSupported) return;
    if (!await hasPermission()) {
      dev.log('bootstrap: enabled but no permission yet', name: _logName);
      return;
    }
    await _startTicker();
  }

  Future<void> _startTicker() async {
    _ticker?.cancel();
    final interval = _settings.interval;
    // Defensive: don't schedule absurdly short intervals.
    final clamped = interval < const Duration(minutes: 1)
        ? const Duration(minutes: 5)
        : interval;
    dev.log(
      '_startTicker: every ${clamped.inMinutes} minute(s)',
      name: _logName,
    );
    _ticker = Timer.periodic(clamped, (_) => _maybeEmit());
  }

  Future<void> _stopTicker() async {
    _ticker?.cancel();
    _ticker = null;
    try {
      // Cap the await — `closeOverlay()` has been observed to hang on
      // some OEM builds (no overlay active, or service mid-teardown). The
      // caller (updateSettings) used to block here, freezing the settings
      // page until the user closed the screen.
      await FlutterOverlayWindow.closeOverlay()
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      dev.log('_stopTicker: closeOverlay error/timeout: $e', name: _logName);
    }
  }

  Future<void> _maybeEmit() async {
    if (!_settings.enabled) return;
    if (!isSupported) return;
    if (_settings.isQuietNow(DateTime.now())) {
      dev.log('_maybeEmit: in quiet hours, skipping', name: _logName);
      return;
    }
    final granted = await hasPermission();
    if (!granted) {
      dev.log('_maybeEmit: no overlay permission, skipping', name: _logName);
      return;
    }
    await emitOnce();
  }

  /// Force an immediate emission (used for "test now" preview in settings).
  /// Returns a status describing what happened so the UI can surface failures
  /// (no permission, iOS, dhikr load failure, etc).
  Future<FloatingDhikrEmitResult> emitOnce() async {
    dev.log('emitOnce: requested', name: _logName);
    if (!isSupported) {
      dev.log('emitOnce: unsupported platform', name: _logName);
      return FloatingDhikrEmitResult.unsupported;
    }
    if (!await hasPermission()) {
      dev.log('emitOnce: missing overlay permission', name: _logName);
      return FloatingDhikrEmitResult.missingPermission;
    }
    final dhikr = await _pickDhikr();
    if (dhikr == null) {
      dev.log('emitOnce: no dhikr available', name: _logName);
      return FloatingDhikrEmitResult.noContent;
    }
    try {
      // Always tear down any existing overlay before showing a fresh one.
      // Sharing data into a still-alive overlay reuses the old position and
      // can leave the pill bar in a stale spot (or behind the app's window).
      // A clean close+reopen guarantees the user sees the current settings.
      final already = await FlutterOverlayWindow.isActive();
      dev.log('emitOnce: overlay already active = $already', name: _logName);
      if (already) {
        await FlutterOverlayWindow.closeOverlay();
        // Give Android a frame to release the previous window before we
        // create the new one.
        await Future.delayed(const Duration(milliseconds: 250));
      }

      final height = _heightFor(_settings.position);
      final alignment = _alignmentFor(_settings.position);
      dev.log(
        'emitOnce: showOverlay height=$height alignment=${alignment.name}',
        name: _logName,
      );
      await FlutterOverlayWindow.showOverlay(
        height: height,
        width: WindowSize.matchParent,
        alignment: alignment,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        overlayTitle: 'Wadhakir',
        overlayContent: 'Floating dhikr reminder',
        enableDrag: true,
      );

      // Give the overlay engine a moment to spin up, then hand it the text.
      // Without a small delay shareData() can race the entry point before
      // its overlayListener is set up.
      await Future.delayed(const Duration(milliseconds: 400));
      await _shareContent(dhikr);

      // Auto-dismiss after the configured duration.
      Future.delayed(_settings.autoDismissAfter, () async {
        try {
          await FlutterOverlayWindow.closeOverlay();
          dev.log('emitOnce: auto-dismissed', name: _logName);
        } catch (e) {
          dev.log('emitOnce auto-dismiss error: $e', name: _logName);
        }
      });
      return FloatingDhikrEmitResult.ok;
    } on PlatformException catch (e) {
      dev.log(
        'emitOnce PlatformException: code=${e.code} message=${e.message}',
        name: _logName,
      );
      return FloatingDhikrEmitResult.platformError;
    } catch (e, st) {
      dev.log('emitOnce error: $e\n$st', name: _logName);
      return FloatingDhikrEmitResult.platformError;
    }
  }

  /// Explicitly close any open overlay. Used by the settings page when the
  /// user toggles the feature off.
  Future<void> closeOverlay() async {
    if (!isSupported) return;
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      dev.log('closeOverlay error: $e', name: _logName);
    }
  }

  Future<void> _shareContent(String dhikr) async {
    // Include the anchor so the overlay engine can pick the right
    // Alignment + edge padding (top anchors render near the top, bottom
    // anchors render near the bottom — without this the pill always sat
    // at the top of the overlay window).
    final payload = jsonEncode({
      'text': dhikr,
      'opacity': _settings.opacity,
      'anchor': _settings.position.id,
    });
    try {
      await FlutterOverlayWindow.shareData(payload);
      dev.log('shareData: sent ${dhikr.length} chars', name: _logName);
    } catch (e) {
      dev.log('shareData error: $e', name: _logName);
    }
  }

  /// Pick a dhikr string from the configured source. Lazily loads the pool
  /// from the bundled JSON. Falls back to a handful of safe defaults if the
  /// asset isn't loadable.
  Future<String?> _pickDhikr() async {
    if (_dhikrPool == null || _loadedPoolSource != _settings.source) {
      _dhikrPool = await _loadPool();
      _loadedPoolSource = _settings.source;
    }
    final pool = _dhikrPool;
    if (pool == null || pool.isEmpty) return null;
    final rand = math.Random();
    return pool[rand.nextInt(pool.length)];
  }

  Future<List<String>> _loadPool() async {
    try {
      final assetPath = _assetForSource(_settings.source);
      dev.log('_loadPool: loading $assetPath', name: _logName);
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
            if (text.isNotEmpty && text.length < 220) {
              // Skip very long entries — the pill bar can't display them
              // gracefully even with ellipsis.
              out.add(text);
            }
          }
          for (final v in node.values) {
            if (v is List || v is Map) collect(v);
          }
        }
      }

      collect(decoded);
      dev.log('_loadPool: collected ${out.length} entries', name: _logName);
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

  /// `flutter_overlay_window.showOverlay()` treats the `height` argument as
  /// raw physical pixels, NOT density-independent dp — checked against the
  /// plugin's `OverlayService.java` which builds `WindowManager.LayoutParams`
  /// directly from these ints with no DP conversion. On a high-DPI phone
  /// (xxhdpi = 3x, xxxhdpi = 4x) a value of 140 px is only ~47/35 dp tall —
  /// barely visible behind the status bar. We compute the physical pixel
  /// count from a sensible dp target multiplied by the device pixel ratio
  /// so the pill bar is always readable.
  int _heightFor(OverlayAnchor p) {
    final view = WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
        ? WidgetsBinding.instance.platformDispatcher.views.first
        : null;
    final dpr = view?.devicePixelRatio ?? 5;
    final dpHeight = _heightDpFor(p);
    final px = (dpHeight * dpr).toInt();
    dev.log(
      '_heightFor: dp=$dpHeight dpr=$dpr -> px=$px',
      name: _logName,
    );
    return px;
  }

  int _heightDpFor(OverlayAnchor p) {
    // Bigger than the pill itself so the in-overlay padding (which clears
    // status bar / gesture indicator) has room. Pill is ~74dp tall + up to
    // 2 lines of larger text; with the new 100dp edge clearance + 12dp on
    // the other side we need at least ~250dp. Slack added for multi-line.
    switch (p) {
      case OverlayAnchor.topBar:
      case OverlayAnchor.bottomBar:
        return 400;
      case OverlayAnchor.topLeft:
      case OverlayAnchor.topRight:
      case OverlayAnchor.bottomLeft:
      case OverlayAnchor.bottomRight:
        return 400;
    }
  }

  OverlayAlignment _alignmentFor(OverlayAnchor p) {
    switch (p) {
      case OverlayAnchor.topBar:
        return OverlayAlignment.topCenter;
      case OverlayAnchor.bottomBar:
        return OverlayAlignment.bottomCenter;
      case OverlayAnchor.topLeft:
        return OverlayAlignment.topLeft;
      case OverlayAnchor.topRight:
        return OverlayAlignment.topRight;
      case OverlayAnchor.bottomLeft:
        return OverlayAlignment.bottomLeft;
      case OverlayAnchor.bottomRight:
        return OverlayAlignment.bottomRight;
    }
  }

  /// Hard-coded fallback adhkar used only if asset loading fails. These are
  /// short, well-known phrases that fit a slim pill bar.
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
