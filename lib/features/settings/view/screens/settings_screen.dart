import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/data/models/app_settings_model.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/settings/cubit/settings_cubit.dart';
import 'package:wadhakir/features/settings/cubit/settings_state.dart';
import 'package:wadhakir/features/settings/view/widgets/settings_section.dart';
import 'package:wadhakir/features/settings/view/widgets/appearance_settings_widget.dart';
import 'package:wadhakir/features/settings/view/widgets/about_section_widgets.dart';
import 'package:wadhakir/features/settings/view/screens/notification_settings_page.dart';
import 'package:wadhakir/features/settings/view/screens/fasting_settings_page.dart';
import 'package:wadhakir/features/settings/view/screens/app_lock_settings_page.dart';
import 'package:wadhakir/features/azkar_reminders/views/screens/azkar_reminders_settings_page.dart';
import 'package:wadhakir/features/backup/views/screens/backup_screen.dart';
import 'package:wadhakir/features/feature_discovery/views/widgets/feature_nudge_toggle_tile.dart';
import 'package:wadhakir/core/constants/app_constants.dart';
import 'package:wadhakir/core/widgets/app_dialog.dart';

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
    final size = MediaQuery.of(context).size;

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
                  title: l10n?.translate('settings.profile') ?? 'الملف الشخصي',
                  icon: Icons.person_outline,
                  subtitle:
                      l10n?.translate('settings.profile_subtitle') ??
                      'اسمك في التطبيق',
                  children: [
                    FItem(
                      prefix: const Icon(Icons.badge_outlined),
                      title: Text(
                        l10n?.translate('settings.your_name') ?? 'اسمك',
                      ),
                      subtitle: Text(
                        settings.userName.trim().isEmpty
                            ? (l10n?.translate('settings.no_name') ??
                                  'لم تُدخل اسماً بعد')
                            : settings.userName,
                      ),
                      suffix: const Icon(Icons.edit_outlined),
                      onPress: () => _showEditNameDialog(
                        context,
                        cubit,
                        settings.userName,
                      ),
                    ),
                  ],
                ),
              ),
              _buildAnimatedSection(
                delay: 50,
                child: SettingsSection(
                  title:
                      l10n?.translate('settings.appearance') ?? 'المظهر واللغة',
                  icon: Icons.palette_outlined,
                  subtitle:
                      l10n?.translate('settings.appearance_subtitle') ??
                      'تخصيص السمة واللغة',
                  children: [
                    AppearanceSettingsWidget(settings: settings, cubit: cubit),
                  ],
                ),
              ),
              _buildAnimatedSection(
                delay: 100,
                child: SettingsSection(
                  title:
                      l10n?.translate('settings.notifications') ?? 'التنبيهات',
                  icon: Icons.notifications_outlined,
                  subtitle:
                      l10n?.translate('settings.notifications_subtitle') ??
                      'تنبيهات أوقات الصلاة',
                  children: [
                    _buildNavTile(
                      context,
                      icon: Icons.notifications_active_outlined,
                      title:
                          l10n?.translate('settings.notifications') ??
                          'التنبيهات',
                      subtitle: settings.notificationSettings.masterEnabled
                          ? (l10n?.translate('settings.notifications_on') ??
                                'مفعّلة')
                          : (l10n?.translate('settings.notifications_off') ??
                                'متوقفة'),
                      page: const NotificationSettingsPage(),
                    ),
                  ],
                ),
              ),
              // App Lock relies on Android usage-stats + system overlay. Gate on
              // Android specifically rather than "not iOS" — this app also ships
              // desktop (see NotificationRepositoryImplWindows), and those
              // targets have no such APIs either.
              if (PlatformUtils.isAndroid)
                _buildAnimatedSection(
                  delay: 150,
                  child: SettingsSection(
                    title:
                        l10n?.translate('settings.app_lock') ??
                        'قفل التطبيقات وقت الصلاة',
                    icon: Icons.lock_outline,
                    subtitle:
                        l10n?.translate('settings.app_lock_subtitle') ??
                        'قفل التطبيقات المختارة حتى إنهاء الصلاة',
                    children: [
                      _buildNavTile(
                        context,
                        icon: Icons.lock_outline,
                        title:
                            l10n?.translate('settings.app_lock') ??
                            'قفل التطبيقات وقت الصلاة',
                        subtitle: settings.appLockSettings.enabled
                            ? (l10n?.translate('settings.notifications_on') ??
                                  'مفعّلة')
                            : (l10n?.translate('settings.notifications_off') ??
                                  'متوقفة'),
                        page: const AppLockSettingsPage(),
                      ),
                    ],
                  ),
                ),
              _buildAnimatedSection(
                delay: 175,
                child: SettingsSection(
                  title:
                      l10n?.translate('fasting.fasting_reminders') ??
                      'تذكيرات الصيام',
                  icon: Icons.restaurant_menu_outlined,
                  subtitle:
                      l10n?.translate('fasting.fasting_reminders_subtitle') ??
                      'الصيام الأسبوعي والشهري والأيام المميزة',
                  children: [
                    _buildNavTile(
                      context,
                      icon: Icons.restaurant_menu_outlined,
                      title:
                          l10n?.translate('fasting.fasting_reminders') ??
                          'تذكيرات الصيام',
                      subtitle:
                          l10n?.translate(
                            'fasting.fasting_reminders_subtitle',
                          ) ??
                          'الصيام الأسبوعي والشهري والأيام المميزة',
                      page: const FastingSettingsPage(),
                    ),
                  ],
                ),
              ),
              _buildAnimatedSection(
                delay: 182,
                child: SettingsSection(
                  title:
                      l10n?.translate('azkar_reminders.title') ??
                      'تذكيرات الأذكار',
                  icon: Icons.notifications_active_outlined,
                  subtitle:
                      l10n?.translate('azkar_reminders.subtitle') ??
                      'الصباح والمساء، بعد الصلاة، قيام الليل وغيرها',
                  children: [
                    _buildNavTile(
                      context,
                      icon: Icons.notifications_active_outlined,
                      title:
                          l10n?.translate('azkar_reminders.title') ??
                          'تذكيرات الأذكار',
                      subtitle:
                          l10n?.translate('azkar_reminders.subtitle') ??
                          'الصباح والمساء، بعد الصلاة، قيام الليل وغيرها',
                      page: const AzkarRemindersSettingsPage(),
                    ),
                  ],
                ),
              ),
              // Floating Dhikr draws an overlay over other apps, which needs
              // Android's SYSTEM_ALERT_WINDOW. No iOS or desktop equivalent.
              if (PlatformUtils.isAndroid)
                _buildAnimatedSection(
                  delay: 188,
                  child: SettingsSection(
                    title:
                        l10n?.translate('floating_dhikr.settings_tile') ??
                        'تذكير الأذكار العائم',
                    icon: Icons.bubble_chart_outlined,
                    subtitle:
                        l10n?.translate(
                          'floating_dhikr.settings_tile_subtitle',
                        ) ??
                        'إظهار ذكر فوق التطبيقات الأخرى كل فترة',
                    children: [
                      // Material(transparency) guards against the "ListTile
                      // background color or ink splashes may be invisible"
                      // warning if any ancestor between the SettingsSection's
                      // Material and this ListTile ever picks up a non-
                      // transparent color.
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          leading: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                          title: Text(
                            l10n?.translate('floating_dhikr.title') ??
                                'تذكير الأذكار العائم',
                          ),
                          subtitle: Text(
                            l10n?.translate(
                                  'floating_dhikr.settings_tile_subtitle',
                                ) ??
                                'إظهار ذكر فوق التطبيقات الأخرى كل فترة',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppConstants.floatingDhikrSettingsRoute),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildAnimatedSection(
                delay: 194,
                child: SettingsSection(
                  title:
                      l10n?.translate('feature_discovery.title') ??
                      'اقتراحات الميزات',
                  icon: Icons.lightbulb_outline,
                  subtitle:
                      l10n?.translate('feature_discovery.subtitle') ??
                      'تذكير لطيف بميزات لم تجرّبها بعد',
                  children: const [FeatureNudgeToggleTile()],
                ),
              ),
              _buildAnimatedSection(
                delay: 197,
                child: SettingsSection(
                  title: l10n?.translate('backup.title') ?? 'النسخ الاحتياطي',
                  icon: Icons.backup_outlined,
                  subtitle:
                      l10n?.translate('backup.settings_tile_subtitle') ??
                      'ملف واحد تحفظه لنفسك، ويعيد كل شيء على جهاز جديد',
                  children: [
                    _buildNavTile(
                      context,
                      icon: Icons.save_outlined,
                      title:
                          l10n?.translate('backup.settings_tile') ??
                          'نسخة احتياطية من بياناتك',
                      subtitle:
                          l10n?.translate('backup.settings_tile_action') ??
                          'حفظ نسخة أو استعادة واحدة',
                      page: const BackupPage(),
                    ),
                  ],
                ),
              ),
              _buildAnimatedSection(
                delay: 200,
                child: SettingsSection(
                  title: l10n?.translate('settings.about_app') ?? 'حول التطبيق',
                  icon: Icons.info_outline,
                  subtitle:
                      l10n?.translate('settings.about_subtitle') ??
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
              SizedBox(height: size.height * 0.05),
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
        final notificationCount = settings != null
            ? _countActiveNotifications(settings)
            : 0;

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

        return Transform.scale(
          scale: headerScale,
          child: Opacity(
            opacity: headerOpacity,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon Container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme.colorScheme.primary
                              : Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings_suggest,
                          size: 24,
                          color: isDark
                              ? theme.colorScheme.onPrimary
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title and Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.translate('settings.title') ?? 'الإعدادات',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? theme.colorScheme.onSurface
                                    : Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n?.translate('settings.description') ??
                                  'خصص تجربتك مع التطبيق',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    (isDark
                                            ? theme.colorScheme.onSurface
                                            : Colors.white)
                                        .withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Stats Bar with Real Data
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? theme.colorScheme.surface : Colors.white)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (isDark
                                    ? theme.colorScheme.onSurface
                                    : Colors.white)
                                .withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.notifications_active,
                          notificationCount.toString(),
                          l10n?.translate('settings.notifications_count') ??
                              'إشعار',
                          theme,
                          isDark,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color:
                              (isDark
                                      ? theme.colorScheme.onSurface
                                      : Colors.white)
                                  .withValues(alpha: 0.2),
                        ),
                        _buildStatItem(
                          Icons.language,
                          languageDisplay,
                          l10n?.translate('settings.language') ?? 'اللغة',
                          theme,
                          isDark,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color:
                              (isDark
                                      ? theme.colorScheme.onSurface
                                      : Colors.white)
                                  .withValues(alpha: 0.2),
                        ),
                        _buildStatItem(
                          Icons.palette,
                          themeModeDisplay,
                          l10n?.translate('settings.theme') ?? 'السمة',
                          theme,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? theme.colorScheme.onSurface : Colors.white,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? theme.colorScheme.onSurface : Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: (isDark ? theme.colorScheme.onSurface : Colors.white)
                .withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }

  /// A tappable row inside a settings section that navigates to a dedicated
  /// settings page. Keeps the main settings screen clean by routing dense
  /// sections out instead of expanding them inline.
  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return FItem(
      prefix: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      suffix: const Icon(Icons.chevron_right_rounded),
      onPress: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
    );
  }

  /// Edit the user's name. Saving persists via [SettingsCubit.setUserName],
  /// which re-emits settings so the home greeting updates reactively.
  Future<void> _showEditNameDialog(
    BuildContext context,
    SettingsCubit cubit,
    String currentName,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: currentName);
    await showFDialog(
      context: context,
      builder: (dialogContext, style, animation) {
        return AppDialog(
          title: Text(l10n?.translate('settings.your_name') ?? 'اسمك'),
          body: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FTextField(
              control: FTextFieldControl.managed(controller: controller),
              hint: l10n?.translate('name_prompt.hint') ?? 'اسمك الأول',
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              maxLines: 1,
              autofocus: true,
            ),
          ),
          actions: [
            FButton(
              variant: FButtonVariant.outline,
              onPress: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n?.translate('common.cancel') ?? 'إلغاء'),
            ),
            FButton(
              onPress: () {
                cubit.setUserName(controller.text.trim());
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n?.translate('common.save') ?? 'حفظ'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }
}
