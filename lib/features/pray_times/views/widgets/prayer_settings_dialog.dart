import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/core/widgets/islamic_icons.dart';
import 'package:adhan/adhan.dart' show CalculationMethod, Madhab;
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_cubit.dart';
import 'package:wadhakir/features/pray_times/cubit/prayer_times_state.dart';

class PrayerSettingsDialog extends StatelessWidget {
  final PrayerTimesCubit cubit;

  const PrayerSettingsDialog({
    super.key,
    required this.cubit,
  });

  static Future<void> show(BuildContext context, PrayerTimesCubit cubit) async {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => BlocProvider.value(
          value: cubit,
          child: PrayerSettingsDialog(cubit: cubit),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.03,
          ),
          child: Container(
            width: size.width * 0.9,
            constraints: BoxConstraints(maxHeight: size.height * 0.8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with decorative element
                _buildHeader(context, size, primaryColor, l10n),

                // Main content
                Flexible(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: CustomScrollView(
                      slivers: [
                        // Prayer calculation methods
                        _buildCalculationMethodsSection(
                            context, size, primaryColor),

                        // Asr calculation (Madhab)
                        _buildAsrCalculationSection(
                            context, size, primaryColor),

                        // Location update section
                        _buildLocationUpdateSection(
                            context, size, primaryColor),

                        SliverToBoxAdapter(
                          child: SizedBox(height: size.height * 0.02),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                _buildActionButtons(context, size, theme, l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Size size, Color primaryColor,
      AppLocalizations? l10n) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: size.height * 0.02,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Title with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(size.width * 0.02),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: size.width * 0.06,
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Text(
                l10n?.translate('prayer_times.prayer_time_settings') ??
                    'إعدادات أوقات الصلاة',
                style: TextStyle(
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Almarai',
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // Decorative divider
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: size.height * 0.015,
              horizontal: size.width * 0.2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.5),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                  child: IslamicIcons.ornamentIcon(
                    size: size.width * 0.04,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.5),
                    thickness: 1,
                  ),
                ),
              ],
            ),
          ),

          // Subtitle
          Text(
            l10n?.translate('prayer_times.customize_prayer_times') ??
                'تخصيص إعدادات مواقيت الصلاة',
            style: TextStyle(
              fontSize: size.width * 0.035,
              color: Colors.white.withValues(alpha: 0.9),
              fontFamily: 'Almarai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationMethodsSection(
      BuildContext context, Size size, Color primaryColor) {
    return SliverToBoxAdapter(
      child: FutureBuilder<CalculationMethod>(
        future: cubit.getCalculationMethod(),
        builder: (context, snapshot) {
          final currentMethod = snapshot.data;
          final l10n = AppLocalizations.of(context);

          return _SettingsSection(
            title:
                l10n?.translate('prayer_times.calculation_method_settings') ??
                    'طريقة حساب مواقيت الصلاة',
            subtitle:
                l10n?.translate('prayer_times.choose_calculation_method') ??
                    'اختر الطريقة المناسبة لحساب المواقيت حسب منطقتك',
            icon: Icons.calculate_outlined,
            iconColor: const Color(0xFF3498DB),
            margin: EdgeInsets.fromLTRB(
              size.width * 0.04,
              size.height * 0.02,
              size.width * 0.04,
              size.height * 0.01,
            ),
            child: Column(
              children: [
                _CalculationMethodTile(
                  title: l10n?.translate('prayer_times.muslim_world_league') ??
                      'رابطة العالم الإسلامي',
                  subtitle: l10n?.translate(
                          'prayer_times.muslim_world_league_description') ??
                      'المعيار المستخدم في أغلب الدول الإسلامية',
                  isSelected:
                      currentMethod == CalculationMethod.muslim_world_league,
                  onTap: () => _setCalculationMethod(
                      context, CalculationMethod.muslim_world_league),
                ),
                _CalculationMethodTile(
                  title: l10n?.translate('prayer_times.egyptian') ??
                      'الهيئة المصرية العامة للمساحة',
                  subtitle:
                      l10n?.translate('prayer_times.egyptian_description') ??
                          'المعيار المستخدم في مصر وأجزاء من أفريقيا',
                  isSelected: currentMethod == CalculationMethod.egyptian,
                  onTap: () => _setCalculationMethod(
                      context, CalculationMethod.egyptian),
                ),
                _CalculationMethodTile(
                  title: l10n?.translate('prayer_times.karachi') ??
                      'جامعة العلوم الإسلامية، كراتشي',
                  subtitle:
                      l10n?.translate('prayer_times.karachi_description') ??
                          'المعيار المستخدم في باكستان وأجزاء من آسيا',
                  isSelected: currentMethod == CalculationMethod.karachi,
                  onTap: () =>
                      _setCalculationMethod(context, CalculationMethod.karachi),
                ),
                _CalculationMethodTile(
                  title: l10n?.translate('prayer_times.umm_al_qura') ??
                      'جامعة أم القرى، مكة المكرمة',
                  subtitle:
                      l10n?.translate('prayer_times.umm_al_qura_description') ??
                          'المعيار المستخدم في المملكة العربية السعودية',
                  isSelected: currentMethod == CalculationMethod.umm_al_qura,
                  onTap: () => _setCalculationMethod(
                      context, CalculationMethod.umm_al_qura),
                ),
                _CalculationMethodTile(
                  title: l10n?.translate('prayer_times.north_america') ??
                      'الجمعية الإسلامية لأمريكا الشمالية',
                  subtitle: l10n?.translate(
                          'prayer_times.north_america_description') ??
                      'المعيار المستخدم في الولايات المتحدة وكندا',
                  isSelected: currentMethod == CalculationMethod.north_america,
                  onTap: () => _setCalculationMethod(
                      context, CalculationMethod.north_america),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAsrCalculationSection(
      BuildContext context, Size size, Color primaryColor) {
    return SliverToBoxAdapter(
      child: FutureBuilder<Madhab>(
        future: cubit.getMadhab(),
        builder: (context, snapshot) {
          final currentMadhab = snapshot.data;
          final l10n = AppLocalizations.of(context);

          return _SettingsSection(
            title: l10n?.translate('prayer_times.asr_calculation_method') ??
                'طريقة حساب وقت صلاة العصر',
            subtitle: l10n?.translate(
                    'prayer_times.asr_calculation_method_description') ??
                'اختر الطريقة المناسبة لحساب وقت العصر حسب المذهب',
            icon: Icons.sunny,
            iconColor: const Color(0xFF27AE60),
            margin: EdgeInsets.fromLTRB(
              size.width * 0.04,
              size.height * 0.01,
              size.width * 0.04,
              size.height * 0.01,
            ),
            child: Column(
              children: [
                _CalculationMethodTile(
                  title: l10n?.translate(
                          'prayer_times.asr_calculation_method_shafi') ??
                      'الشافعي، المالكي، الحنبلي',
                  subtitle: l10n?.translate(
                          'prayer_times.asr_calculation_method_shafi_description') ??
                      'عندما يكون ظل الشيء مثل طوله',
                  isSelected: currentMadhab == Madhab.shafi,
                  onTap: () => _setMadhab(context, Madhab.shafi),
                ),
                _CalculationMethodTile(
                  title: l10n?.translate(
                          'prayer_times.asr_calculation_method_hanafi') ??
                      'الحنفي',
                  subtitle: l10n?.translate(
                          'prayer_times.asr_calculation_method_hanafi_description') ??
                      'عندما يكون ظل الشيء ضعف طوله',
                  isSelected: currentMadhab == Madhab.hanafi,
                  onTap: () => _setMadhab(context, Madhab.hanafi),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationUpdateSection(
      BuildContext context, Size size, Color primaryColor) {
    final l10n = AppLocalizations.of(context);
    return SliverToBoxAdapter(
      child: _SettingsSection(
        title:
            l10n?.translate('prayer_times.location_update') ?? 'تحديث الموقع',
        subtitle: l10n?.translate('prayer_times.location_update_description') ??
            'تحديث الموقع الحالي لحساب مواقيت الصلاة بدقة',
        icon: Icons.location_on,
        iconColor: const Color(0xFFE67E22),
        margin: EdgeInsets.fromLTRB(
          size.width * 0.04,
          size.height * 0.01,
          size.width * 0.04,
          size.height * 0.01,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current location text
            FutureBuilder<String>(
                future: cubit.getCurrentLocationName(),
                builder: (context, snapshot) {
                  final locationName = snapshot.data ??
                      l10n?.translate('prayer_times.loading_location') ??
                      'جاري تحميل الموقع...';
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE67E22).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.place,
                          color: const Color(0xFFE67E22),
                          size: size.width * 0.05,
                        ),
                        SizedBox(width: size.width * 0.02),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.translate(
                                        'prayer_times.current_location') ??
                                    'الموقع الحالي',
                                style: TextStyle(
                                  fontSize: size.width * 0.03,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                locationName,
                                style: TextStyle(
                                  fontSize: size.width * 0.035,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

            // Update location button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateLocation(context),
                icon: const Icon(Icons.refresh),
                label: Text(l10n?.translate('prayer_times.update_location') ??
                    'تحديث الموقع'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: size.height * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Button for time adjustment
  Widget _buildActionButtons(BuildContext context, Size size, ThemeData theme,
      AppLocalizations? l10n) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
            label: Text(l10n?.translate('prayer_times.close') ?? 'إغلاق'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

          // Save button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check),
            label: Text(l10n?.translate('prayer_times.done') ?? 'تم'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.06,
                vertical: size.height * 0.015,
              ),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  void _setCalculationMethod(BuildContext context, CalculationMethod method) {
    BlocProvider.of<PrayerTimesCubit>(context).setCalculationMethod(method);
  }

  void _setMadhab(BuildContext context, Madhab madhab) {
    BlocProvider.of<PrayerTimesCubit>(context).setMadhab(madhab);
  }

  void _updateLocation(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    // Show loading indicator
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text(l10n?.translate('prayer_times.loading_location') ??
                'جاري تحديث الموقع...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    // Update location
    try {
      await BlocProvider.of<PrayerTimesCubit>(context).updateLocation();

      // Show success message
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n?.translate('prayer_times.location_updated') ??
                'تم تحديث الموقع بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
                l10n?.translate('prayer_times.location_update_failed') ??
                    'فشل تحديث الموقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// A section in the settings dialog
class _SettingsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final EdgeInsets margin;

  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: EdgeInsets.all(size.width * 0.04),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(size.width * 0.02),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: size.width * 0.045,
                  ),
                ),
                SizedBox(width: size.width * 0.03),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Section subtitle
          if (subtitle.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                size.width * 0.04,
                size.height * 0.01,
                size.width * 0.04,
                0,
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.right,
              ),
            ),

          // Section content
          Padding(
            padding: EdgeInsets.all(size.width * 0.03),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CalculationMethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _CalculationMethodTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: theme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
