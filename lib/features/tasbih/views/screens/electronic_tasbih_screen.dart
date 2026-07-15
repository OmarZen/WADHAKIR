import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/widgets/celebration.dart';

class ElectronicTasbihScreen extends StatefulWidget {
  const ElectronicTasbihScreen({super.key});

  @override
  State<ElectronicTasbihScreen> createState() => _ElectronicTasbihScreenState();
}

class _ElectronicTasbihScreenState extends State<ElectronicTasbihScreen>
    with TickerProviderStateMixin {
  int _counter = 0;
  int _totalCounter = 0;
  int _target = 33;
  bool _isPressed = false;

  late AnimationController _beadController;
  late AnimationController _counterAnimController;
  late Animation<double> _beadAnimation;
  late Animation<double> _counterScaleAnimation;

  static const String _counterKey = 'electronic_tasbih_counter';
  static const String _totalCounterKey = 'electronic_tasbih_total';
  static const String _targetKey = 'electronic_tasbih_target';

  @override
  void initState() {
    super.initState();
    _loadCounters();

    // Bead rotation animation
    _beadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _beadAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _beadController, curve: Curves.easeOut));

    // Counter scale animation
    _counterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _counterScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _counterAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _beadController.dispose();
    _counterAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt(_counterKey) ?? 0;
      _totalCounter = prefs.getInt(_totalCounterKey) ?? 0;
      _target = prefs.getInt(_targetKey) ?? 33;
    });
  }

  Future<void> _saveCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_counterKey, _counter);
    await prefs.setInt(_totalCounterKey, _totalCounter);
    await prefs.setInt(_targetKey, _target);
  }

  void _incrementCounter() {
    HapticFeedback.mediumImpact();
    setState(() {
      _counter++;
      _totalCounter++;
      _isPressed = true;
    });

    _beadController.forward(from: 0);
    _counterAnimController.forward().then((_) {
      _counterAnimController.reverse();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isPressed = false);
      }
    });

    if (_counter >= _target) {
      HapticFeedback.heavyImpact();
      _showCompletionDialog();
    }

    _saveCounters();
  }

  void _resetCounter() {
    HapticFeedback.lightImpact();
    setState(() {
      _counter = 0;
    });
    _saveCounters();
  }

  void _resetTotalCounter() {
    HapticFeedback.lightImpact();
    setState(() {
      _counter = 0;
      _totalCounter = 0;
    });
    _saveCounters();
  }

  void _showCompletionDialog() {
    final l10n = context.l10n;
    // Reward hitting the tasbih target with a confetti burst alongside the
    // existing celebration dialog.
    Celebration.burst(context);
    showFDialog(
      context: context,
      builder: (context, style, animation) {
        final theme = Theme.of(context);
        return FDialog(
          title: Row(
            children: [
              Icon(
                Icons.celebration_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.translate('tasbih.completion_title') ?? 'مبارك!',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ],
          ),
          body: Text(
            l10n?.translate('tasbih.completion_message') ??
                'أحسنت! لقد أكملت $_target تسبيحة',
          ),
          actions: [
            FButton(
              onPress: () {
                Navigator.of(context).pop();
                _resetCounter();
              },
              child: Text(l10n?.translate('tasbih.continue') ?? 'متابعة'),
            ),
          ],
        );
      },
    );
  }

  void _changeTarget() {
    final l10n = context.l10n;
    showFDialog(
      context: context,
      builder: (context, style, animation) {
        int tempTarget = _target;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return FDialog(
              title: Text(
                l10n?.translate('tasbih.change_target') ?? 'تغيير الهدف',
              ),
              // FDialog (forui) provides no Material ancestor, so the
              // FilterChip + TextField below need one or they throw
              // "No Material widget found".
              body: Material(
                type: MaterialType.transparency,
                child: ConstrainedBox(
                  // Bound the body height so the keyboard (resizeToAvoidInsets)
                  // can't collapse it into an overflow; scroll instead.
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n?.translate('tasbih.select_target') ??
                              'اختر عدد التسبيحات',
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [33, 99, 100, 1000].map((value) {
                            final isSelected = tempTarget == value;
                            return FilterChip(
                              label: Text('$value'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setDialogState(() {
                                  tempTarget = value;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                l10n?.translate('tasbih.custom_target') ??
                                'عدد مخصص',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed != null && parsed > 0) {
                              setDialogState(() {
                                tempTarget = parsed;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                FButton(
                  onPress: () {
                    setState(() {
                      _target = tempTarget;
                      if (_counter > _target) _counter = 0;
                    });
                    _saveCounters();
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n?.translate('tasbih.save') ?? 'حفظ'),
                ),
                FButton(
                  onPress: () => Navigator.of(context).pop(),
                  variant: FButtonVariant.outline,
                  child: Text(l10n?.translate('tasbih.cancel') ?? 'إلغاء'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = PlatformUtils.isDesktop;

    final progress = _target > 0 ? (_counter / _target).clamp(0.0, 1.0) : 0.0;

    // Single hero counter sized off the smaller of width/height so it never
    // dominates a wide screen or overflows a short one. Clamped to a calm range.
    final double heroDiameter = <double>[
      size.width * 0.66,
      size.height * 0.40,
      300.0,
    ].reduce((a, b) => a < b ? a : b).clamp(220.0, 300.0).toDouble();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n?.translate('home.electronic_tasbih') ?? 'مسبحة إلكترونية',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showFDialog(
                context: context,
                builder: (context, style, animation) => FDialog(
                  title: Text(
                    l10n?.translate('tasbih.about_title') ?? 'عن المسبحة',
                  ),
                  body: Text(
                    l10n?.translate('tasbih.about_description') ??
                        'المسبحة الإلكترونية تساعدك على عد التسبيحات والأذكار بسهولة.\n\nاضغط على الزر الأوسط للتسبيح.\n\nيمكنك تغيير الهدف وإعادة ضبط العداد من خلال الأزرار في الأسفل.',
                  ),
                  actions: [
                    FButton(
                      onPress: () => Navigator.pop(context),
                      child: Text(l10n?.translate('tasbih.close') ?? 'إغلاق'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 600 : double.infinity,
            ),
            child: Column(
              children: [
                Expanded(
                  // One hero counter + a stats card, centered with generous
                  // whitespace. Scrolls only if a short screen can't fit it.
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 16.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Single hero: progress ring + count + tap
                                  // target, framed by a subtle bead accent.
                                  _buildHeroCounter(
                                    theme,
                                    progress,
                                    heroDiameter,
                                  ),
                                  const SizedBox(height: 36),
                                  _buildStatisticsCard(theme, l10n, isDark),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom action buttons
                _buildBottomActions(theme, l10n, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The single focal element: a circular progress ring + a tappable inner
  /// disc showing the live count, framed by a subtle rotating bead accent.
  /// Replaces the old bead-circle + counter-pill + button stack so nothing
  /// crowds or overlaps.
  Widget _buildHeroCounter(ThemeData theme, double progress, double diameter) {
    final cs = theme.colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final ringSize = diameter * 0.88;
    final innerSize = diameter * 0.64;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle bead accent framing the ring (keeps the tasbih identity).
          _buildBeadRing(theme, diameter),

          // Progress toward the target.
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 9,
                strokeCap: StrokeCap.round,
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
          ),

          // Tappable inner disc with the live count.
          Semantics(
            button: true,
            label: context.l10n?.translate('tasbih.tap') ?? 'اضغط',
            child: GestureDetector(
              onTap: _incrementCounter,
              child: AnimatedScale(
                scale: _isPressed ? 0.96 : 1.0,
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeOut,
                child: Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.82)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _counterScaleAnimation,
                          child: Text(
                            '$_counter',
                            style: TextStyle(
                              fontSize: diameter * 0.24,
                              height: 1,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimary,
                              fontFamily: 'Almarai',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '/ $_target',
                          style: TextStyle(
                            fontSize: diameter * 0.075,
                            color: cs.onPrimary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n?.translate('tasbih.tap_to_count') ??
                              'اضغط للتسبيح',
                          style: TextStyle(
                            fontSize: diameter * 0.05,
                            color: cs.onPrimary.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Subtle ring of 33 small beads that rotates slightly on each tap — frames
  /// the progress ring without competing with the count.
  Widget _buildBeadRing(ThemeData theme, double diameter) {
    final cs = theme.colorScheme;
    final center = diameter / 2;
    final radius = diameter / 2 - 5;
    return AnimatedBuilder(
      animation: _beadAnimation,
      builder: (context, _) {
        final rotation = _beadAnimation.value * (2 * math.pi / 33);
        return SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            children: List.generate(33, (index) {
              final angle = (index * 2 * math.pi / 33) + rotation;
              final active = index < (_counter % 33);
              final beadSize = active ? 5.0 : 4.0;
              return Positioned(
                left: center + radius * math.cos(angle) - beadSize / 2,
                top: center + radius * math.sin(angle) - beadSize / 2,
                child: Container(
                  width: beadSize,
                  height: beadSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: active ? 0.55 : 0.18),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCard(
    ThemeData theme,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            theme,
            icon: Icons.all_inclusive,
            label: l10n?.translate('tasbih.total') ?? 'الإجمالي',
            value: '$_totalCounter',
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            theme,
            icon: Icons.flag_outlined,
            label: l10n?.translate('tasbih.target') ?? 'الهدف',
            value: '$_target',
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            theme,
            icon: Icons.trending_up,
            label: l10n?.translate('tasbih.progress') ?? 'التقدم',
            value: '${(_target > 0 ? (_counter / _target * 100).toInt() : 0)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(
    ThemeData theme,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: FButton(
                onPress: _resetCounter,
                variant: FButtonVariant.outline,
                prefix: const Icon(Icons.refresh, size: 18),
                child: Text(l10n?.translate('tasbih.reset') ?? 'إعادة ضبط'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FButton(
                onPress: _changeTarget,
                prefix: const Icon(Icons.edit_outlined, size: 18),
                child: Text(
                  l10n?.translate('tasbih.change_target') ?? 'تغيير الهدف',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _resetTotalCounter,
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip:
                  l10n?.translate('tasbih.reset_total') ?? 'إعادة ضبط الكل',
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
