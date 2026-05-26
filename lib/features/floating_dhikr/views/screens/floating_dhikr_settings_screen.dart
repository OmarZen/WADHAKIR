import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:wadhakir/core/design/design_tokens.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

import '../../data/floating_dhikr_settings.dart';
import '../../service/floating_dhikr_service.dart';
import '../widgets/pill_preview.dart';
import '../widgets/position_picker.dart';

/// User-facing settings for the floating adhkar reminder.
///
/// Minimalist redesign: a clean app bar, a single hero preview card so
/// the user immediately understands the feature, then a grouped settings
/// surface with subtle dividers instead of five separate cards. All
/// accent colors derive from the brand `#20497D` blue — `colorScheme
/// .secondary` (`#0D1122`, near-black) is intentionally never used.
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

  // -- Brand palette ----------------------------------------------------
  // Pinned to the same primary blues that the onboarding + share card use
  // so the whole "soft Islamic" surface family feels like one design.
  static const Color _brandPrimary = Color(0xFF20497D);
  static const Color _brandAccent = Color(0xFF3A6BA8);
  static const Color _surfaceTintLight = Color(0xFFEEF3FB);
  static const Color _surfaceTintDark = Color(0xFF0F1A2A);

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
    // OEM builds; awaiting it before setState() left the Switch stuck in
    // the previous position.
    setState(() => _settings = next);
    unawaited(_service.updateSettings(next));
  }

  Future<void> _toggleEnabled(bool value) async {
    if (value && !_service.isSupported) {
      _showSnack(
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
        _showSnack(
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
        _showSnack(
          l10n?.translate('floating_dhikr.preview_success') ??
              'ظهر التذكير الآن في أعلى الشاشة لمدة 10 ثوانٍ.',
          Icons.check_circle_outline,
        );
        break;
      case FloatingDhikrEmitResult.unsupported:
        _showSnack(
          l10n?.translate('floating_dhikr.unsupported_platform') ??
              'هذه الميزة متاحة على نظام أندرويد فقط',
          Icons.info_outline,
        );
        break;
      case FloatingDhikrEmitResult.missingPermission:
        _showSnack(
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
        _showSnack(
          l10n?.translate('floating_dhikr.no_content') ??
              'لم يتم العثور على أذكار من المصدر المختار.',
          Icons.warning_amber_outlined,
        );
        break;
      case FloatingDhikrEmitResult.platformError:
        _showSnack(
          l10n?.translate('floating_dhikr.platform_error') ??
              'تعذّر إظهار التذكير. حاول مرة أخرى.',
          Icons.error_outline,
        );
        break;
    }
  }

  void _showSnack(String message, IconData icon, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: Spacing.md),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(Spacing.md),
        backgroundColor: _brandPrimary,
        action: action,
      ),
    );
  }

  // -- Build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final effectivelyEnabled =
        _settings.enabled && _hasPermission && _service.isSupported;

    return Scaffold(
      backgroundColor: isDark ? _surfaceTintDark : _surfaceTintLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : _brandPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n?.translate('floating_dhikr.title') ?? 'تذكير الأذكار العائم',
          style: TextStyle(
            color: isDark ? Colors.white : _brandPrimary,
            fontFamily: 'Almarai',
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _brandPrimary),
            )
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.sm,
                  Spacing.lg,
                  Spacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroPreview(
                      isActive: effectivelyEnabled,
                      hasPermission: _hasPermission,
                      isSupported: _service.isSupported,
                      previewOpacity: _settings.opacity,
                      l10n: l10n,
                      isDark: isDark,
                    ),
                    if (!_service.isSupported) ...[
                      const SizedBox(height: Spacing.md),
                      _Banner(
                        icon: Icons.info_outline,
                        tone: _BannerTone.info,
                        text: l10n?.translate(
                              'floating_dhikr.unsupported_platform',
                            ) ??
                            'هذه الميزة متاحة على نظام أندرويد فقط',
                      ),
                    ] else if (!_hasPermission) ...[
                      const SizedBox(height: Spacing.md),
                      _Banner(
                        icon: Icons.shield_outlined,
                        tone: _BannerTone.warning,
                        text: l10n?.translate(
                              'floating_dhikr.permission_explainer',
                            ) ??
                            'يحتاج التطبيق إلى صلاحية الظهور فوق التطبيقات الأخرى لعرض التذكير.',
                        actionLabel: l10n?.translate(
                              'floating_dhikr.grant_permission',
                            ) ??
                            'منح الصلاحية',
                        onAction: () async {
                          final granted =
                              await _service.requestPermission();
                          if (!mounted) return;
                          setState(() => _hasPermission = granted);
                        },
                      ),
                    ],
                    const SizedBox(height: Spacing.lg),
                    _MasterToggle(
                      value: effectivelyEnabled,
                      onChanged: _toggleEnabled,
                      l10n: l10n,
                    ),
                    const SizedBox(height: Spacing.lg),
                    _SettingsGroup(
                      isDark: isDark,
                      children: [
                        _GroupRow(
                          icon: Icons.timer_outlined,
                          label: l10n?.translate('floating_dhikr.interval') ??
                              'كل كم دقيقة',
                          child: _IntervalChips(
                            value: _settings.interval.inMinutes,
                            onChanged: (m) => _persist(
                              _settings.copyWith(
                                interval: Duration(minutes: m),
                              ),
                            ),
                            l10n: l10n,
                          ),
                        ),
                        const _GroupDivider(),
                        _GroupRow(
                          icon: Icons.menu_book_rounded,
                          label: l10n?.translate('floating_dhikr.source') ??
                              'مصدر الأذكار',
                          child: _SourceChips(
                            value: _settings.source,
                            onChanged: (s) =>
                                _persist(_settings.copyWith(source: s)),
                            l10n: l10n,
                          ),
                        ),
                        const _GroupDivider(),
                        _GroupRow(
                          icon: Icons.crop_free_rounded,
                          label: l10n?.translate('floating_dhikr.position') ??
                              'مكان الظهور',
                          child: PositionPicker(
                            selected: _settings.position,
                            onSelected: (anchor) => _persist(
                              _settings.copyWith(position: anchor),
                            ),
                          ),
                        ),
                        const _GroupDivider(),
                        _GroupRow(
                          icon: Icons.opacity_rounded,
                          label: l10n?.translate('floating_dhikr.opacity') ??
                              'الشفافية',
                          child: _OpacityControl(
                            value: _settings.opacity,
                            onPreview: (v) => setState(
                              () => _settings =
                                  _settings.copyWith(opacity: v),
                            ),
                            onCommit: (v) =>
                                _persist(_settings.copyWith(opacity: v)),
                          ),
                        ),
                        const _GroupDivider(),
                        _GroupRow(
                          icon: Icons.notifications_paused_rounded,
                          label: l10n?.translate(
                                'floating_dhikr.pause_during_prayer',
                              ) ??
                              'إيقاف أثناء وقت الصلاة',
                          inline: true,
                          child: Switch.adaptive(
                            value: _settings.pauseDuringPrayer,
                            onChanged: (v) => _persist(
                              _settings.copyWith(pauseDuringPrayer: v),
                            ),
                            activeThumbColor: _brandPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl),
                    if (_service.isSupported && _hasPermission)
                      _PrimaryCta(
                        label: l10n?.translate(
                              'floating_dhikr.preview_now',
                            ) ??
                            'معاينة الآن',
                        icon: Icons.visibility_outlined,
                        loading: _previewing,
                        onPressed: _preview,
                      ),
                    if (_service.isSupported && _hasPermission) ...[
                      const SizedBox(height: Spacing.sm),
                      Text(
                        l10n?.translate('floating_dhikr.preview_hint') ??
                            'سيظهر التذكير بمكانه وحجمه الفعلي لمدة قصيرة',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ],
                    if (effectivelyEnabled) ...[
                      const SizedBox(height: Spacing.lg),
                      _SecondaryCta(
                        label: l10n?.translate(
                              'floating_dhikr.stop_now',
                            ) ??
                            'إيقاف الآن',
                        icon: Icons.stop_circle_outlined,
                        danger: true,
                        onPressed: () async {
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);
                          final stoppedMsg = l10n?.translate(
                                'floating_dhikr.stopped',
                              ) ??
                              'تم إيقاف التذكير العائم.';
                          await _service.closeOverlay();
                          await _persist(_settings.copyWith(enabled: false));
                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(stoppedMsg),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

// ================================================================ Atoms ===
// All atomic widgets live below and key off the same constants as the
// screen so the look stays consistent. They take dumb data and emit
// events back to the parent — no state of their own.

class _HeroPreview extends StatelessWidget {
  const _HeroPreview({
    required this.isActive,
    required this.hasPermission,
    required this.isSupported,
    required this.previewOpacity,
    required this.l10n,
    required this.isDark,
  });

  final bool isActive;
  final bool hasPermission;
  final bool isSupported;
  final double previewOpacity;
  final AppLocalizations? l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _FloatingDhikrSettingsScreenState._brandPrimary,
            _FloatingDhikrSettingsScreenState._brandAccent,
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: [
          BoxShadow(
            color: _FloatingDhikrSettingsScreenState._brandPrimary.withValues(
              alpha: 0.30,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.preview_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                l10n?.translate('floating_dhikr.preview_label') ?? 'معاينة',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontFamily: 'Almarai',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              _StatusDot(
                isActive: isActive,
                hasPermission: hasPermission,
                isSupported: isSupported,
                l10n: l10n,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          PillPreview(opacity: previewOpacity),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.isActive,
    required this.hasPermission,
    required this.isSupported,
    required this.l10n,
  });

  final bool isActive;
  final bool hasPermission;
  final bool isSupported;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final (color, text) = _resolveStatus();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Almarai',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _resolveStatus() {
    if (!isSupported) {
      return (
        Colors.white70,
        l10n?.translate('floating_dhikr.status_needs_permission') ??
            'يحتاج صلاحية',
      );
    }
    if (isActive) {
      return (
        const Color(0xFF36CF74),
        l10n?.translate('floating_dhikr.status_active') ?? 'مفعّل',
      );
    }
    if (hasPermission) {
      return (
        Colors.amber.shade300,
        l10n?.translate('floating_dhikr.status_paused') ?? 'متوقف',
      );
    }
    return (
      Colors.white70,
      l10n?.translate('floating_dhikr.status_needs_permission') ??
          'يحتاج صلاحية',
    );
  }
}

class _MasterToggle extends StatelessWidget {
  const _MasterToggle({
    required this.value,
    required this.onChanged,
    required this.l10n,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(Radii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _FloatingDhikrSettingsScreenState._brandPrimary
                      .withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.bubble_chart_rounded,
                  color: _FloatingDhikrSettingsScreenState._brandPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.translate('floating_dhikr.enable_label') ??
                          'تفعيل التذكير العائم',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n?.translate('floating_dhikr.enable_subtitle') ??
                          'يظهر ذكر كل فترة زمنية فوق أي تطبيق تستخدمه',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor:
                    _FloatingDhikrSettingsScreenState._brandPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single grouped surface that holds all secondary settings. Subtle
/// dividers separate rows so the page reads as one card instead of five
/// floating tiles.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children, required this.isDark});

  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(Radii.md),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(children: children),
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      thickness: 0.6,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
    );
  }
}

/// One labelled row inside [_SettingsGroup].
///
/// `inline: true` puts the [child] on the right of the label (used for a
/// trailing toggle). The default lays the child below the label.
class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.icon,
    required this.label,
    required this.child,
    this.inline = false,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final header = Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: _FloatingDhikrSettingsScreenState._brandPrimary,
        ),
        const SizedBox(width: Spacing.sm),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontFamily: 'Almarai',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: inline
          ? Row(
              children: [
                Expanded(child: header),
                child,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: Spacing.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: child,
                ),
              ],
            ),
    );
  }
}

class _IntervalChips extends StatelessWidget {
  const _IntervalChips({
    required this.value,
    required this.onChanged,
    required this.l10n,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [5, 10, 15, 30, 60].map((m) {
        final selected = value == m;
        return _BrandChip(
          label: '$m ${l10n?.translate('floating_dhikr.minutes') ?? 'د'}',
          selected: selected,
          onTap: () => onChanged(m),
        );
      }).toList(),
    );
  }
}

class _SourceChips extends StatelessWidget {
  const _SourceChips({
    required this.value,
    required this.onChanged,
    required this.l10n,
  });

  final DhikrSource value;
  final ValueChanged<DhikrSource> onChanged;
  final AppLocalizations? l10n;

  IconData _iconFor(DhikrSource s) {
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

  String _labelFor(DhikrSource s) {
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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: DhikrSource.values.map((s) {
        return _BrandChip(
          label: _labelFor(s),
          icon: _iconFor(s),
          selected: s == value,
          onTap: () => onChanged(s),
        );
      }).toList(),
    );
  }
}

/// Brand-tinted chip — replaces Material's default `ChoiceChip` so we get
/// consistent colors with the rest of the page. Selected = primary-tinted
/// fill + primary border + primary label; idle = transparent fill with
/// a soft hairline.
class _BrandChip extends StatelessWidget {
  const _BrandChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const brand = _FloatingDhikrSettingsScreenState._brandPrimary;
    return Material(
      color: selected ? brand.withValues(alpha: 0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: selected
                  ? brand
                  : theme.colorScheme.onSurface.withValues(alpha: 0.14),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? brand
                      : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: selected
                      ? brand
                      : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slider + live percentage badge.
class _OpacityControl extends StatelessWidget {
  const _OpacityControl({
    required this.value,
    required this.onPreview,
    required this.onCommit,
  });

  final double value;
  final ValueChanged<double> onPreview;
  final ValueChanged<double> onCommit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const brand = _FloatingDhikrSettingsScreenState._brandPrimary;
    return Row(
      children: [
        Icon(
          Icons.brightness_low_rounded,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: brand,
              inactiveTrackColor: brand.withValues(alpha: 0.16),
              thumbColor: brand,
              overlayColor: brand.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: 0.6,
              max: 1.0,
              divisions: 8,
              label: '${(value * 100).round()}%',
              onChanged: onPreview,
              onChangeEnd: onCommit,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: brand.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              color: brand,
              fontFamily: 'Almarai',
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _FloatingDhikrSettingsScreenState._brandPrimary,
              _FloatingDhikrSettingsScreenState._brandAccent,
            ],
          ),
          borderRadius: BorderRadius.circular(Radii.md),
          boxShadow: [
            BoxShadow(
              color: _FloatingDhikrSettingsScreenState._brandPrimary
                  .withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: loading ? null : onPressed,
          splashColor: Colors.white.withValues(alpha: 0.18),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Almarai',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
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

class _SecondaryCta extends StatelessWidget {
  const _SecondaryCta({
    required this.label,
    required this.icon,
    required this.danger,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  /// When `true`, paints with `colorScheme.error`. Otherwise the brand
  /// primary blue. Used here only for the "stop now" button — that
  /// destructive action should look slightly different from the brand.
  final bool danger;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger
        ? theme.colorScheme.error
        : _FloatingDhikrSettingsScreenState._brandPrimary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Almarai',
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.2),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
    );
  }
}

enum _BannerTone { info, warning }

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.tone,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final _BannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tone == _BannerTone.warning
        ? Colors.orange.shade700
        : _FloatingDhikrSettingsScreenState._brandPrimary;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Almarai',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: Spacing.xs),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontFamily: 'Almarai',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
