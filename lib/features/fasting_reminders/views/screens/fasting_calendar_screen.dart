import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/core/utils/date_utils.dart';
import 'package:wadhakir/data/models/fasting/islamic_fasting_day_model.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_cubit.dart';
import 'package:wadhakir/features/fasting_reminders/cubit/fasting_reminders_state.dart';

/// Compact calendar dialog showing fasting days with date picker
class FastingCalendarScreen extends StatefulWidget {
  const FastingCalendarScreen({super.key});

  @override
  State<FastingCalendarScreen> createState() => _FastingCalendarScreenState();
}

class _FastingCalendarScreenState extends State<FastingCalendarScreen> {
  HijriDateTime? _selectedDate;
  List<IslamicFastingDay> _selectedDateEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = HijriDateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(theme, languageCode, l10n),

            // Calendar with event indicators
            Expanded(
              child: BlocBuilder<FastingRemindersCubit, FastingRemindersState>(
                builder: (context, state) {
                  if (state is! FastingRemindersLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: [
                      // Hijri Date Picker - Shows full year of fasting days
                      _buildDatePicker(
                        theme,
                        isDark,
                        languageCode,
                        state.yearFastingDays,
                      ),

                      const Divider(height: 1),

                      // Events for selected date
                      Expanded(
                        child: _buildEventsForSelectedDate(
                          theme,
                          languageCode,
                          l10n,
                          state.yearFastingDays,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    String languageCode,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.translate('fasting.calendar_title') ??
                      (languageCode == 'ar'
                          ? 'تقويم الصيام'
                          : 'Fasting Calendar'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n?.translate('fasting.calendar_subtitle') ??
                      (languageCode == 'ar'
                          ? 'أيام الصيام المستحبة'
                          : 'Recommended Fasting Days'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(
    ThemeData theme,
    bool isDark,
    String languageCode,
    List<IslamicFastingDay> fastingDays,
  ) {
    // Generate special dates (fasting days) for the next 12 months
    // Show ALL fasting days regardless of settings
    final now = HijriDateTime.now();
    final specialDates = <HijriDateTime>[];

    // Generate dates for the next 12 months
    for (int i = 0; i < 12; i++) {
      int targetMonth = now.month + i;
      int targetYear = now.year;

      // Adjust year if month exceeds 12
      while (targetMonth > 12) {
        targetMonth -= 12;
        targetYear++;
      }

      // Add Ayyam al-Bid (13, 14, 15)
      specialDates.add(HijriDateTime(targetYear, targetMonth, 13));
      specialDates.add(HijriDateTime(targetYear, targetMonth, 14));
      specialDates.add(HijriDateTime(targetYear, targetMonth, 15));

      // Add 9th and 10th
      specialDates.add(HijriDateTime(targetYear, targetMonth, 9));
      specialDates.add(HijriDateTime(targetYear, targetMonth, 10));

      // Add special days (Tasu'a, Ashura in Muharram; Arafah in Dhul Hijjah)
      if (targetMonth == 1) {
        // Muharram - Tasu'a (9th) and Ashura (10th) - already added above
      }
      if (targetMonth == 12) {
        // Dhul Hijjah - Arafah (9th) - already added above
      }

      // Add all Mondays and Thursdays
      final daysInMonth = _getDaysInHijriMonth(targetYear, targetMonth);
      for (int day = 1; day <= daysInMonth; day++) {
        final date = HijriDateTime(targetYear, targetMonth, day);
        final weekday = date.toDateTime().weekday;
        if (weekday == DateTime.monday || weekday == DateTime.thursday) {
          specialDates.add(date);
        }
      }
    }

    // Calculate min and max dates (12 months from now)
    final minDate = now;
    final maxDate = HijriDateTime(
      now.month + 12 > 12 ? now.year + 1 : now.year,
      (now.month + 12) > 12 ? (now.month + 12) - 12 : now.month + 12,
      now.day,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: SfHijriDateRangePicker(
        view: HijriDatePickerView.month,
        selectionMode: DateRangePickerSelectionMode.single,
        initialSelectedDate: _selectedDate,
        minDate: minDate,
        maxDate: maxDate,
        onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
          setState(() {
            _selectedDate = args.value as HijriDateTime?;
            _updateSelectedDateEvents(fastingDays);
          });
        },
        monthViewSettings: HijriDatePickerMonthViewSettings(
          dayFormat: 'EEE',
          specialDates: specialDates,
        ),
        monthCellStyle: HijriDatePickerMonthCellStyle(
          textStyle: theme.textTheme.bodyMedium,
          todayTextStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          specialDatesTextStyle: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
          specialDatesDecoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: DateRangePickerHeaderStyle(
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        selectionColor: theme.colorScheme.primary,
        todayHighlightColor: theme.colorScheme.primary.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildEventsForSelectedDate(
    ThemeData theme,
    String languageCode,
    AppLocalizations? l10n,
    List<IslamicFastingDay> fastingDays,
  ) {
    // Build complete list of ALL fasting days (regardless of settings)
    final allFastingDays = <IslamicFastingDay>[];

    // Add all monthly recurring days
    allFastingDays.add(IslamicFastingDay.ayyamAlBid13());
    allFastingDays.add(IslamicFastingDay.ayyamAlBid14());
    allFastingDays.add(IslamicFastingDay.ayyamAlBid15());
    allFastingDays.add(IslamicFastingDay.ninthOfMonth());
    allFastingDays.add(IslamicFastingDay.tenthOfMonth());

    // Add weekly fasting days
    allFastingDays.add(IslamicFastingDay.mondayFasting());
    allFastingDays.add(IslamicFastingDay.thursdayFasting());

    // Add special days
    allFastingDays.add(IslamicFastingDay.tasua());
    allFastingDays.add(IslamicFastingDay.ashura());
    allFastingDays.add(IslamicFastingDay.arafah());

    // Update selected date events with complete list
    _updateSelectedDateEvents(allFastingDays);

    if (_selectedDateEvents.isEmpty) {
      // Get Gregorian date for the selected Hijri date
      final gregorianDate = _selectedDate?.toDateTime() ?? DateTime.now();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Date Header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${gregorianDate.day} ${AppDateUtils.getGregorianMonthName(gregorianDate.month, l10n)} • ${AppDateUtils.getShortFormattedHijriDate(_selectedDate!, l10n)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.event_available_rounded,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                l10n?.translate('fasting.no_events_today') ??
                    (languageCode == 'ar'
                        ? 'لا توجد أحداث في هذا اليوم'
                        : 'No events on this day'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Get Gregorian date for the selected Hijri date
    final gregorianDate = _selectedDate?.toDateTime() ?? DateTime.now();

    return Column(
      children: [
        // Date Header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${gregorianDate.day} ${AppDateUtils.getGregorianMonthName(gregorianDate.month, l10n)} • ${AppDateUtils.getShortFormattedHijriDate(_selectedDate!, l10n)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Events List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _selectedDateEvents.length,
            itemBuilder: (context, index) {
              final fastingDay = _selectedDateEvents[index];
              return _buildEventCard(theme, languageCode, l10n, fastingDay);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(
    ThemeData theme,
    String languageCode,
    AppLocalizations? l10n,
    IslamicFastingDay fastingDay,
  ) {
    final primaryColor = theme.colorScheme.primary;
    final typeIcon = _getFastingTypeIcon(fastingDay.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _showFastingDetailDialog(
          context,
          theme,
          languageCode,
          l10n,
          fastingDay,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageCode == 'ar'
                          ? fastingDay.nameAr
                          : fastingDay.nameEn,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n?.translate('fasting.fast_on_this_day') ??
                          (languageCode == 'ar'
                              ? 'صوم في هذا اليوم'
                              : 'Fast on this day'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.info_outline, size: 20, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  // Show compact popup dialog for fasting day details
  void _showFastingDetailDialog(
    BuildContext context,
    ThemeData theme,
    String languageCode,
    AppLocalizations? l10n,
    IslamicFastingDay fastingDay,
  ) {
    final primaryColor = theme.colorScheme.primary;
    final fastingName = languageCode == 'ar'
        ? fastingDay.nameAr
        : fastingDay.nameEn;
    final fastingDescription = languageCode == 'ar'
        ? fastingDay.descriptionAr
        : fastingDay.descriptionEn;

    // Get Gregorian date for the selected Hijri date
    final gregorianDate = _selectedDate?.toDateTime() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 580),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fastingName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${gregorianDate.day} ${AppDateUtils.getGregorianMonthName(gregorianDate.month, l10n)} • ${AppDateUtils.getShortFormattedHijriDate(_selectedDate!, l10n)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        fastingDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),

                      // Virtues section
                      if (fastingDay.getVirtues(languageCode).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    color: primaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n?.translate('fasting.virtues') ??
                                        (languageCode == 'ar'
                                            ? 'الفضائل'
                                            : 'Virtues'),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...fastingDay
                                  .getVirtues(languageCode)
                                  .take(3)
                                  .map(
                                    (virtue) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            color: primaryColor,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              virtue,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    height: 1.5,
                                                    fontFamily:
                                                        languageCode == 'ar'
                                                        ? 'ScheherazadeNew'
                                                        : null,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],

                      // Quick guide
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n?.translate('fasting.quick_guide') ??
                                      (languageCode == 'ar'
                                          ? 'دليل سريع'
                                          : 'Quick Guide'),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildQuickTip(
                              theme,
                              Icons.wb_twilight,
                              l10n?.translate('fasting.make_intention') ??
                                  (languageCode == 'ar'
                                      ? 'بيّت النية قبل الفجر'
                                      : 'Make intention before Fajr'),
                            ),
                            const SizedBox(height: 6),
                            _buildQuickTip(
                              theme,
                              Icons.restaurant,
                              l10n?.translate('fasting.break_at_sunset') ??
                                  (languageCode == 'ar'
                                      ? 'أفطر عند غروب الشمس'
                                      : 'Break fast at sunset'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTip(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }

  void _updateSelectedDateEvents(List<IslamicFastingDay> fastingDays) {
    if (_selectedDate == null) return;

    _selectedDateEvents = fastingDays.where((day) {
      // Handle weekly fasting (Monday/Thursday)
      if (day.type == FastingDayType.weeklyFasting) {
        final weekday = _selectedDate!.toDateTime().weekday;
        if (day.hijriDay == 1 && weekday == DateTime.monday) return true;
        if (day.hijriDay == 4 && weekday == DateTime.thursday) return true;
        return false;
      }

      // Check if day matches either specific month or monthly recurring
      final monthMatches =
          day.hijriMonth == null || day.hijriMonth == _selectedDate!.month;
      final dayMatches = day.hijriDay == _selectedDate!.day;
      return monthMatches && dayMatches;
    }).toList();
  }

  IconData _getFastingTypeIcon(FastingDayType type) {
    switch (type) {
      case FastingDayType.ayyamAlBid:
        return Icons.wb_twilight;
      case FastingDayType.ninthTenth:
        return Icons.calendar_today;
      case FastingDayType.special:
        return Icons.calendar_month;
      case FastingDayType.weeklyFasting:
        return Icons.event_repeat;
    }
  }

  /// Get the number of days in a Hijri month
  int _getDaysInHijriMonth(int year, int month) {
    // Hijri months alternate between 29 and 30 days
    final List<int> monthLengths = [
      30,
      29,
      30,
      29,
      30,
      29,
      30,
      29,
      30,
      29,
      30,
      29,
    ];

    // Adjust for leap years (adds day to month 12)
    if (month == 12 && _isHijriLeapYear(year)) {
      return 30;
    }

    return monthLengths[month - 1];
  }

  /// Check if a Hijri year is a leap year
  bool _isHijriLeapYear(int year) {
    // Hijri leap year pattern: 2, 5, 7, 10, 13, 15, 18, 21, 24, 26, 29 in a 30-year cycle
    final leapYears = [2, 5, 7, 10, 13, 15, 18, 21, 24, 26, 29];
    return leapYears.contains(year % 30);
  }
}
