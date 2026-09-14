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
class QiblaArScreen extends StatefulWidget {
  const QiblaArScreen({super.key});

  @override
  State<QiblaArScreen> createState() => _QiblaArScreenState();
}

class _QiblaArScreenState extends State<QiblaArScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  QiblaArAvailability _status = QiblaArAvailability.ready;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // AR overlay math assumes portrait; lock while this screen is visible.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCamera();
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
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Release the camera while backgrounded to avoid leaks/locks.
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (mounted) setState(() => _initializing = true);
    final result = await QiblaArCameraService.prepare();
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
      if (!mounted) return;
      setState(() {
        _status = QiblaArAvailability.noCamera;
        _initializing = false;
      });
      return;
    }

    if (!mounted) {
      controller.dispose();
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

          if (!cameraReady && !_initializing) _buildFallback(context),
          if (_initializing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Top bar.
          SafeArea(child: _buildTopBar(context)),

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
            tooltip: l10n?.translate('common.close') ?? 'رجوع',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n?.translate('campus.ar_mode') ?? 'وضع الكاميرا',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Almarai',
              ),
            ),
          ),
          const Spacer(),
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
                l10n?.translate('campus.compass_mode') ?? 'العودة للبوصلة',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
