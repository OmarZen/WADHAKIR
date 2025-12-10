import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/mosque_model.dart';
import '../../../../core/services/masjid_near_me_service.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class MosqueListBottomSheet extends StatefulWidget {
  final Position userPosition;

  const MosqueListBottomSheet({
    super.key,
    required this.userPosition,
  });

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
    _fetchMosques();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchMosques() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });

    try {
      final mosques = await _service.searchByCoordinates(
        lat: widget.userPosition.latitude,
        lng: widget.userPosition.longitude,
        radius: 5000, // 5km radius
      );

      if (mounted) {
        setState(() {
          _mosques = mosques.take(5).toList(); // Only take first 5
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network error
        final isNetworkError = e.toString().contains('SocketException') ||
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
          'https://www.google.com/maps/search/?api=1&query=mosque&query=$lat,$lng');
    }

    try {
      final launched = await launchUrl(
        mapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(
          mapsUrl,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate('home.failed_to_open_maps_message') ??
                'Cannot open maps application',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.mosque,
                      color: theme.colorScheme.onPrimary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.translate('home.nearest_mosques') ??
                            'أقرب المساجد',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isLoading
                            ? (l10n?.translate('home.searching_nearby') ??
                                'البحث عن مساجد قريبة...')
                            : _mosques != null
                                ? '${_mosques!.length} ${_mosques!.length == 1 ? (l10n?.translate('home.nearest_mosque') ?? 'مسجد') : (l10n?.translate('home.nearest_mosques') ?? 'مساجد')}'
                                : '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final mosque = _mosques![index];
                                    final distance = mosque.distanceFromPoint(
                                      widget.userPosition.latitude,
                                      widget.userPosition.longitude,
                                    );

                                    return _MosqueCard(
                                      mosque: mosque,
                                      distance: distance,
                                    );
                                  },
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.surface,
                                      theme.colorScheme.primary
                                          .withValues(alpha: 0.03),
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, -4),
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _openMapsWithMosqueSearch,
                                    icon: const Icon(Icons.explore_outlined,
                                        size: 22),
                                    label: Text(
                                      l10n?.translate(
                                              'home.get_more_mosques') ??
                                          'المزيد من المساجد',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
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
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.mosque,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            l10n?.translate('home.searching_nearby') ??
                'البحث عن مساجد قريبة...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              borderRadius: BorderRadius.circular(100),
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineState(ThemeData theme, dynamic l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n?.translate('home.no_internet_connection') ??
                  'لا يوجد اتصال بالإنترنت',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.translate('home.check_internet_connection') ??
                  'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.tonalIcon(
              onPressed: _fetchMosques,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                l10n?.translate('common.retry') ?? 'إعادة المحاولة',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(
                l10n?.translate('common.close') ?? 'إغلاق',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, dynamic l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.mosque_outlined,
                size: 72,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n?.translate('home.no_mosques_found') ?? 'لا توجد مساجد قريبة',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.translate('home.try_expanding_search') ??
                  'جرب توسيع نطاق البحث',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _fetchMosques,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    l10n?.translate('common.retry') ?? 'إعادة المحاولة',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _openMapsWithMosqueSearch,
                  icon: const Icon(Icons.explore_outlined, size: 20),
                  label: Text(
                    l10n?.translate('home.get_more_mosques') ??
                        'المزيد من المساجد',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MosqueCard extends StatelessWidget {
  final MosqueModel mosque;
  final double distance;

  const _MosqueCard({
    required this.mosque,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mosque,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mosque.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                              theme.colorScheme.primary.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.near_me_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              distance < 1
                                  ? '${(distance * 1000).toStringAsFixed(0)} ${l10n?.translate('home.meters') ?? 'm'}'
                                  : '${distance.toStringAsFixed(1)} ${l10n?.translate('home.kilometers') ?? 'km'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (mosque.address.formattedAddress.isNotEmpty &&
                mosque.address.formattedAddress != 'Address not available') ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_city_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mosque.address.formattedAddress,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (mosque.timings.hasTimings) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (mosque.timings.fajr.isNotEmpty)
                    _PrayerTimeChip(
                      label:
                          '${l10n?.translate('home.fajr') ?? 'Fajr'}: ${mosque.timings.fajr}',
                      theme: theme,
                    ),
                  if (mosque.timings.maghrib.isNotEmpty)
                    _PrayerTimeChip(
                      label:
                          '${l10n?.translate('home.maghrib') ?? 'Maghrib'}: ${mosque.timings.maghrib}',
                      theme: theme,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrayerTimeChip extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _PrayerTimeChip({
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
