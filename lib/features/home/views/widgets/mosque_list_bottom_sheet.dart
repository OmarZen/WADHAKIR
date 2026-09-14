import 'dart:io';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/mosque_model.dart';
import '../../../../core/services/masjid_near_me_service.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class MosqueListBottomSheet extends StatefulWidget {
  final Position userPosition;

  const MosqueListBottomSheet({super.key, required this.userPosition});

  @override
  State<MosqueListBottomSheet> createState() => _MosqueListBottomSheetState();
}

class _MosqueListBottomSheetState extends State<MosqueListBottomSheet>
    with SingleTickerProviderStateMixin {
  final MasjidNearMeService _service = MasjidNearMeService();
  List<MosqueModel>? _mosques;
  bool _isLoading = true;
  bool _isOffline = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    // Defer to after the first frame: _fetchMosques reads
    // Localizations.localeOf(context), which is not available during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchMosques();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchMosques() async {
    // Capture the locale synchronously before any await; we can't safely
    // touch BuildContext after the async gap.
    final preferredLanguage = Localizations.localeOf(context).languageCode;

    setState(() {
      _isLoading = true;
      _isOffline = false;
    });

    try {
      // Use the OSM-backed search so Arabic mosque names surface correctly
      // for Arabic-speaking users. Falls back to the legacy API internally.
      final mosques = await _service.searchNearby(
        lat: widget.userPosition.latitude,
        lng: widget.userPosition.longitude,
        radius: 10000, // 10km radius
        preferredLanguage: preferredLanguage,
      );

      if (mounted) {
        setState(() {
          _mosques = mosques.take(10).toList(); // Only take first 10
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network error
        final isNetworkError =
            e.toString().contains('SocketException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Network is unreachable') ||
            e.toString().contains('TimeoutException');

        setState(() {
          _isOffline = isNetworkError;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openMapsWithMosqueSearch() async {
    final lat = widget.userPosition.latitude;
    final lng = widget.userPosition.longitude;

    final Uri mapsUrl;

    if (Platform.isIOS) {
      mapsUrl = Uri.parse('http://maps.apple.com/?q=mosque&ll=$lat,$lng');
    } else {
      mapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=mosque&query=$lat,$lng',
      );
    }

    try {
      final launched = await launchUrl(
        mapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(mapsUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      showFToast(
        context: context,
        title: Text(
          l10n?.translate('home.failed_to_open_maps_message') ??
              'Cannot open maps application',
        ),
        variant: FToastVariant.destructive,
      );
    }
  }

  Future<void> _openDirectionsToMosque(MosqueModel mosque) async {
    final lat = mosque.location.latitude;
    final lng = mosque.location.longitude;

    final Uri mapsUrl;

    if (Platform.isIOS) {
      // Apple Maps directions
      mapsUrl = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
    } else {
      // Google Maps directions
      mapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=${mosque.address.googlePlaceId.isNotEmpty ? mosque.address.googlePlaceId : ''}&travelmode=driving',
      );
    }

    try {
      final launched = await launchUrl(
        mapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(mapsUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      showFToast(
        context: context,
        title: Text(
          l10n?.translate('home.failed_to_open_maps_message') ??
              'Cannot open maps application',
        ),
        variant: FToastVariant.destructive,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.mosque,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.translate('home.nearest_mosques') ??
                            'أقرب المساجد',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!_isLoading && _mosques != null)
                        Text(
                          '${_mosques!.length} ${_mosques!.length == 1 ? (l10n?.translate('home.nearest_mosque') ?? 'مسجد') : (l10n?.translate('home.nearest_mosques') ?? 'مساجد')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState(theme, l10n)
                : _isOffline
                ? _buildOfflineState(theme, l10n)
                : _mosques == null || _mosques!.isEmpty
                ? _buildEmptyState(theme, l10n)
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _mosques!.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final mosque = _mosques![index];
                            final distance = mosque.distanceFromPoint(
                              widget.userPosition.latitude,
                              widget.userPosition.longitude,
                            );

                            return _AnimatedMosqueCard(
                              mosque: mosque,
                              distance: distance,
                              index: index,
                              onTap: () => _openDirectionsToMosque(mosque),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                              width: 1,
                            ),
                          ),
                        ),
                        child: FButton(
                          onPress: _openMapsWithMosqueSearch,
                          prefix: const Icon(Icons.map_outlined, size: 20),
                          child: Text(
                            l10n?.translate('home.get_more_mosques') ??
                                'المزيد من المساجد',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      // Space under the button + the system nav-bar inset so
                      // it clears the navigation bar under edge-to-edge.
                      SizedBox(
                        height: 16 + MediaQuery.of(context).viewPadding.bottom,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, dynamic l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: _animationController,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.mosque,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.translate('home.searching_nearby') ??
                'البحث عن مساجد قريبة...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineState(ThemeData theme, dynamic l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n?.translate('home.no_internet_connection') ??
                'لا يوجد اتصال بالإنترنت',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.translate('home.check_internet_connection') ??
                'تحقق من اتصالك بالإنترنت',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, dynamic l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.mosque_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n?.translate('home.no_mosques_found') ?? 'لا توجد مساجد قريبة',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.translate('home.try_expanding_search') ??
                  'جرب توسيع نطاق البحث',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FButton(
              onPress: _openMapsWithMosqueSearch,
              prefix: const Icon(Icons.map_outlined, size: 20),
              child: Text(
                l10n?.translate('home.search_on_maps') ?? 'البحث في الخرائط',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedMosqueCard extends StatefulWidget {
  final MosqueModel mosque;
  final double distance;
  final int index;
  final VoidCallback onTap;

  const _AnimatedMosqueCard({
    required this.mosque,
    required this.distance,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedMosqueCard> createState() => _AnimatedMosqueCardState();
}

class _AnimatedMosqueCardState extends State<_AnimatedMosqueCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Stagger animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _MosqueCard(
          mosque: widget.mosque,
          distance: widget.distance,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _MosqueCard extends StatelessWidget {
  final MosqueModel mosque;
  final double distance;
  final VoidCallback onTap;

  const _MosqueCard({
    required this.mosque,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      elevation: 0.5,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mosque,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mosque.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.near_me_rounded,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distance < 1
                                    ? '${(distance * 1000).toStringAsFixed(0)} ${l10n?.translate('home.meters') ?? 'm'}'
                                    : '${distance.toStringAsFixed(1)} ${l10n?.translate('home.kilometers') ?? 'km'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ],
              ),
              if (mosque.address.formattedAddress.isNotEmpty &&
                  mosque.address.formattedAddress !=
                      'Address not available') ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        mosque.address.formattedAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
