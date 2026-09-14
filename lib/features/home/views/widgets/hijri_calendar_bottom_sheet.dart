import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class HijriCalendarBottomSheet extends StatefulWidget {
  final HijriDateTime initialDate;

  const HijriCalendarBottomSheet({super.key, required this.initialDate});

  @override
  State<HijriCalendarBottomSheet> createState() =>
      _HijriCalendarBottomSheetState();
}

class _HijriCalendarBottomSheetState extends State<HijriCalendarBottomSheet>
    with SingleTickerProviderStateMixin {
  late HijriDatePickerController _hijriController;
  late DateRangePickerController _gregorianController;
  late TabController _tabController;
  HijriDateTime? _selectedHijriDate;
  DateTime? _selectedGregorianDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _hijriController = HijriDatePickerController();
    _gregorianController = DateRangePickerController();
    _hijriController.selectedDate = widget.initialDate;
    _selectedHijriDate = widget.initialDate;
    _selectedGregorianDate = widget.initialDate.toDateTime();
    _gregorianController.selectedDate = _selectedGregorianDate;
  }

  void _onHijriSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is HijriDateTime) {
        _selectedHijriDate = args.value;
        _selectedGregorianDate = _selectedHijriDate!.toDateTime();
      }
    });
  }

  void _onGregorianSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is DateTime) {
        _selectedGregorianDate = args.value;
        _selectedHijriDate = HijriDateTime.fromDateTime(
          _selectedGregorianDate!,
        );
      }
    });
  }

  @override
  void dispose() {
    _hijriController.dispose();
    _gregorianController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final isDark = theme.brightness == Brightness.dark;

    return Localizations.override(
      context: context,
      locale: locale,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(10),
                tabs: [
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mosque, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n?.translate('calendar.hijri_calendar') ??
                                'هجري',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n?.translate('calendar.gregorian_calendar') ??
                                'ميلادي',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Hijri Calendar Tab
                  _buildHijriCalendar(theme, isDark),
                  // Gregorian Calendar Tab
                  _buildGregorianCalendar(theme, isDark, l10n),
                ],
              ),
            ),

            // Selected Date Display
            if (_selectedHijriDate != null && _selectedGregorianDate != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hijri Date
                    Icon(
                      Icons.mosque,
                      size: 18,
                      color: isDark
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedHijriDate!.day} ${_getHijriMonthName(_selectedHijriDate!.month, l10n)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                            : theme.colorScheme.primary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    // Gregorian Date
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isDark
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatGregorianDate(_selectedGregorianDate!, l10n),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Bottom padding
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  String _getHijriMonthName(int month, AppLocalizations? l10n) {
    if (l10n == null) return '';
    final monthKey = 'hijri_months.month_$month';
    return l10n.translate(monthKey);
  }

  String _formatGregorianDate(DateTime date, AppLocalizations? l10n) {
    final months = [
      l10n?.translate('global.jan') ?? 'Jan',
      l10n?.translate('global.feb') ?? 'Feb',
      l10n?.translate('global.mar') ?? 'Mar',
      l10n?.translate('global.apr') ?? 'Apr',
      l10n?.translate('global.may') ?? 'May',
      l10n?.translate('global.jun') ?? 'Jun',
      l10n?.translate('global.jul') ?? 'Jul',
      l10n?.translate('global.aug') ?? 'Aug',
      l10n?.translate('global.sep') ?? 'Sep',
      l10n?.translate('global.oct') ?? 'Oct',
      l10n?.translate('global.nov') ?? 'Nov',
      l10n?.translate('global.dec') ?? 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _buildHijriCalendar(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SfHijriDateRangePicker(
          controller: _hijriController,
          initialSelectedDate: widget.initialDate,
          onSelectionChanged: _onHijriSelectionChanged,
          showTodayButton: true,
          showNavigationArrow: true,
          selectionMode: DateRangePickerSelectionMode.single,
          todayHighlightColor: theme.colorScheme.primary,
          selectionColor: theme.colorScheme.primary,
          monthViewSettings: HijriDatePickerMonthViewSettings(
            firstDayOfWeek: 6, // Saturday
            viewHeaderStyle: DateRangePickerViewHeaderStyle(
              textStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                    : theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            dayFormat: 'EEE',
            showWeekNumber: true,
          ),
          monthCellStyle: HijriDatePickerMonthCellStyle(
            textStyle: TextStyle(
              fontSize: 12,
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                  : theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
            todayTextStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          yearCellStyle: HijriDatePickerYearCellStyle(
            textStyle: TextStyle(
              fontSize: 13,
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                  : theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
            todayTextStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            todayCellDecoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary, width: 2),
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: DateRangePickerHeaderStyle(
            textAlign: TextAlign.center,
            textStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.9)
                  : theme.colorScheme.primary,
            ),
          ),
          headerHeight: 45,
          navigationDirection: DateRangePickerNavigationDirection.horizontal,
          navigationMode: DateRangePickerNavigationMode.snap,
        ),
      ),
    );
  }

  Widget _buildGregorianCalendar(
    ThemeData theme,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SfDateRangePicker(
          controller: _gregorianController,
          initialSelectedDate: _selectedGregorianDate,
          onSelectionChanged: _onGregorianSelectionChanged,
          showTodayButton: true,
          showNavigationArrow: true,
          selectionMode: DateRangePickerSelectionMode.single,
          todayHighlightColor: theme.colorScheme.primary,
          selectionColor: theme.colorScheme.primary,
          monthViewSettings: DateRangePickerMonthViewSettings(
            firstDayOfWeek: 6, // Saturday
            viewHeaderStyle: DateRangePickerViewHeaderStyle(
              textStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                    : theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            dayFormat: 'EEE',
            showWeekNumber: true,
          ),
          monthCellStyle: DateRangePickerMonthCellStyle(
            textStyle: TextStyle(
              fontSize: 12,
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                  : theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
            todayTextStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          yearCellStyle: DateRangePickerYearCellStyle(
            textStyle: TextStyle(
              fontSize: 13,
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                  : theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
            todayTextStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            todayCellDecoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary, width: 2),
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: DateRangePickerHeaderStyle(
            textAlign: TextAlign.center,
            textStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.9)
                  : theme.colorScheme.primary,
            ),
          ),
          headerHeight: 45,
          navigationDirection: DateRangePickerNavigationDirection.horizontal,
          navigationMode: DateRangePickerNavigationMode.snap,
        ),
      ),
    );
  }
}
