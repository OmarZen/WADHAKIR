import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/data/models/app_lock_settings_model.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/features/app_lock/models/app_lock_permission_status.dart';
import 'package:wadhakir/features/app_lock/models/installed_app_model.dart';
import 'package:wadhakir/features/app_lock/services/app_lock_hadith_quotes_service.dart';
import 'package:wadhakir/features/app_lock/services/app_lock_prayer_window.dart';
import 'package:wadhakir/features/app_lock/services/app_lock_platform_service.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';

class AppLockSettingsWidget extends StatefulWidget {
  final AppSettingsModel settings;
  final SettingsCubit cubit;

  const AppLockSettingsWidget({
    super.key,
    required this.settings,
    required this.cubit,
  });

  @override
  State<AppLockSettingsWidget> createState() => _AppLockSettingsWidgetState();
}

class _AppLockSettingsWidgetState extends State<AppLockSettingsWidget> {
  final AppLockPlatformService _platformService =
      const AppLockPlatformService();
  final AppLockHadithQuotesService _quotesService =
      const AppLockHadithQuotesService();
  late Future<AppLockPermissionStatus> _permissionStatusFuture;

  static const String _durationUntilConfirm = 'until_confirm';

  bool get _isAndroidOnlyFeature =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _permissionStatusFuture = _isAndroidOnlyFeature
        ? _platformService.getPermissionStatus()
        : Future.value(
            const AppLockPermissionStatus(
              usageAccessGranted: false,
              overlayGranted: false,
            ),
          );
  }

  Future<void> _refreshPermissionStatus() async {
    setState(() {
      _permissionStatusFuture = _platformService.getPermissionStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final appLockSettings = widget.settings.appLockSettings;
    final selectedAppsCount = appLockSettings.lockedAppPackageNames.length;

    return Column(
      children: [
        SwitchListTile.adaptive(
          value: appLockSettings.enabled,
          onChanged: (enabled) => _handleAppLockToggle(context, enabled),
          title: Text(
            l10n?.translate('settings.app_lock_enable') ??
                'Enable app lock during prayer',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            l10n?.translate('settings.app_lock_enable_subtitle') ??
                'Lock selected apps during prayer windows',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          activeThumbColor: theme.colorScheme.primary,
        ),
        _divider(theme),
        ListTile(
          leading: const Icon(Icons.apps_outlined),
          title: Text(
            l10n?.translate('settings.app_lock_selected_apps') ??
                'Selected apps to lock',
          ),
          subtitle: Text(
            selectedAppsCount == 0
                ? (l10n?.translate('settings.app_lock_no_apps_selected') ??
                    'No apps selected yet')
                : '$selectedAppsCount ${l10n?.translate('settings.app_lock_apps_count_suffix') ?? 'apps selected'}',
          ),
          trailing: TextButton(
            onPressed: () => _showAppPicker(context),
            child: Text(
              l10n?.translate('settings.app_lock_manage_apps') ?? 'Manage',
            ),
            style: ButtonStyle(
              foregroundColor: isDark
                  ? MaterialStateProperty.all(theme.colorScheme.onPrimary)
                  : null,
            ),
          ),
        ),
        _divider(theme),
        ListTile(
          leading: const Icon(Icons.security_outlined),
          title: Text(
            l10n?.translate('settings.app_lock_permissions_title') ??
                'Permissions setup',
          ),
          subtitle: FutureBuilder<AppLockPermissionStatus>(
            future: _permissionStatusFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Text(
                  l10n?.translate('settings.app_lock_permissions_loading') ??
                      'Checking permissions...',
                );
              }

              final status = snapshot.data!;
              final usage = status.usageAccessGranted
                  ? (l10n?.translate('settings.app_lock_permission_granted') ??
                      'Granted')
                  : (l10n?.translate('settings.app_lock_permission_missing') ??
                      'Missing');
              final overlay = status.overlayGranted
                  ? (l10n?.translate('settings.app_lock_permission_granted') ??
                      'Granted')
                  : (l10n?.translate('settings.app_lock_permission_missing') ??
                      'Missing');

              return Text('Usage: $usage • Overlay: $overlay');
            },
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPermissionsActions(context),
        ),
        if (appLockSettings.enabled) ...[
          _divider(theme),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(
              l10n?.translate('settings.app_lock_duration_title') ??
                  'Lock duration',
            ),
            subtitle: Text(
              _durationLabelForSettings(
                appLockSettings.lockDurationMinutes,
                l10n,
              ),
            ),
            trailing: DropdownButton<String>(
              value: _durationValueFromMinutes(
                appLockSettings.lockDurationMinutes,
              ),
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(
                  value: '10',
                  child: Text(
                    l10n?.translate('settings.app_lock_duration_10_min') ??
                        '10 min',
                  ),
                ),
                DropdownMenuItem(
                  value: '15',
                  child: Text(
                    l10n?.translate('settings.app_lock_duration_15_min') ??
                        '15 min',
                  ),
                ),
                DropdownMenuItem(
                  value: '20',
                  child: Text(
                    l10n?.translate('settings.app_lock_duration_20_min') ??
                        '20 min',
                  ),
                ),
                DropdownMenuItem(
                  value: _durationUntilConfirm,
                  child: Text(
                    l10n?.translate(
                          'settings.app_lock_duration_until_confirm',
                        ) ??
                        'Until confirm',
                  ),
                ),
              ],
              onChanged: (value) async {
                if (value == null) return;
                final duration = _minutesFromDurationValue(value);
                await widget.cubit.setLockDurationMinutes(duration);
                await _syncMonitorConfigIfEnabled(
                  lockDurationMinutes: duration,
                );
              },
            ),
          ),
          _divider(theme),
          SwitchListTile.adaptive(
            value: appLockSettings.emergencyBypassEnabled,
            onChanged: (enabled) async {
              await widget.cubit.toggleEmergencyBypass(enabled);
              await _syncMonitorConfigIfEnabled(
                emergencyBypassEnabled: enabled,
              );
            },
            title: Text(
              l10n?.translate('settings.app_lock_bypass_title') ??
                  'Emergency bypass',
            ),
            subtitle: Text(
              l10n?.translate('settings.app_lock_bypass_subtitle') ??
                  'Hold 3 seconds, then confirm to unlock temporarily',
            ),
          ),
          _divider(theme),
          SwitchListTile.adaptive(
            value: appLockSettings.useAccessibilityFallback,
            onChanged: widget.cubit.toggleAccessibilityFallback,
            title: Text(
              l10n?.translate('settings.app_lock_accessibility_fallback') ??
                  'Enable accessibility fallback',
            ),
            subtitle: Text(
              l10n?.translate(
                      'settings.app_lock_accessibility_fallback_subtitle') ??
                  'Use accessibility only when usage access is not enough',
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showAppPicker(BuildContext context) async {
    final l10n = context.l10n;

    if (!_isAndroidOnlyFeature) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate('settings.app_lock_android_only') ??
                'This feature is currently Android only',
          ),
        ),
      );
      return;
    }

    try {
      final List<InstalledAppModel> apps =
          await _platformService.getInstalledApps();
      if (!context.mounted) return;

      final filtered = apps
          .where(
            (app) => !widget.settings.appLockSettings.excludedAppPackageNames
                .contains(app.packageName),
          )
          .toList();

      final selected =
          widget.settings.appLockSettings.lockedAppPackageNames.toSet();

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          String query = '';
          return StatefulBuilder(
            builder: (context, setLocalState) {
              final visible = filtered.where((app) {
                if (query.isEmpty) return true;
                final q = query.toLowerCase();
                return app.appName.toLowerCase().contains(q) ||
                    app.packageName.toLowerCase().contains(q);
              }).toList()
                ..sort((a, b) {
                  final aSelected = selected.contains(a.packageName);
                  final bSelected = selected.contains(b.packageName);
                  if (aSelected != bSelected) {
                    return aSelected ? -1 : 1;
                  }
                  return a.appName.toLowerCase().compareTo(
                        b.appName.toLowerCase(),
                      );
                });

              return Dialog(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 520, maxHeight: 620),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.translate('settings.app_lock_picker_title') ??
                              'Select apps to lock',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${selected.length} ${l10n?.translate('settings.app_lock_apps_count_suffix') ?? 'apps selected'}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: l10n?.translate(
                                  'settings.app_lock_picker_search_hint',
                                ) ??
                                'Search apps...',
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setLocalState(() {
                              query = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final app = visible[index];
                              final isSelected =
                                  selected.contains(app.packageName);
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  setLocalState(() {
                                    if (isSelected) {
                                      selected.remove(app.packageName);
                                    } else {
                                      selected.add(app.packageName);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.25),
                                    ),
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.08)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.25),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildAppIcon(app, isSelected),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              app.appName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              app.packageName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(
                                                            alpha: 0.65),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .outline
                                                    .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_rounded
                                              : Icons.add_rounded,
                                          size: 18,
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: Text(
                                  l10n?.translate('common.cancel') ?? 'Cancel'),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () async {
                                final isArabic =
                                    Localizations.localeOf(dialogContext)
                                            .languageCode ==
                                        'ar';
                                final isDark =
                                    Theme.of(dialogContext).brightness ==
                                        Brightness.dark;
                                final prayerWindow =
                                    _currentPrayerWindowPayload();
                                final prayerName =
                                    _currentPrayerName(dialogContext.l10n);
                                await widget.cubit.setLockedAppPackageNames(
                                    selected.toList());
                                final latestSettings =
                                    _currentAppLockSettings();
                                if (latestSettings.enabled) {
                                  if (!dialogContext.mounted) return;
                                  final quotePayload =
                                      await _buildOverlayQuotePayload(
                                    useArabic: isArabic,
                                  );
                                  if (!dialogContext.mounted) return;
                                  await _platformService.updateMonitorConfig(
                                    lockedPackages: selected.toList(),
                                    lockDurationMinutes:
                                        latestSettings.lockDurationMinutes,
                                    emergencyBypassEnabled:
                                        latestSettings.emergencyBypassEnabled,
                                    overlayTexts: _overlayTexts(
                                      dialogContext,
                                      referenceText:
                                          quotePayload.initialReference,
                                      prayerName: prayerName,
                                    ),
                                    overlayMessages:
                                        quotePayload.overlayMessages,
                                    overlayReferences:
                                        quotePayload.overlayReferences,
                                    overlayIsDark: isDark,
                                    prayerWindowStartMs:
                                        prayerWindow.windowStartMs,
                                    nextPrayerStartMs:
                                        prayerWindow.nextPrayerStartMs,
                                  );
                                }
                                if (!dialogContext.mounted) return;
                                Navigator.of(dialogContext).pop();
                              },
                              child: Text(
                                  l10n?.translate('common.save') ?? 'Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate('settings.app_lock_app_picker_error') ??
                'Failed to load installed apps',
          ),
        ),
      );
    }
  }

  Future<void> _showPermissionsActions(BuildContext context) async {
    final l10n = context.l10n;

    if (!_isAndroidOnlyFeature) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate('settings.app_lock_android_only') ??
                'This feature is currently Android only',
          ),
        ),
      );
      return;
    }

    final status = await _platformService.getPermissionStatus();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  status.usageAccessGranted
                      ? Icons.check_circle
                      : Icons.error_outline,
                ),
                title: Text(
                  l10n?.translate('settings.app_lock_usage_access_title') ??
                      'Usage access',
                ),
                subtitle: Text(
                  status.usageAccessGranted
                      ? (l10n?.translate(
                              'settings.app_lock_permission_granted') ??
                          'Granted')
                      : (l10n?.translate(
                              'settings.app_lock_permission_missing') ??
                          'Missing'),
                ),
                trailing: TextButton(
                  onPressed: () => _platformService.openUsageAccessSettings(),
                  child: Text(
                    l10n?.translate('settings.app_lock_open_settings') ??
                        'Open',
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  status.overlayGranted
                      ? Icons.check_circle
                      : Icons.error_outline,
                ),
                title: Text(
                  l10n?.translate('settings.app_lock_overlay_title') ??
                      'Display over other apps',
                ),
                subtitle: Text(
                  status.overlayGranted
                      ? (l10n?.translate(
                              'settings.app_lock_permission_granted') ??
                          'Granted')
                      : (l10n?.translate(
                              'settings.app_lock_permission_missing') ??
                          'Missing'),
                ),
                trailing: TextButton(
                  onPressed: () => _platformService.openOverlaySettings(),
                  child: Text(
                    l10n?.translate('settings.app_lock_open_settings') ??
                        'Open',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: Text(
                  l10n?.translate(
                          'settings.app_lock_overlay_not_found_title') ??
                      'App not listed in overlay screen?',
                ),
                subtitle: Text(
                  l10n?.translate(
                          'settings.app_lock_overlay_not_found_subtitle') ??
                      'Open app details and check Display over other apps manually.',
                ),
                trailing: TextButton(
                  onPressed: () => _platformService.openAppDetailsSettings(),
                  child: Text(
                    l10n?.translate('settings.app_lock_open_settings') ??
                        'Open',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.accessibility_new),
                title: Text(
                  l10n?.translate('settings.app_lock_accessibility_title') ??
                      'Accessibility fallback',
                ),
                subtitle: Text(
                  l10n?.translate('settings.app_lock_accessibility_subtitle') ??
                      'Optional fallback mode',
                ),
                trailing: TextButton(
                  onPressed: () => _platformService.openAccessibilitySettings(),
                  child: Text(
                    l10n?.translate('settings.app_lock_open_settings') ??
                        'Open',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(
                  l10n?.translate('settings.app_lock_refresh_permissions') ??
                      'Refresh permission status',
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _refreshPermissionStatus();
                },
              ),
            ],
          ),
        );
      },
    );

    await _refreshPermissionStatus();
  }

  Future<void> _handleAppLockToggle(BuildContext context, bool enabled) async {
    final previousSettings = widget.settings.appLockSettings;
    await widget.cubit.toggleAppLock(enabled);

    if (!_isAndroidOnlyFeature) {
      return;
    }

    if (enabled) {
      final currentState = widget.cubit.state;
      final currentSettings = currentState is SettingsLoaded
          ? currentState.settings.appLockSettings
          : previousSettings;

      final lockedPackages = currentSettings.lockedAppPackageNames;
      if (lockedPackages.isEmpty && context.mounted) {
        await widget.cubit.toggleAppLock(false);
        await _platformService.stopLockMonitor();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n?.translate('settings.app_lock_select_apps_first') ??
                  'Select apps first to enable blocking.',
            ),
          ),
        );
        return;
      }

      final permissionStatus = await _platformService.getPermissionStatus();
      if (!permissionStatus.usageAccessGranted && context.mounted) {
        await widget.cubit.toggleAppLock(false);
        await _platformService.stopLockMonitor();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n
                      ?.translate('settings.app_lock_usage_required_message') ??
                  'Usage access is required to block selected apps.',
            ),
          ),
        );
        return;
      }

      if (!context.mounted) return;

      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final quotePayload = await _buildOverlayQuotePayload(
        useArabic: isArabic,
      );
      if (!context.mounted) return;
      final prayerWindow = _currentPrayerWindowPayload();
      final prayerName = _currentPrayerName(context.l10n);

      await _platformService.startLockMonitor(
        lockedPackages: lockedPackages,
        overlayMessage: quotePayload.initialMessage,
        overlayTexts: _overlayTexts(
          context,
          referenceText: quotePayload.initialReference,
          prayerName: prayerName,
        ),
        overlayMessages: quotePayload.overlayMessages,
        overlayReferences: quotePayload.overlayReferences,
        lockDurationMinutes: currentSettings.lockDurationMinutes,
        emergencyBypassEnabled: currentSettings.emergencyBypassEnabled,
        overlayIsDark: Theme.of(context).brightness == Brightness.dark,
        prayerWindowStartMs: prayerWindow.windowStartMs,
        nextPrayerStartMs: prayerWindow.nextPrayerStartMs,
      );
    } else {
      await _platformService.stopLockMonitor();
    }
  }

  Future<void> _syncMonitorConfigIfEnabled({
    int? lockDurationMinutes,
    bool? emergencyBypassEnabled,
  }) async {
    if (!_isAndroidOnlyFeature) return;

    final currentState = widget.cubit.state;
    if (currentState is! SettingsLoaded) return;

    final settings = currentState.settings.appLockSettings;
    if (!settings.enabled) return;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prayerWindow = _currentPrayerWindowPayload();
    final prayerName = _currentPrayerName(context.l10n);
    final quotePayload = await _buildOverlayQuotePayload(useArabic: isArabic);
    if (!mounted) return;

    await _platformService.updateMonitorConfig(
      lockedPackages: settings.lockedAppPackageNames,
      overlayTexts: _overlayTexts(
        context,
        referenceText: quotePayload.initialReference,
        prayerName: prayerName,
      ),
      overlayMessages: quotePayload.overlayMessages,
      overlayReferences: quotePayload.overlayReferences,
      lockDurationMinutes: lockDurationMinutes ?? settings.lockDurationMinutes,
      emergencyBypassEnabled:
          emergencyBypassEnabled ?? settings.emergencyBypassEnabled,
      overlayIsDark: isDark,
      prayerWindowStartMs: prayerWindow.windowStartMs,
      nextPrayerStartMs: prayerWindow.nextPrayerStartMs,
    );
  }

  _PrayerWindowPayload _currentPrayerWindowPayload() {
    final state = context.read<PrayerTimesCubit>().state;
    if (state is! PrayerTimesLoaded) {
      return const _PrayerWindowPayload(0, 0);
    }

    final now = DateTime.now();
    final dateKey = DateTime(now.year, now.month, now.day);
    final todayTimes = state.prayerTimes[dateKey];
    if (todayTimes == null) {
      return const _PrayerWindowPayload(0, 0);
    }

    final window = AppLockPrayerWindow.fromPrayerTimes(todayTimes, now);
    if (window == null) {
      return const _PrayerWindowPayload(0, 0);
    }

    return _PrayerWindowPayload(
      window.windowStart.millisecondsSinceEpoch,
      window.nextPrayerStart.millisecondsSinceEpoch,
    );
  }

  Future<_OverlayQuotePayload> _buildOverlayQuotePayload({
    required bool useArabic,
  }) async {
    final quotes = await _quotesService.getAllQuotes(useArabic: useArabic);
    final messages =
        quotes.map((q) => q.message.trim()).where((m) => m.isNotEmpty).toList();
    final references = quotes.map((q) => q.reference.trim()).toList();

    if (messages.isEmpty) {
      return const _OverlayQuotePayload(
        initialMessage: 'Use this time in something beneficial.',
        initialReference: '',
        overlayMessages: ['Use this time in something beneficial.'],
        overlayReferences: [''],
      );
    }

    return _OverlayQuotePayload(
      initialMessage: messages.first,
      initialReference: references.isNotEmpty ? references.first : '',
      overlayMessages: messages,
      overlayReferences: references,
    );
  }

  AppLockSettingsModel _currentAppLockSettings() {
    final currentState = widget.cubit.state;
    if (currentState is SettingsLoaded) {
      return currentState.settings.appLockSettings;
    }
    return widget.settings.appLockSettings;
  }

  String _currentPrayerName(AppLocalizations? l10n) {
    final state = context.read<PrayerTimesCubit>().state;
    if (state is! PrayerTimesLoaded) {
      return l10n?.translate('settings.app_lock_prayer_name_fallback') ??
          'Prayer time';
    }

    final now = DateTime.now();
    final dateKey = DateTime(now.year, now.month, now.day);
    final todayTimes = state.prayerTimes[dateKey];
    if (todayTimes == null) {
      return l10n?.translate('settings.app_lock_prayer_name_fallback') ??
          'Prayer time';
    }

    final window = AppLockPrayerWindow.fromPrayerTimes(todayTimes, now);
    if (window == null) {
      return l10n?.translate('settings.app_lock_prayer_name_fallback') ??
          'Prayer time';
    }

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (window.windowStart == todayTimes.fajr) {
      return isArabic ? 'الفجر' : 'Fajr';
    }
    if (window.windowStart == todayTimes.dhuhr) {
      return isArabic ? 'الظهر' : 'Dhuhr';
    }
    if (window.windowStart == todayTimes.asr) {
      return isArabic ? 'العصر' : 'Asr';
    }
    if (window.windowStart == todayTimes.maghrib) {
      return isArabic ? 'المغرب' : 'Maghrib';
    }
    if (window.windowStart == todayTimes.isha) {
      return isArabic ? 'العشاء' : 'Isha';
    }

    return l10n?.translate('settings.app_lock_prayer_name_fallback') ??
        'Prayer time';
  }

  Map<String, String> _overlayTexts(
    BuildContext context, {
    String? referenceText,
    String? prayerName,
  }) {
    return _overlayTextsFromL10n(
      context.l10n,
      referenceText: referenceText,
      prayerName: prayerName,
    );
  }

  Map<String, String> _overlayTextsFromL10n(
    AppLocalizations? l10n, {
    String? referenceText,
    String? prayerName,
  }) {
    return <String, String>{
      'title': l10n?.translate('settings.app_lock_overlay_title_text') ??
          'Valuable time',
      'reference': referenceText ?? '',
      'prayerName': prayerName ??
          (l10n?.translate('settings.app_lock_prayer_name_fallback') ??
              'Prayer time'),
      'goHome': l10n?.translate('settings.app_lock_overlay_go_home') ??
          'Return to home',
      'completedPrayer':
          l10n?.translate('settings.app_lock_overlay_completed_prayer') ??
              'I completed prayer',
      'holdBypass': l10n?.translate('settings.app_lock_overlay_hold_bypass') ??
          'Hold 3 seconds for emergency bypass',
      'keepHolding':
          l10n?.translate('settings.app_lock_overlay_keep_holding') ??
              'Keep holding...',
      'holdReady': l10n?.translate('settings.app_lock_overlay_hold_ready') ??
          'Hold complete. Confirm to unlock for 10 seconds.',
      'confirmBypass':
          l10n?.translate('settings.app_lock_overlay_confirm_bypass') ??
              'Confirm emergency bypass',
      'cancel': l10n?.translate('common.cancel') ?? 'Cancel',
    };
  }

  String _durationValueFromMinutes(int? minutes) {
    if (minutes == null) return _durationUntilConfirm;
    return minutes.toString();
  }

  int? _minutesFromDurationValue(String value) {
    if (value == _durationUntilConfirm) {
      return null;
    }
    return int.tryParse(value);
  }

  String _durationLabelForSettings(int? minutes, AppLocalizations? l10n) {
    if (minutes == null) {
      return l10n?.translate('settings.app_lock_duration_until_confirm') ??
          'Until user confirms completion';
    }

    switch (minutes) {
      case 10:
        return l10n?.translate('settings.app_lock_duration_10_min') ??
            '10 minutes';
      case 15:
        return l10n?.translate('settings.app_lock_duration_15_min') ??
            '15 minutes';
      case 20:
        return l10n?.translate('settings.app_lock_duration_20_min') ??
            '20 minutes';
      default:
        return '$minutes min';
    }
  }

  Widget _divider(ThemeData theme) {
    return Divider(
      height: 1,
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  Widget _buildAppIcon(InstalledAppModel app, bool isSelected) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
        alignment: Alignment.center,
        child: (app.iconBytes != null && app.iconBytes!.isNotEmpty)
            ? Image.memory(
                app.iconBytes!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.apps_rounded, size: 20),
      ),
    );
  }
}

class _OverlayQuotePayload {
  final String initialMessage;
  final String initialReference;
  final List<String> overlayMessages;
  final List<String> overlayReferences;

  const _OverlayQuotePayload({
    required this.initialMessage,
    required this.initialReference,
    required this.overlayMessages,
    required this.overlayReferences,
  });
}

class _PrayerWindowPayload {
  final int windowStartMs;
  final int nextPrayerStartMs;

  const _PrayerWindowPayload(this.windowStartMs, this.nextPrayerStartMs);
}
