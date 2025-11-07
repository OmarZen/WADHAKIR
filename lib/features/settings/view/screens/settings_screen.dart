import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/features/settings/view/widgets/settings_section.dart';
import 'package:wadhakir/features/settings/view/widgets/theme_selector_widget.dart';
import 'package:wadhakir/features/settings/view/widgets/about_section_widgets.dart';
import 'package:wadhakir/features/settings/view/widgets/language_selector_widget.dart';
import 'package:wadhakir/features/settings/view/widgets/adhan_sounds_section_widget.dart';
import 'package:wadhakir/features/settings/view/widgets/notification_settings_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.forward();

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : theme.colorScheme.primary.withValues(alpha: 0.05),
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return Center(
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
              );
            } else if (state is SettingsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is SettingsLoaded) {
              return _buildSettingsContent(context, state.settings, isDark);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    AppSettingsModel settings,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Futuristic Animated Header
        SliverToBoxAdapter(
          child: _buildFuturisticHeader(context, l10n, theme, isDark),
        ),

        // Settings Sections with Staggered Animation
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildAnimatedSection(
                delay: 0,
                child: SettingsSection(
                  title: l10n?.translate('settings.theme') ?? 'السمة',
                  icon: Icons.palette_outlined,
                  subtitle: l10n?.translate('settings.theme_subtitle') ??
                      'تخصيص مظهر التطبيق',
                  children: [
                    ThemeSelectorWidget(settings: settings, cubit: cubit),
                  ],
                ),
              ),
              _buildAnimatedSection(
                delay: 100,
                child: SettingsSection(
                  title: l10n?.translate('settings.language') ?? 'اللغة',
                  icon: Icons.language_outlined,
                  subtitle: l10n?.translate('settings.language_subtitle') ??
                      'تغيير لغة التطبيق',
                  children: [
                    LanguageSelectorWidget(settings: settings, cubit: cubit)
                  ],
                ),
              ),
              _buildAnimatedSection(
                delay: 200,
                child: SettingsSection(
                  title:
                      l10n?.translate('settings.notifications') ?? 'التنبيهات',
                  icon: Icons.notifications_outlined,
                  subtitle:
                      l10n?.translate('settings.notifications_subtitle') ??
                          'تنبيهات أوقات الصلاة',
                  children: [
                    NotificationSettingsWidgets.buildNotificationMasterToggle(
                        context, settings, cubit),
                    if (settings.notificationSettings.masterEnabled) ...[
                      _buildDivider(theme),
                      NotificationSettingsWidgets
                          .buildPersistentNotificationToggle(
                              context, settings, cubit),
                      _buildDivider(theme),
                      NotificationSettingsWidgets
                          .buildNotificationTimingSelector(
                              context, settings, cubit),
                      _buildDivider(theme),
                      const AdhanSoundsSectionWidget(),
                      _buildDivider(theme),
                      NotificationSettingsWidgets
                          .buildPrayerNotificationsSettings(
                              context, settings, cubit),
                    ],
                  ],
                ),
              ),
              _buildAnimatedSection(
                delay: 300,
                child: SettingsSection(
                  title: l10n?.translate('settings.about_app') ?? 'حول التطبيق',
                  icon: Icons.info_outline,
                  subtitle: l10n?.translate('settings.about_subtitle') ??
                      'معلومات عن التطبيق',
                  children: [
                    AboutSectionWidgets.buildAboutTile(context),
                    AboutSectionWidgets.buildFeedbackTile(context),
                    AboutSectionWidgets.buildWebsiteTile(context),
                    AboutSectionWidgets.buildPrivacyTile(context),
                    AboutSectionWidgets.buildRateAppTile(context),
                  ],
                ),
              ),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildFuturisticHeader(
    BuildContext context,
    AppLocalizations? l10n,
    ThemeData theme,
    bool isDark,
  ) {
    final headerOpacity = (1 - (_scrollOffset / 200)).clamp(0.0, 1.0);
    final headerScale = (1 - (_scrollOffset / 1000)).clamp(0.85, 1.0);

    // Get current settings from BlocBuilder context
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final settings = state is SettingsLoaded ? state.settings : null;

        // Count active notifications
        final notificationCount =
            settings != null ? _countActiveNotifications(settings) : 0;

        // Get language display
        final languageDisplay = settings?.languageCode == 'ar' ? 'AR' : 'EN';

        // Get theme mode display
        String themeModeDisplay;
        if (settings?.themeMode == ThemeMode.system) {
          themeModeDisplay = l10n?.translate('settings.system') ?? 'النظام';
        } else if (settings?.themeMode == ThemeMode.light) {
          themeModeDisplay = l10n?.translate('settings.light') ?? 'فاتح';
        } else {
          themeModeDisplay = l10n?.translate('settings.dark') ?? 'داكن';
        }

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: headerScale,
              child: Opacity(
                opacity: headerOpacity,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                            ]
                          : [
                              theme.colorScheme.primary.withValues(alpha: 0.95),
                              theme.colorScheme.primary.withValues(alpha: 0.75),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Animated Icon Container
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Transform.rotate(
                                  angle: (1 - value) * 0.5,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? [
                                                Colors.white
                                                    .withValues(alpha: 0.2),
                                                Colors.white
                                                    .withValues(alpha: 0.05),
                                              ]
                                            : [
                                                Colors.white
                                                    .withValues(alpha: 0.3),
                                                Colors.white
                                                    .withValues(alpha: 0.1),
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.settings_suggest,
                                      size: 30,
                                      color: isDark
                                          ? Colors.white
                                          : theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 20),
                          // Title and Subtitle with Slide Animation
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TweenAnimationBuilder(
                                  tween: Tween<Offset>(
                                    begin: const Offset(-50, 0),
                                    end: Offset.zero,
                                  ),
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, Offset offset, child) {
                                    return Transform.translate(
                                      offset: offset,
                                      child: Opacity(
                                        opacity: offset.dx == 0 ? 1 : 0,
                                        child: Text(
                                          l10n?.translate('settings.title') ??
                                              'الإعدادات',
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : theme.colorScheme.onPrimary,
                                            fontSize: 24,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 6),
                                TweenAnimationBuilder(
                                  tween: Tween<Offset>(
                                    begin: const Offset(-30, 0),
                                    end: Offset.zero,
                                  ),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, Offset offset, child) {
                                    return Transform.translate(
                                      offset: offset,
                                      child: Opacity(
                                        opacity: offset.dx == 0 ? 1 : 0.5,
                                        child: Text(
                                          l10n?.translate(
                                                  'settings.description') ??
                                              'خصص تجربتك مع التطبيق',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: (isDark
                                                    ? Colors.white
                                                    : theme
                                                        .colorScheme.onPrimary)
                                                .withValues(alpha: 0.85),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Animated Stats Bar with Real Data
                      const SizedBox(height: 20),
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildAnimatedStatItem(
                                    Icons.notifications_active,
                                    notificationCount.toString(),
                                    l10n?.translate(
                                            'settings.notifications_count') ??
                                        'إشعار',
                                    theme,
                                    isDark,
                                    true, // Bell ringing animation
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  _buildAnimatedStatItem(
                                    Icons.language,
                                    languageDisplay,
                                    l10n?.translate('settings.language') ??
                                        'اللغة',
                                    theme,
                                    isDark,
                                    false, // Rotating globe animation
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  _buildAnimatedStatItem(
                                    Icons.palette,
                                    themeModeDisplay,
                                    l10n?.translate('settings.theme') ??
                                        'السمة',
                                    theme,
                                    isDark,
                                    false,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
  }

  int _countActiveNotifications(AppSettingsModel settings) {
    if (!settings.notificationSettings.masterEnabled) return 0;

    int count = 0;
    if (settings.notificationSettings.fajrSettings.enabled) count++;
    if (settings.notificationSettings.dhuhrSettings.enabled) count++;
    if (settings.notificationSettings.asrSettings.enabled) count++;
    if (settings.notificationSettings.maghribSettings.enabled) count++;
    if (settings.notificationSettings.ishaSettings.enabled) count++;

    return count;
  }

  Widget _buildAnimatedStatItem(
    IconData icon,
    String value,
    String label,
    ThemeData theme,
    bool isDark,
    bool shouldAnimate,
  ) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (context, animValue, child) {
        return Column(
          children: [
            // Animated Icon with loop
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeInOut,
              onEnd: () {
                // Loop animation by rebuilding after a delay
                if (mounted) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) setState(() {});
                  });
                }
              },
              builder: (context, loopValue, child) {
                final angle = shouldAnimate
                    ? (loopValue < 0.5
                        ? loopValue * 0.4
                        : (1 - loopValue) * 0.4)
                    : loopValue * 6.28; // Full rotation for globe

                return Transform.rotate(
                  angle: angle,
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDark ? Colors.white : theme.colorScheme.onPrimary,
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : theme.colorScheme.onPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: (isDark ? Colors.white : theme.colorScheme.onPrimary)
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedSection({
    required int delay,
    required Widget child,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
      ),
    );
  }
}
