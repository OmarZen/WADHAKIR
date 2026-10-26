import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/campus/services/qibla_ar_camera_service.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';

/// Builds a layer in the camera preview's own frame: [frame] is the unscaled
/// preview size, and the layer is scaled and cropped together with the
/// picture, so anything drawn in it stays on the same pixels of the floor.
typedef QiblaArFrameBuilder = Widget Function(BuildContext context, Size frame);

/// AR Qibla mode: the live camera preview with a guide drawn over it.
///
/// It runs in two ways:
/// * **Embedded** (`embedded: true`), as the Qibla screen's AR tab. The host
///   passes the overlays and callbacks, pads the top of the [MediaQuery] by
///   its tab strip so nothing covers the notice, and is told through
///   [onArActiveChanged] when the preview is live.
/// * **Route** (the defaults), pushed on its own with a back bar. Without
///   overlays it is just the notice and the preview.
///
/// This screen never reads the qibla cubit: not in `initState`, not in
/// `dispose`, not in the notice or the fallbacks. The safety test pumps it
/// with no cubit at all, and a cubit read in `dispose` would also run while
/// the host is tearing down. Everything cubit-shaped arrives through the
/// constructor; the overlays (which may read it) are built only once the
/// camera is live.
///
/// ## The safety notice comes first
///
/// Google Play treats this screen as Augmented Reality, and because the app's
/// audience includes children the Families policy requires a safety warning
/// the moment the AR section starts — one that stresses parental supervision
/// and awareness of your surroundings. Version code 23 was rejected for not
/// having one.
///
/// So the screen opens on that notice, every time, and nothing touches the
/// camera — not the permission prompt, not the preview — until the user taps
/// through it. It is deliberately not a "don't show again" dialog: the child
/// holding the phone today may not be the adult who dismissed it last week.
class QiblaArScreen extends StatefulWidget {
  /// Resolves the camera. Injectable so a test can prove it is never called
  /// before the safety notice is acknowledged.
  final Future<QiblaArCameraResult> Function() prepareCamera;

  /// Hosted as a tab: no back bar of its own (the host has the header and the
  /// tab strip), and [onExit] instead of popping a route.
  final bool embedded;

  /// «العودة للبوصلة» / «استخدم البوصلة بدلًا من ذلك». Null pops the route.
  final VoidCallback? onExit;

  /// True once the preview is live; false when the camera is released while
  /// this screen stays mounted (the app went to the background). Never
  /// called from `dispose`: a host switching tabs stands AR down itself.
  final ValueChanged<bool>? onArActiveChanged;

  /// Drawn inside the preview's frame (see [QiblaArFrameBuilder]), e.g. the
  /// prayer rug. Built only while the camera is live.
  final QiblaArFrameBuilder? previewOverlayBuilder;

  /// Drawn over the preview in screen space, inside the safe area: guidance,
  /// the steady step, the result panel. Built only while the camera is live.
  final WidgetBuilder? overlayBuilder;

  const QiblaArScreen({
    super.key,
    this.prepareCamera = QiblaArCameraService.prepare,
    this.embedded = false,
    this.onExit,
    this.onArActiveChanged,
    this.previewOverlayBuilder,
    this.overlayBuilder,
  });

  @override
  State<QiblaArScreen> createState() => _QiblaArScreenState();
}

class _QiblaArScreenState extends State<QiblaArScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  QiblaArAvailability _status = QiblaArAvailability.ready;
  bool _initializing = false;

  /// False until the user taps through the safety notice. The camera is not
  /// prepared — so its permission is not even requested — before then.
  bool _acknowledged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // AR overlay math assumes portrait; lock while this screen is visible.
    _mounted++;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  /// AR views alive right now. Leaving AR and coming straight back
  /// cross-fades two of them, and the old one's dispose must not unlock
  /// the orientation the new one has just locked.
  static int _mounted = 0;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _mounted--;
    if (_mounted == 0) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nothing to release or restart until the safety notice is accepted.
    if (!_acknowledged) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Release the camera while backgrounded to avoid leaks/locks — through
      // setState, so no preview of a disposed controller is left on screen.
      final controller = _controller;
      if (controller == null) return;
      setState(() => _controller = null);
      controller.dispose();
      widget.onArActiveChanged?.call(false);
    } else if (state == AppLifecycleState.resumed) {
      // Restart a camera released above, or look again after the user was
      // sent to system settings. Never after a plain denial: that would put
      // the system prompt up on every resume — and the prompt itself makes the
      // app inactive and then resumed, so it would never stop asking.
      final worthRetrying =
          _status == QiblaArAvailability.ready ||
          _status == QiblaArAvailability.permissionPermanentlyDenied;
      if (_controller == null && !_initializing && worthRetrying) {
        _initCamera();
      }
    }
  }

  void _acknowledgeSafetyNotice() {
    setState(() => _acknowledged = true);
    _initCamera();
  }

  void _exit() {
    final onExit = widget.onExit;
    if (onExit != null) {
      onExit();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _initCamera() async {
    // One attempt at a time: a second would build a second controller and
    // overwrite the first without disposing it.
    if (_initializing) return;
    if (mounted) setState(() => _initializing = true);
    final QiblaArCameraResult result;
    try {
      result = await widget.prepareCamera();
    } catch (_) {
      // A permission request already running, or a camera service error.
      // Uncaught, `_initializing` stayed true and the spinner never stopped.
      if (!mounted) return;
      setState(() {
        _status = QiblaArAvailability.noCamera;
        _initializing = false;
      });
      return;
    }
    if (!mounted) return;

    if (result.status != QiblaArAvailability.ready || result.camera == null) {
      setState(() {
        _status = result.status;
        _initializing = false;
      });
      return;
    }

    final controller = CameraController(
      result.camera!,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
    } catch (_) {
      // initialize() allocates the platform camera before it can throw.
      controller.dispose();
      if (!mounted) return;
      setState(() {
        _status = QiblaArAvailability.noCamera;
        _initializing = false;
      });
      return;
    }

    // Finished after the app left the foreground: the lifecycle handler had
    // no controller to release then, so release it here and let `resumed`
    // start it again.
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final backgrounded =
        lifecycle != null && lifecycle != AppLifecycleState.resumed;
    if (!mounted || backgrounded) {
      controller.dispose();
      if (mounted) {
        setState(() {
          _status = QiblaArAvailability.ready;
          _initializing = false;
        });
      }
      return;
    }
    setState(() {
      _controller = controller;
      _status = QiblaArAvailability.ready;
      _initializing = false;
    });
    widget.onArActiveChanged?.call(true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final cameraReady =
        controller != null && controller.value.isInitialized && !_initializing;
    final overlay = widget.overlayBuilder;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (cameraReady)
            _cameraPreview(controller)
          else
            const ColoredBox(color: Colors.black),

          if (cameraReady && overlay != null)
            SafeArea(child: Builder(builder: overlay)),

          if (!_acknowledged)
            _buildSafetyNotice(context)
          else if (!cameraReady && !_initializing)
            _buildFallback(context),
          if (_initializing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Top bar. Aligned, or the expanded Stack's tight constraints
          // would centre the Row vertically — over the middle of the screen.
          // Embedded, the host's header and tab strip take its place.
          if (!widget.embedded)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildTopBar(context),
              ),
            ),
        ],
      ),
    );
  }

  /// The preview, scaled to COVER the screen (cropping the overflow) rather
  /// than letterboxed, with [QiblaArScreen.previewOverlayBuilder] drawn
  /// inside the same scaled child so it moves and crops with the picture.
  Widget _cameraPreview(CameraController controller) {
    final frameBuilder = widget.previewOverlayBuilder;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        // `aspectRatio` is the sensor's width / height (landscape), so in
        // portrait the picture is width × width·ratio.
        final frame = Size(width, width * controller.value.aspectRatio);
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox.fromSize(
              size: frame,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  if (frameBuilder != null) frameBuilder(context, frame),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _circleButton(
            icon: Icons.arrow_back,
            tooltip: l10n?.translate('common.back') ?? 'رجوع',
            onPressed: _exit,
          ),
          const SizedBox(width: 8),
          // Takes what the two buttons leave, so the label shortens rather
          // than overflowing on a narrow phone at a large text size.
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              // Or the Align fills the height it is offered, and the bar with
              // it.
              heightFactor: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n?.translate('campus.ar_mode') ?? 'وضع الكاميرا',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Almarai',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _circleButton(
            icon: Icons.explore_rounded,
            tooltip: l10n?.translate('campus.compass_mode') ?? 'البوصلة',
            onPressed: _exit,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSafetyNotice(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          // Clears the route's top bar, which is stacked above this. Embedded
          // there is no bar: the host already moved the safe area below its
          // tab strip.
          padding: EdgeInsets.fromLTRB(24, widget.embedded ? 24 : 72, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.amber,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.translate('campus.ar_safety_title') ?? 'تنبيه للسلامة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Almarai',
                  ),
                ),
                const SizedBox(height: 24),
                _safetyPoint(
                  icon: Icons.family_restroom_rounded,
                  title:
                      l10n?.translate('campus.ar_safety_supervision_title') ??
                      'إشراف الوالدين',
                  body:
                      l10n?.translate('campus.ar_safety_supervision') ??
                      'على الأطفال ألّا يستخدموا وضع الكاميرا إلا بإشراف أحد الوالدين أو شخص بالغ.',
                ),
                const SizedBox(height: 12),
                _safetyPoint(
                  icon: Icons.directions_walk_rounded,
                  title:
                      l10n?.translate('campus.ar_safety_surroundings_title') ??
                      'انتبه لما حولك',
                  body:
                      l10n?.translate('campus.ar_safety_surroundings') ??
                      'لا تمشِ وعيناك على الشاشة، وتأكد أن المكان حولك خالٍ من العوائق والمخاطر.',
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _acknowledgeSafetyNotice,
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: Text(
                    l10n?.translate('campus.ar_safety_continue') ??
                        'فهمت، افتح الكاميرا',
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _exit,
                  child: Text(
                    l10n?.translate('campus.back_to_compass') ??
                        'العودة للبوصلة',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _safetyPoint({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Almarai',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The camera is off: «الكاميرا غير مفعّلة», why it is needed, what the
  /// camera is (and is not) used for, a way to turn it on, and the compass as
  /// the way out.
  Widget _buildFallback(BuildContext context) {
    final l10n = context.l10n;
    final permanently =
        _status == QiblaArAvailability.permissionPermanentlyDenied;
    final noCamera = _status == QiblaArAvailability.noCamera;

    final message = noCamera
        ? (l10n?.translate('campus.camera_unavailable') ??
              'الكاميرا غير متاحة على هذا الجهاز')
        : (l10n?.translate('campus.camera_permission_required') ??
              'يحتاج وضع الكاميرا إلى إذن الكاميرا');

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, widget.embedded ? 24 : 72, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  noCamera
                      ? Icons.videocam_off_rounded
                      : Icons.no_photography_rounded,
                  color: Colors.white70,
                  size: 56,
                ),
                const SizedBox(height: 16),
                if (!noCamera) ...[
                  Text(
                    QiblaStrings.tr(
                      context,
                      'qibla.ar.camera_off_title',
                      'الكاميرا غير مفعّلة',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Almarai',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Almarai',
                  ),
                ),
                if (!noCamera) ...[
                  const SizedBox(height: 12),
                  Text(
                    QiblaStrings.tr(
                      context,
                      'qibla.ar.privacy',
                      'نرسم سجادة صلاة افتراضية فوق صورة الكاميرا الحيّة، ولا نلتقط أي صور ولا نحفظها.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: 'Almarai',
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Material, like the notice's own button: this screen is
                  // also pumped with no forui theme above it (the safety
                  // test), where FButton cannot build.
                  ElevatedButton.icon(
                    onPressed: permanently
                        ? () => openAppSettings()
                        : _initCamera,
                    icon: Icon(
                      permanently
                          ? Icons.settings_rounded
                          : Icons.photo_camera_rounded,
                    ),
                    label: Text(
                      permanently
                          ? QiblaStrings.tr(
                              context,
                              'qibla.ar.open_settings',
                              'فتح الإعدادات',
                            )
                          : QiblaStrings.tr(
                              context,
                              'qibla.ar.allow_camera',
                              'السماح بالكاميرا',
                            ),
                    ),
                  ),
                ] else
                  const SizedBox(height: 24),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _exit,
                  child: Text(
                    QiblaStrings.tr(
                      context,
                      'qibla.ar.use_compass_instead',
                      'استخدم البوصلة بدلًا من ذلك',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Almarai',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
