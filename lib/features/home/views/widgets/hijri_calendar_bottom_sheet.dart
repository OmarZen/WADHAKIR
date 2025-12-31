import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class HijriCalendarBottomSheet extends StatefulWidget {
  final HijriDateTime initialDate;

  const HijriCalendarBottomSheet({
    super.key,
    required this.initialDate,
  });

  @override
  State<HijriCalendarBottomSheet> createState() =>
      _HijriCalendarBottomSheetState();
}

class _HijriCalendarBottomSheetState extends State<HijriCalendarBottomSheet> {
  late HijriDatePickerController _controller;
  HijriDateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _controller = HijriDatePickerController();
    _controller.selectedDate = widget.initialDate;
    _selectedDate = widget.initialDate;
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is HijriDateTime) {
        _selectedDate = args.value;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);

    return Localizations.override(
      context: context,
      locale: locale,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n?.translate('calendar.hijri_calendar') ??
                        'التقويم الهجري',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Syncfusion Hijri Date Picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SfHijriDateRangePicker(
                controller: _controller,
                initialSelectedDate: widget.initialDate,
                onSelectionChanged: _onSelectionChanged,
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
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  dayFormat: 'EEE',
                  showWeekNumber: true,
                ),
                monthCellStyle: HijriDatePickerMonthCellStyle(
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  todayTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                yearCellStyle: HijriDatePickerYearCellStyle(
                  textStyle: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  todayTextStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  todayCellDecoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: DateRangePickerHeaderStyle(
                  textAlign: TextAlign.center,
                  textStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                headerHeight: 45,
                navigationDirection:
                    DateRangePickerNavigationDirection.horizontal,
                navigationMode: DateRangePickerNavigationMode.snap,
              ),
            ),

            // Selected Date Display
            if (_selectedDate != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate!.day} ${_getHijriMonthName(_selectedDate!.month, l10n)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.5),
                      ),
                    ),
                    // Gregorian Date
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatGregorianDate(_selectedDate!.toDateTime(), l10n),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color,
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
}
