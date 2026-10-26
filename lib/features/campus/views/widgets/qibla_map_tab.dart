import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/geo/qibla_geodesy.dart';
import 'package:wadhakir/features/campus/cubit/qibla_cubit.dart';
import 'package:wadhakir/features/campus/views/qibla_look.dart';
import 'package:wadhakir/features/campus/views/qibla_strings.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_location_gate.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_location_label.dart';
import 'package:wadhakir/features/campus/views/widgets/qibla_map_info_card.dart';

/// The Map tab: a real street map (OpenStreetMap through flutter_map) with
/// the great-circle path from the user to the Kaaba, and the distance and
/// bearing under it.
///
/// ## OpenStreetMap's tile policy
/// * The User-Agent names the app (`userAgentPackageName`).
/// * Tiles are fetched only for what is on screen and cached by flutter_map's
///   built-in cache; nothing is ever bulk-downloaded.
/// * «© OpenStreetMap contributors» is always visible, never behind a button
///   or under the info card, readable in both themes (including over the
///   dark-mode tiles), and opens the copyright page when tapped.
///
/// Tile requests reveal roughly where the user is looking to the OSM
/// Foundation; the privacy policy has to say so (see the release notes).
class QiblaMapTab extends StatelessWidget {
  /// Off in widget tests, which must not touch the network.
  final bool enableTiles;

  const QiblaMapTab({super.key, this.enableTiles = true});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QiblaCubit, QiblaState>(
      buildWhen: (a, b) =>
          a.fix != b.fix ||
          a.qiblaBearing != b.qiblaBearing ||
          a.distanceKm != b.distanceKm ||
          a.placeName != b.placeName,
      builder: (context, state) {
        final fix = state.fix;
        final bearing = state.qiblaBearing;
        final distance = state.distanceKm;
        if (fix == null || bearing == null || distance == null) {
          return const QiblaLocationGate();
        }
        return QiblaMapView(
          from: fix.point,
          bearing: bearing,
          distanceKm: distance,
          placeName: state.placeName,
          enableTiles: enableTiles,
        );
      },
    );
  }
}

/// The map itself, once there is a position to draw from.
class QiblaMapView extends StatefulWidget {
  final GeoPoint from;
  final double bearing;
  final double distanceKm;
  final String? placeName;
  final bool enableTiles;

  const QiblaMapView({
    super.key,
    required this.from,
    required this.bearing,
    required this.distanceKm,
    required this.placeName,
    required this.enableTiles,
  });

  @override
  State<QiblaMapView> createState() => QiblaMapViewState();
}

class QiblaMapViewState extends State<QiblaMapView> {
  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _copyrightUrl = 'https://www.openstreetmap.org/copyright';

  /// This many failed tiles and the map is treated as offline.
  static const int offlineAfterErrors = 4;

  static const double _minZoom = 1;
  static const double _maxZoom = 18;

  final MapController _controller = MapController();
  late List<LatLng> _path;
  bool _mapReady = false;

  int _tileErrors = 0;

  /// When the current run of tile errors began. Errors only count toward
  /// "offline" inside [offlineErrorWindow]: four scattered failures (a rate
  /// limit, one slow tile) over a long session are not an outage, but used
  /// to show the offline banner while tiles were loading fine.
  DateTime? _errorRunStart;
  static const Duration offlineErrorWindow = Duration(seconds: 30);
  bool _offline = false;

  /// A new tile layer (and provider) per retry: the layer disposes its
  /// provider with itself, so a provider must never outlive its layer.
  int _tileGeneration = 0;
  NetworkTileProvider? _tileProvider;

  @override
  void initState() {
    super.initState();
    _path = _greatCircle(widget.from);
  }

  @override
  void didUpdateWidget(QiblaMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (QiblaGeodesy.distanceKm(oldWidget.from, widget.from) > 1) {
      _path = _greatCircle(widget.from);
      if (_mapReady) _controller.fitCamera(_fit);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static List<LatLng> _greatCircle(GeoPoint from) => [
    for (final p in QiblaGeodesy.greatCircle(from, QiblaGeodesy.kaaba))
      LatLng(p.latitude, p.longitude),
  ];

  /// Both ends and the bow of the path in view. The zoom cap matters at the
  /// Haram, where the two ends coincide and an uncapped fit would zoom in
  /// without limit.
  CameraFit get _fit => CameraFit.coordinates(
    coordinates: _path,
    padding: const EdgeInsets.all(Spacing.xxxl),
    maxZoom: 12,
    minZoom: _minZoom,
  );

  void _onTileError(TileImage tile, Object error, StackTrace? stackTrace) =>
      _countTileError();

  /// One failed tile, as the tile layer would report it; for widget tests,
  /// which run without tiles.
  @visibleForTesting
  void debugReportTileError() => _countTileError();

  void _countTileError() {
    if (_offline) return;
    final now = DateTime.now();
    final start = _errorRunStart;
    if (start == null || now.difference(start) > offlineErrorWindow) {
      _errorRunStart = now;
      _tileErrors = 0;
    }
    _tileErrors++;
    if (_tileErrors < offlineAfterErrors) return;
    void markOffline() {
      if (mounted && !_offline) setState(() => _offline = true);
    }

    // Tile callbacks can arrive mid-frame; setState must wait for its end.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => markOffline());
    } else {
      markOffline();
    }
  }

  void _retryTiles() {
    setState(() {
      _offline = false;
      _tileErrors = 0;
      _errorRunStart = null;
      _tileGeneration++;
      _tileProvider = null;
    });
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final camera = _controller.camera;
    _controller.move(
      camera.center,
      (camera.zoom + delta).clamp(_minZoom, _maxZoom),
    );
  }

  Future<void> _openCopyright() async {
    try {
      await launchUrl(
        Uri.parse(_copyrightUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Qibla map: could not open the OSM copyright page: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final accent = AppAccent.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final map = FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCameraFit: _fit,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        backgroundColor: dark
            ? const Color(0xFF1B1F27)
            : const Color(0xFFE8ECF1),
        // North stays up: the map is read against the compass and the
        // bearing in the card, and a rotated map invites misreading both.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: () => _mapReady = true,
      ),
      children: [
        if (widget.enableTiles)
          TileLayer(
            key: ValueKey(_tileGeneration),
            urlTemplate: _tileUrl,
            userAgentPackageName: 'com.bloom.wadhakir',
            tileProvider: _tileProvider ??= NetworkTileProvider(),
            maxNativeZoom: 19,
            tileBuilder: dark ? darkModeTileBuilder : null,
            errorTileCallback: _onTileError,
          ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _path,
              strokeWidth: 4,
              color: accent,
              borderStrokeWidth: 2,
              borderColor: (dark ? Colors.black : Colors.white).withValues(
                alpha: 0.7,
              ),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _path.last,
              width: 40,
              height: 40,
              child: Semantics(
                label: QiblaStrings.tr(
                  context,
                  'qibla.map.makkah',
                  'مكة المكرمة',
                ),
                child: const _KaabaMarker(),
              ),
            ),
            Marker(
              point: _path.first,
              width: 44,
              height: 44,
              child: Semantics(
                label: QiblaStrings.tr(context, 'qibla.map.you', 'موقعك'),
                child: _UserMarker(color: accent),
              ),
            ),
          ],
        ),
      ],
    );

    final attribution = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Align(
        alignment: rtl ? Alignment.bottomRight : Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xs),
          // Scaled down rather than wrapped or clipped: the notice has to
          // stay whole and visible at any text size.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.85),
              ),
              // The notice is Latin text: laid out right to left, bidi moved
              // "©" after the name ("OpenStreetMap contributors ©").
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SimpleAttributionWidget(
                  source: const Text('OpenStreetMap contributors'),
                  onTap: _openCopyright,
                  backgroundColor: (dark ? theme.cardColor : cs.surface)
                      .withValues(alpha: 0.9),
                  alignment: rtl ? Alignment.bottomRight : Alignment.bottomLeft,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: map),
                if (!_offline)
                  PositionedDirectional(
                    end: Spacing.sm,
                    top: Spacing.sm,
                    child: _MapButtons(
                      onZoomIn: () => _zoomBy(1),
                      onZoomOut: () => _zoomBy(-1),
                      onRecenter: () {
                        if (_mapReady) _controller.fitCamera(_fit);
                      },
                    ),
                  ),
                if (_offline)
                  // Scrolls inside the map's area rather than being clipped
                  // by it on a short screen at a large text size.
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(Spacing.sm),
                        child: _OfflineBanner(onRetry: _retryTiles),
                      ),
                    ),
                  ),
                Positioned.fill(child: attribution),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.5),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.sm,
                Spacing.md,
                Spacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const QiblaLocationLabel(),
                  QiblaMapInfoCard(
                    distanceKm: widget.distanceKm,
                    bearing: widget.bearing,
                    latitude: widget.from.latitude,
                    longitude: widget.from.longitude,
                    placeName: widget.placeName,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButtons extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  const _MapButtons({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapButton(
          icon: Icons.add_rounded,
          label: QiblaStrings.tr(context, 'qibla.map.zoom_in', 'تكبير'),
          onTap: onZoomIn,
        ),
        const SizedBox(height: Spacing.xs),
        _MapButton(
          icon: Icons.remove_rounded,
          label: QiblaStrings.tr(context, 'qibla.map.zoom_out', 'تصغير'),
          onTap: onZoomOut,
        ),
        const SizedBox(height: Spacing.sm),
        _MapButton(
          icon: Icons.fit_screen_rounded,
          label: QiblaStrings.tr(
            context,
            'qibla.map.recenter',
            'إظهار المسار كاملًا',
          ),
          onTap: onRecenter,
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MapButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Tooltip(
      message: label,
      child: Material(
        color: dark ? theme.cardColor : cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          side: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppAccent.of(context), size: 22),
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final warning = QiblaLook.warning(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          warning.withValues(alpha: 0.14),
          dark ? theme.cardColor : cs.surface,
        ),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_off_rounded, color: warning, size: 22),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  QiblaStrings.tr(
                    context,
                    'qibla.map.offline',
                    'تعذّر تحميل الخريطة، تحقق من اتصالك. المسافة والاتجاه صحيحان دون اتصال.',
                  ),
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 13,
                    height: 1.4,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FButton(
              variant: FButtonVariant.outline,
              mainAxisSize: MainAxisSize.min,
              onPress: onRetry,
              child: QiblaButtonLabel(
                QiblaStrings.tr(
                  context,
                  'qibla.location.retry',
                  'إعادة المحاولة',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserMarker extends StatelessWidget {
  final Color color;

  const _UserMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _KaabaMarker extends StatelessWidget {
  const _KaabaMarker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? theme.cardColor : cs.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppAccent.of(context).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedKaaba01,
        color: cs.onSurface,
        size: 22,
      ),
    );
  }
}
