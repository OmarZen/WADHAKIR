import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

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

  late AnimationController _pulseController;
  late AnimationController _beadController;
  late AnimationController _counterAnimController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _beadAnimation;
  late Animation<double> _counterScaleAnimation;

  static const String _counterKey = 'electronic_tasbih_counter';
  static const String _totalCounterKey = 'electronic_tasbih_total';
  static const String _targetKey = 'electronic_tasbih_target';

  @override
  void initState() {
    super.initState();
    _loadCounters();

    // Pulse animation for the counter button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
          content: Text(
            l10n?.translate('tasbih.completion_message') ??
                'أحسنت! لقد أكملت $_target تسبيحة',
          ),
          actions: [
            TextButton(
              onPressed: () {
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
    showDialog(
      context: context,
      builder: (context) {
        int tempTarget = _target;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                l10n?.translate('tasbih.change_target') ?? 'تغيير الهدف',
              ),
              content: Column(
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
                          l10n?.translate('tasbih.custom_target') ?? 'عدد مخصص',
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n?.translate('tasbih.cancel') ?? 'إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _target = tempTarget;
                      if (_counter > _target) _counter = 0;
                    });
                    _saveCounters();
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n?.translate('tasbih.save') ?? 'حفظ'),
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
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    l10n?.translate('tasbih.about_title') ?? 'عن المسبحة',
                  ),
                  content: Text(
                    l10n?.translate('tasbih.about_description') ??
                        'المسبحة الإلكترونية تساعدك على عد التسبيحات والأذكار بسهولة.\n\nاضغط على الزر الأوسط للتسبيح.\n\nيمكنك تغيير الهدف وإعادة ضبط العداد من خلال الأزرار في الأسفل.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Prayer beads visualization
                        _buildBeadCircle(theme, isDark, size),

                        // Main counter display
                        _buildCounterDisplay(theme, isDark),

                        // Main tasbih button with progress
                        _buildTasbihButton(theme, isDark, progress),

                        // Statistics card
                        _buildStatisticsCard(theme, l10n, isDark),
                      ],
                    ),
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

  Widget _buildBeadCircle(ThemeData theme, bool isDark, Size size) {
    return AnimatedBuilder(
      animation: _beadAnimation,
      builder: (context, child) {
        return SizedBox(
          width: size.width * 0.5,
          height: size.width * 0.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle with gradient
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
              // Prayer beads
              ...List.generate(33, (index) {
                final angle = (index * 360 / 33) * math.pi / 180;
                final rotationOffset = _beadAnimation.value * 360 / 33;
                final adjustedAngle = angle + (rotationOffset * math.pi / 180);
                final radius = size.width * 0.21;
                final beadSize = index == (_counter % 33) && _isPressed
                    ? 10.0
                    : index < (_counter % 33)
                    ? 8.0
                    : 6.0;

                return Positioned(
                  left:
                      size.width * 0.25 +
                      radius * math.cos(adjustedAngle) -
                      beadSize / 2,
                  top:
                      size.width * 0.25 +
                      radius * math.sin(adjustedAngle) -
                      beadSize / 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: beadSize,
                    height: beadSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: index < (_counter % 33)
                            ? [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ]
                            : [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: index < (_counter % 33)
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCounterDisplay(ThemeData theme, bool isDark) {
    return ScaleTransition(
      scale: _counterScaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$_counter',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontFamily: 'Almarai',
              ),
            ),
            Text(
              ' / $_target',
              style: TextStyle(
                fontSize: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasbihButton(ThemeData theme, bool isDark, double progress) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: _incrementCounter,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 48,
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n?.translate('tasbih.tap') ?? 'اضغط',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetCounter,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n?.translate('tasbih.reset') ?? 'إعادة ضبط'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _changeTarget,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(
                  l10n?.translate('tasbih.change_target') ?? 'تغيير الهدف',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
