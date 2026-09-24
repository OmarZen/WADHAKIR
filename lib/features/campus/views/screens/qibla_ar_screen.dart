import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/cubit/qibla_state.dart';
import 'package:wadhakir/features/campus/services/qibla_ar_camera_service.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_ar_overlay.dart';

const Color _alignedColor = Color(0xFF27AE60);

/// AR Qibla mode: a live camera preview with the qibla marker drawn on top.
///
/// Reuses the existing [QiblaCubit] stream (provided by the host
/// [QiblaScreen] via `BlocProvider.value`) for the qibla bearing + compass
/// heading — so this screen never owns or closes the cubit. It only manages the
/// [CameraController] lifecycle.
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

  const QiblaArScreen({
    super.key,
    this.prepareCamera = QiblaArCameraService.prepare,
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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
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

  Future<void> _initCamera() async {
    // One attempt at a time: a second would build a second controller and
    // overwrite the first without disposing it.
    if (_initializing) return;
    if (mounted) setState(() => _initializing = true);
    final result = await widget.prepareCamera();
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
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final cameraReady =
        controller != null && controller.value.isInitialized && !_initializing;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (cameraReady)
            _cameraPreview(controller)
          else
            const ColoredBox(color: Colors.black),

          if (cameraReady)
            BlocBuilder<QiblaCubit, QiblaState>(
              builder: (context, state) {
                if (state is QiblaLoaded) {
                  return Positioned.fill(
                    child: QiblaArOverlay(
                      qiblaDirection: state.qiblaModel.qiblaDirection,
                      compassDirection: state.qiblaModel.compassDirection,
                      isAligned: state.isAligned,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

          if (!_acknowledged)
            _buildSafetyNotice(context)
          else if (!cameraReady && !_initializing)
            _buildFallback(context),
          if (_initializing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Top bar. Aligned, or the expanded Stack's tight constraints
          // would centre the Row vertically — over the middle of the screen.
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _buildTopBar(context),
            ),
          ),

          // Bottom status badge.
          if (cameraReady)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomBadge(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cameraPreview(CameraController controller) {
    final size = MediaQuery.of(context).size;
    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.width * controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      ),
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
            onPressed: () => Navigator.of(context).pop(),
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
            onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildBottomBadge(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<QiblaCubit, QiblaState>(
      builder: (context, state) {
        final aligned = state is QiblaLoaded && state.isAligned;
        final text = aligned
            ? (l10n?.translate('campus.align_to_kaaba') ?? 'متجه نحو القبلة')
            : (l10n?.translate('campus.point_camera_hint') ??
                  'حرّك الهاتف حتى تتطابق العلامة مع المنتصف');
        return Container(
          margin: const EdgeInsets.only(bottom: 28),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: aligned
                ? _alignedColor.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                aligned
                    ? Icons.check_circle_rounded
                    : Icons.my_location_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Almarai',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSafetyNotice(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          // Clears the top bar, which is stacked above this.
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
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
                  onPressed: () => Navigator.of(context).pop(),
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noCamera
                  ? Icons.videocam_off_rounded
                  : Icons.no_photography_rounded,
              color: Colors.white70,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (!noCamera)
              ElevatedButton.icon(
                onPressed: permanently ? () => openAppSettings() : _initCamera,
                icon: Icon(permanently ? Icons.settings : Icons.refresh),
                label: Text(
                  permanently
                      ? (l10n?.translate('campus.settings') ?? 'الإعدادات')
                      : (l10n?.translate('campus.retry') ?? 'إعادة المحاولة'),
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n?.translate('campus.back_to_compass') ?? 'العودة للبوصلة',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
