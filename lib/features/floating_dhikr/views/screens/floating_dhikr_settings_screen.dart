import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

import '../../data/floating_dhikr_settings.dart';
import '../../service/floating_dhikr_service.dart';
import '../widgets/floating_dhikr_header.dart';
import '../widgets/position_picker.dart';

/// User-facing settings for the floating adhkar reminder. Lets the user
/// enable the feature, pick interval / position / source, and request the
/// overlay permission when needed.
class FloatingDhikrSettingsScreen extends StatefulWidget {
  const FloatingDhikrSettingsScreen({super.key});

  @override
  State<FloatingDhikrSettingsScreen> createState() =>
      _FloatingDhikrSettingsScreenState();
}

class _FloatingDhikrSettingsScreenState
    extends State<FloatingDhikrSettingsScreen> {
  final _service = FloatingDhikrService.instance;
  FloatingDhikrSettings _settings = const FloatingDhikrSettings();
  bool _loading = true;
  bool _hasPermission = false;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _service.getSettings();
    final perm = await _service.hasPermission();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _hasPermission = perm;
      _loading = false;
    });
  }

  Future<void> _persist(FloatingDhikrSettings next) async {
    dev.log(
      '_persist: enabled=${next.enabled} interval=${next.interval.inMinutes}m',
      name: 'FloatingDhikrSettings',
    );
    // OPTIMISTIC UI: update local state synchronously FIRST so the Switch
    // reflects the user's tap immediately. The platform-side teardown
    // (closeOverlay) inside updateSettings can occasionally hang on some
    // OEM builds, and awaiting it before setState() left the Switch stuck
    // in the previous position. Fire-and-forget the persist; the next
    // _load() will resync from disk if anything went wrong.
    setState(() => _settings = next);
    dev.log(
      '_persist: setState complete (optimistic), _settings.enabled=${_settings.enabled}',
      name: 'FloatingDhikrSettings',
    );
    // Run the slow part asynchronously without blocking the UI.
    unawaited(_service.updateSettings(next));
  }

  Future<void> _toggleEnabled(bool value) async {
    dev.log(
      '_toggleEnabled: value=$value supported=${_service.isSupported} '
      'hasPermission=$_hasPermission',
      name: 'FloatingDhikrSettings',
    );
    if (value && !_service.isSupported) {
      _showSnackbar(
        context.l10n?.translate('floating_dhikr.unsupported_platform') ??
            'هذه الميزة متاحة على نظام أندرويد فقط',
        Icons.info_outline,
      );
      return;
    }
    if (value && !_hasPermission) {
      final granted = await _service.requestPermission();
      if (!mounted) return;
      setState(() => _hasPermission = granted);
      if (!granted) {
        _showSnackbar(
          context.l10n?.translate('floating_dhikr.permission_denied') ??
              'لم يتم منح الصلاحية. لا يمكن تفعيل التذكير العائم.',
          Icons.error_outline,
        );
        return;
      }
    }
    await _persist(_settings.copyWith(enabled: value));
  }

  Future<void> _preview() async {
    setState(() => _previewing = true);
    final result = await _service.emitOnce();
    if (!mounted) return;
    setState(() => _previewing = false);
    final l10n = context.l10n;
    switch (result) {
      case FloatingDhikrEmitResult.ok:
        // Don't minimise the app on success — earlier we called
        // SystemNavigator.pop() but on some OEM skins (XOS in particular)
        // this kills the main activity and tears the overlay down with it.
        // The SYSTEM_ALERT_WINDOW pill is drawn ABOVE the current app
        // anyway, so showing a snackbar pointing the user to the top of
        // the screen is enough.
        _showSnackbar(
          l10n?.translate('floating_dhikr.preview_success') ??
              'ظهر التذكير الآن في أعلى الشاشة لمدة 10 ثوانٍ.',
          Icons.check_circle_outline,
        );
        break;
      case FloatingDhikrEmitResult.unsupported:
        _showSnackbar(
          l10n?.translate('floating_dhikr.unsupported_platform') ??
              'هذه الميزة متاحة على نظام أندرويد فقط',
          Icons.info_outline,
        );
        break;
      case FloatingDhikrEmitResult.missingPermission:
        _showSnackbar(
          l10n?.translate('floating_dhikr.permission_explainer') ??
              'يحتاج التطبيق إلى صلاحية الظهور فوق التطبيقات الأخرى لعرض التذكير.',
          Icons.shield_outlined,
          action: SnackBarAction(
            label: l10n?.translate('floating_dhikr.grant_permission') ??
                'منح الصلاحية',
            onPressed: () async {
              final granted = await _service.requestPermission();
              if (!mounted) return;
              setState(() => _hasPermission = granted);
            },
          ),
        );
        break;
      case FloatingDhikrEmitResult.noContent:
        _showSnackbar(
          l10n?.translate('floating_dhikr.no_content') ??
              'لم يتم العثور على أذكار من المصدر المختار.',
          Icons.warning_amber_outlined,
        );
        break;
      case FloatingDhikrEmitResult.platformError:
        _showSnackbar(
          l10n?.translate('floating_dhikr.platform_error') ??
              'تعذّر إظهار التذكير. حاول مرة أخرى.',
          Icons.error_outline,
        );
        break;
    }
  }

  void _showSnackbar(String message, IconData icon, {SnackBarAction? action}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onInverseSurface, size: 20),
            const SizedBox(width: Spacing.md),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(Spacing.md),
        action: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final effectivelyEnabled =
        _settings.enabled && _hasPermission && _service.isSupported;

    return Scaffold(
      // Custom hero header replaces the default AppBar entirely.
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          FloatingDhikrHeader(
            isActive: effectivelyEnabled,
            hasPermission: _hasPermission,
            previewOpacity: _settings.opacity,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.xxl,
            ),
            child: _buildBody(theme, l10n, effectivelyEnabled),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations? l10n,
      bool effectivelyEnabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_service.isSupported)
            _InfoBanner(
              icon: Icons.info_outline,
              text: l10n?.translate('floating_dhikr.unsupported_platform') ??
                  'هذه الميزة متاحة على نظام أندرويد فقط',
              tone: _BannerTone.info,
            ),
          if (_service.isSupported && !_hasPermission)
            _InfoBanner(
              icon: Icons.shield_outlined,
              text: l10n?.translate('floating_dhikr.permission_explainer') ??
                  'يحتاج التطبيق إلى صلاحية الظهور فوق التطبيقات الأخرى لعرض التذكير.',
              tone: _BannerTone.warning,
              actionLabel:
                  l10n?.translate('floating_dhikr.grant_permission') ??
                      'منح الصلاحية',
              onAction: () async {
                final granted = await _service.requestPermission();
                if (!mounted) return;
                setState(() => _hasPermission = granted);
              },
            ),

          // Master toggle in its own card so it reads as the primary action.
          _SettingCard(
            child: SwitchListTile(
              value: effectivelyEnabled,
              onChanged: _toggleEnabled,
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n?.translate('floating_dhikr.enable_label') ??
                    'تفعيل التذكير العائم',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n?.translate('floating_dhikr.enable_subtitle') ??
                      'يظهر ذكر كل فترة زمنية فوق أي تطبيق تستخدمه',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bubble_chart_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),

          _SectionLabel(
            label: l10n?.translate('floating_dhikr.interval') ?? 'كل كم دقيقة',
            icon: Icons.timer_outlined,
          ),
          _SettingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [5, 10, 15, 30, 60].map((m) {
                    final selected = _settings.interval.inMinutes == m;
                    return ChoiceChip(
                      label: Text(
                        '$m ${l10n?.translate('floating_dhikr.minutes') ?? 'د'}',
                      ),
                      selected: selected,
                      onSelected: (_) => _persist(
                        _settings.copyWith(interval: Duration(minutes: m)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          _SectionLabel(
            label: l10n?.translate('floating_dhikr.position') ?? 'مكان الظهور',
            icon: Icons.crop_free_rounded,
          ),
          _SettingCard(
            child: PositionPicker(
              selected: _settings.position,
              onSelected: (anchor) =>
                  _persist(_settings.copyWith(position: anchor)),
            ),
          ),
          const SizedBox(height: Spacing.lg),

          _SectionLabel(
            label: l10n?.translate('floating_dhikr.opacity') ?? 'الشفافية',
            icon: Icons.opacity_rounded,
          ),
          _SettingCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.brightness_low_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    Expanded(
                      child: Slider(
                        value: _settings.opacity,
                        min: 0.6,
                        max: 1.0,
                        divisions: 8,
                        label: '${(_settings.opacity * 100).round()}%',
                        onChanged: (v) =>
                            setState(() => _settings = _settings.copyWith(opacity: v)),
                        onChangeEnd: (v) =>
                            _persist(_settings.copyWith(opacity: v)),
                      ),
                    ),
                    Icon(
                      Icons.brightness_high_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${(_settings.opacity * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          _SectionLabel(
            label: l10n?.translate('floating_dhikr.source') ?? 'مصدر الأذكار',
            icon: Icons.menu_book_rounded,
          ),
          _SettingCard(
            child: Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: DhikrSource.values.map((s) {
                final selected = _settings.source == s;
                return ChoiceChip(
                  label: Text(_sourceLabel(s, l10n)),
                  avatar: Icon(_sourceIcon(s), size: 16),
                  selected: selected,
                  onSelected: (_) => _persist(_settings.copyWith(source: s)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: Spacing.lg),

          _SectionLabel(
            label: l10n?.translate('floating_dhikr.behaviour') ?? 'السلوك',
            icon: Icons.tune_rounded,
          ),
          _SettingCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: _settings.pauseDuringPrayer,
                  onChanged: (v) =>
                      _persist(_settings.copyWith(pauseDuringPrayer: v)),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n?.translate('floating_dhikr.pause_during_prayer') ??
                        'إيقاف أثناء وقت الصلاة',
                  ),
                  subtitle: Text(
                    l10n?.translate('floating_dhikr.pause_during_prayer_hint') ??
                        'لا تظهر التذكيرات أثناء أوقات الصلاة المجدولة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          if (_service.isSupported && _hasPermission)
            FilledButton.icon(
              onPressed: _previewing ? null : _preview,
              icon: _previewing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.visibility_outlined),
              label: Text(
                l10n?.translate('floating_dhikr.preview_now') ??
                    'معاينة الآن',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
              ),
            ),
          const SizedBox(height: Spacing.sm),
          if (_service.isSupported && _hasPermission)
            Text(
              l10n?.translate('floating_dhikr.preview_hint') ??
                  'سيظهر التذكير بمكانه وحجمه الفعلي لمدة قصيرة',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),

          // Explicit "Stop now" backup so users can disable the feature
          // even if the master switch above ever misfires. Also closes any
          // currently-showing pill bar immediately.
          if (effectivelyEnabled) ...[
            const SizedBox(height: Spacing.lg),
            OutlinedButton.icon(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                await _service.closeOverlay();
                await _persist(_settings.copyWith(enabled: false));
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.translate('floating_dhikr.stopped') ??
                          'تم إيقاف التذكير العائم.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(
                l10n?.translate('floating_dhikr.stop_now') ?? 'إيقاف الآن',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
              ),
            ),
          ],
        ],
      );
  }

  IconData _sourceIcon(DhikrSource s) {
    switch (s) {
      case DhikrSource.random:
        return Icons.shuffle_rounded;
      case DhikrSource.morning:
        return Icons.wb_sunny_rounded;
      case DhikrSource.evening:
        return Icons.nightlight_round;
      case DhikrSource.prayer:
        return Icons.mosque_rounded;
      case DhikrSource.tasbih:
        return Icons.touch_app_rounded;
    }
  }

  String _sourceLabel(DhikrSource s, AppLocalizations? l10n) {
    switch (s) {
      case DhikrSource.random:
        return l10n?.translate('floating_dhikr.source_random') ?? 'متنوع';
      case DhikrSource.morning:
        return l10n?.translate('floating_dhikr.source_morning') ??
            'أذكار الصباح';
      case DhikrSource.evening:
        return l10n?.translate('floating_dhikr.source_evening') ??
            'أذكار المساء';
      case DhikrSource.prayer:
        return l10n?.translate('floating_dhikr.source_prayer') ??
            'أذكار الصلاة';
      case DhikrSource.tasbih:
        return l10n?.translate('floating_dhikr.source_tasbih') ?? 'تسبيح';
    }
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Material wrapper so SwitchListTile / ListTile children render their
    // ink splash and background correctly. A plain Container has no Material
    // ancestor and Flutter raises the "ListTile background color or ink
    // splashes may be invisible" framework warning.
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(Radii.md),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xs,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: Spacing.sm),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BannerTone { info, warning }

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final _BannerTone tone;

  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.tone,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tone == _BannerTone.warning
        ? Colors.orange.shade700
        : theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodyMedium),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: Spacing.sm),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
