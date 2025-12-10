import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/mosque_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/masjid_near_me_service.dart';
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

class _MosqueListBottomSheetState extends State<MosqueListBottomSheet> {
  final MasjidNearMeService _service = MasjidNearMeService();
  List<MosqueModel>? _mosques;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMosques();
  }

  Future<void> _fetchMosques() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mosques = await _service.searchByCoordinates(
        lat: widget.userPosition.latitude,
        lng: widget.userPosition.longitude,
        radius: 5000, // 5km radius
      );

      setState(() {
        _mosques = mosques.take(5).toList(); // Only take first 5
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.mosque, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n?.translate('home.nearest_mosques') ?? 'أقرب المساجد',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
          Divider(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            height: 1,
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.translate('home.loading_mosques') ??
                              'جارٍ تحميل المساجد...',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n?.translate('home.error_loading_mosques') ??
                                    'خطأ في تحميل المساجد',
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _fetchMosques,
                                icon: const Icon(Icons.refresh),
                                label: Text(
                                  l10n?.translate('common.retry') ??
                                      'إعادة المحاولة',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _mosques == null || _mosques!.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mosque_outlined,
                                    size: 64,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n?.translate('home.no_mosques_found') ??
                                        'لا توجد مساجد قريبة',
                                    style: theme.textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n?.translate(
                                            'home.try_expanding_search') ??
                                        'جرب توسيع نطاق البحث',
                                    style: theme.textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
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
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _openMapsWithMosqueSearch,
                                    icon: const Icon(Icons.map_outlined),
                                    label: Text(
                                      l10n?.translate(
                                              'home.get_more_mosques') ??
                                          'المزيد من المساجد',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance < 1
                                ? '${(distance * 1000).toStringAsFixed(0)} ${l10n?.translate('home.meters') ?? 'm'}'
                                : '${distance.toStringAsFixed(1)} ${l10n?.translate('home.kilometers') ?? 'km'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
