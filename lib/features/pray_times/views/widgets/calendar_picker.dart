import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class CalendarPicker extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final bool isVisible;
  final VoidCallback onClose;

  const CalendarPicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.isVisible,
    required this.onClose,
  });

  @override
  State<CalendarPicker> createState() => _CalendarPickerState();
}

class _CalendarPickerState extends State<CalendarPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  bool _isHijriMode = false;
  late HijriCalendar _selectedHijriDate;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _selectedHijriDate = HijriCalendar.fromDate(widget.selectedDate);

    if (widget.isVisible) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CalendarPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }

    if (widget.selectedDate != oldWidget.selectedDate) {
      _selectedHijriDate = HijriCalendar.fromDate(widget.selectedDate);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            heightFactor: _heightAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04,
                  vertical: size.height * 0.01,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button and calendar type toggle
                    Padding(
                      padding: EdgeInsets.all(size.width * 0.04),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Calendar type toggle
                          Row(
                            children: [
                              Text(
                                l10n?.translate('prayer_times.gregorian') ??
                                    'ميلادي',
                                style: TextStyle(
                                  fontSize: size.width * 0.035,
                                  color: !_isHijriMode
                                      ? theme.primaryColor
                                      : Colors.grey,
                                  fontWeight: !_isHijriMode
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Switch(
                                value: _isHijriMode,
                                onChanged: (value) {
                                  setState(() {
                                    _isHijriMode = value;
                                  });
                                },
                                activeThumbColor: theme.primaryColor,
                              ),
                              Text(
                                l10n?.translate('prayer_times.hijri') ?? 'هجري',
                                style: TextStyle(
                                  fontSize: size.width * 0.035,
                                  color: _isHijriMode
                                      ? theme.primaryColor
                                      : Colors.grey,
                                  fontWeight: _isHijriMode
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),

                          // Close button
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: widget.onClose,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),

                    // Calendar
                    if (_isHijriMode)
                      _buildHijriCalendar(size, theme)
                    else
                      _buildGregorianCalendar(size, theme),

                    // Today button
                    Padding(
                      padding: EdgeInsets.all(size.width * 0.04),
                      child: ElevatedButton(
                        onPressed: () {
                          final today = DateTime.now();
                          widget.onDateSelected(today);
                          widget.onClose();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.06,
                            vertical: size.height * 0.015,
                          ),
                        ),
                        child: Text(
                          l10n?.translate('prayer_times.today') ?? 'اليوم',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildGregorianCalendar(Size size, ThemeData theme) {
    // One year before and after current date
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now().add(const Duration(days: 365));

    return SizedBox(
      height: size.height * 0.35,
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: theme.primaryColor,
            onPrimary: Colors.white,
            surface: theme.primaryColor.withValues(alpha: 0.1),
            onSurface: theme.primaryColor,
          ),
        ),
        child: CalendarDatePicker(
          initialDate: widget.selectedDate,
          firstDate: firstDate,
          lastDate: lastDate,
          onDateChanged: (date) {
            widget.onDateSelected(date);
            widget.onClose();
          },
          currentDate: DateTime.now(),
        ),
      ),
    );
  }

  Widget _buildHijriCalendar(Size size, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: size.height * 0.35,
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          children: [
            // Year and month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      if (_selectedHijriDate.hMonth == 1) {
                        _selectedHijriDate = HijriCalendar()
                          ..hYear = _selectedHijriDate.hYear - 1
                          ..hMonth = 12
                          ..hDay = 1;
                      } else {
                        _selectedHijriDate = HijriCalendar()
                          ..hYear = _selectedHijriDate.hYear
                          ..hMonth = _selectedHijriDate.hMonth - 1
                          ..hDay = 1;
                      }
                    });
                  },
                  color: theme.primaryColor,
                ),
                Text(
                  '${_selectedHijriDate.longMonthName} ${_selectedHijriDate.hYear}',
                  style: TextStyle(
                    fontSize: size.width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    setState(() {
                      if (_selectedHijriDate.hMonth == 12) {
                        _selectedHijriDate = HijriCalendar()
                          ..hYear = _selectedHijriDate.hYear + 1
                          ..hMonth = 1
                          ..hDay = 1;
                      } else {
                        _selectedHijriDate = HijriCalendar()
                          ..hYear = _selectedHijriDate.hYear
                          ..hMonth = _selectedHijriDate.hMonth + 1
                          ..hDay = 1;
                      }
                    });
                  },
                  color: theme.primaryColor,
                ),
              ],
            ),

            SizedBox(height: size.height * 0.02),

            // Days of week header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(l10n?.translate('global.sunday') ?? 'الأحد'),
                Text(l10n?.translate('global.monday') ?? 'الإثنين'),
                Text(l10n?.translate('global.tuesday') ?? 'الثلاثاء'),
                Text(l10n?.translate('global.wednesday') ?? 'الأربعاء'),
                Text(l10n?.translate('global.thursday') ?? 'الخميس'),
                Text(l10n?.translate('global.friday') ?? 'الجمعة'),
                Text(l10n?.translate('global.saturday') ?? 'السبت'),
              ],
            ),

            SizedBox(height: size.height * 0.01),

            // Calendar grid
            Expanded(
              child: _buildHijriCalendarGrid(size, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHijriCalendarGrid(Size size, ThemeData theme) {
    // Get the first day of the month
    final firstDayOfMonth = HijriCalendar()
      ..hYear = _selectedHijriDate.hYear
      ..hMonth = _selectedHijriDate.hMonth
      ..hDay = 1;

    // Convert to Gregorian to get the day of week
    DateTime firstDayGregorian =
        DateTime.now(); // Initialize with fallback value
    try {
      firstDayGregorian = firstDayOfMonth.hijriToGregorian(
        firstDayOfMonth.hYear,
        firstDayOfMonth.hMonth,
        firstDayOfMonth.hDay,
      );
    } catch (e) {
      // Fallback if conversion fails
    }

    final int startWeekday = firstDayGregorian.weekday % 7; // 0 = Sunday

    // Current Hijri date
    final now = HijriCalendar.now();

    // Get days in month - using instance method
    int daysInMonth = 30; // Default to 30 days
    try {
      // Call the instance method on the firstDayOfMonth
      daysInMonth = firstDayOfMonth.lengthOfMonth;
    } catch (e) {
      // Fallback if method call fails
    }

    // Calculate rows needed
    final numRows = ((startWeekday + daysInMonth) / 7).ceil();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: numRows * 7,
      itemBuilder: (context, index) {
        final int weekday = index % 7;
        final int day = index - startWeekday + 1;

        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final currentDay = HijriCalendar()
          ..hYear = _selectedHijriDate.hYear
          ..hMonth = _selectedHijriDate.hMonth
          ..hDay = day;

        final isSelectedDay = currentDay.hYear == _selectedHijriDate.hYear &&
            currentDay.hMonth == _selectedHijriDate.hMonth &&
            currentDay.hDay == _selectedHijriDate.hDay;

        final isToday = currentDay.hYear == now.hYear &&
            currentDay.hMonth == now.hMonth &&
            currentDay.hDay == now.hDay;

        return GestureDetector(
          onTap: () {
            // Convert to Gregorian date for selection
            DateTime gregorianDate = DateTime.now(); // Default value
            try {
              gregorianDate = currentDay.hijriToGregorian(
                currentDay.hYear,
                currentDay.hMonth,
                currentDay.hDay,
              );
            } catch (e) {
              // Fallback if conversion fails
            }

            widget.onDateSelected(gregorianDate);
            widget.onClose();
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelectedDay
                  ? theme.primaryColor
                  : isToday
                      ? theme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(size.width * 0.02),
              border: isToday && !isSelectedDay
                  ? Border.all(color: theme.primaryColor)
                  : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelectedDay
                      ? Colors.white
                      : isToday
                          ? theme.primaryColor
                          : weekday == 5 // Friday
                              ? Colors.green
                              : Colors.black87,
                  fontWeight: isSelectedDay || isToday || weekday == 5
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
