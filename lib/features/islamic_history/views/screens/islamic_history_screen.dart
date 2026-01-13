import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wadhakir/core/platform/platform_utils.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';

class IslamicHistoryScreen extends StatefulWidget {
  const IslamicHistoryScreen({super.key});

  @override
  State<IslamicHistoryScreen> createState() => _IslamicHistoryScreenState();
}

class _IslamicHistoryScreenState extends State<IslamicHistoryScreen> {
  List<HistoryEvent> historyEvents = [];
  List<HistoryEvent> filteredEvents = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredEvents = historyEvents;
      } else {
        filteredEvents = historyEvents.where((event) {
          return event.title.toLowerCase().contains(query) ||
              event.text.toLowerCase().contains(query) ||
              event.hijriYear.toLowerCase().contains(query) ||
              event.lunarMonth.toLowerCase().contains(query) ||
              event.gregorianYear.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadHistoryData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/json_data/history.json',
      );
      final List<dynamic> data = json.decode(response);

      setState(() {
        historyEvents = data.map((json) {
          final dateList = json['date'] as List?;
          final dateLength = dateList?.length ?? 0;

          String hijriYear = '';
          String lunarMonth = '';
          String gregorianYear = '';

          if (dateLength >= 2) {
            hijriYear = dateList![0].toString();
            // Check if middle element is lunar month or gregorian year
            final secondElement = dateList[1].toString();
            if (secondElement.contains('الشهر القمري')) {
              lunarMonth = secondElement;
              if (dateLength >= 3) {
                gregorianYear = dateList[2].toString();
              }
            } else {
              gregorianYear = secondElement;
            }
          } else if (dateLength == 1) {
            hijriYear = dateList![0].toString();
          }

          return HistoryEvent(
            id: json['id'],
            title: json['title'],
            text: json['text'],
            hijriYear: hijriYear,
            lunarMonth: lunarMonth,
            gregorianYear: gregorianYear,
          );
        }).toList();
        filteredEvents = historyEvents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = context.l10n;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: size.height * 0.25,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n?.translate('home.islamic_history') ?? 'السيرة النبوية',
                style: const TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(100, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.85),
                          theme.colorScheme.primary.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Islamic geometric pattern overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: IslamicPatternPainter(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  // Center decorative element
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        // Decorative Islamic star
                        Container(
                          width: size.width * 0.2,
                          height: size.width * 0.2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: size.width * 0.12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Decorative line
                        Container(
                          width: size.width * 0.15,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.4),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.translate('common.loading') ?? 'جارٍ التحميل...',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            )
          else if (error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: size.width * 0.2,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.translate('common.error') ?? 'حدث خطأ',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        error!,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: PlatformUtils.isDesktop
                        ? 1400.0
                        : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      PlatformUtils.isDesktop ? 24.0 : 16.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, child) {
                          return TextField(
                            controller: _searchController,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'ابحث في السيرة النبوية...',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor.withValues(alpha: 0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                              suffixIcon: value.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: theme.hintColor,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!isLoading && error == null)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: PlatformUtils.isDesktop
                        ? 1400.0
                        : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      PlatformUtils.isDesktop ? 24.0 : 16.0,
                      8,
                      PlatformUtils.isDesktop ? 24.0 : 16.0,
                      0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${filteredEvents.length} ${filteredEvents.length == 1 ? 'حدث' : 'أحداث'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!isLoading && error == null)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: PlatformUtils.isDesktop
                        ? 1400.0
                        : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      PlatformUtils.isDesktop ? 24.0 : 16.0,
                    ),
                    child: _buildHistoryList(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    final isDesktop = PlatformUtils.isDesktop;
    final width = MediaQuery.of(context).size.width;

    // Determine grid columns for desktop
    int crossAxisCount = 1;
    if (isDesktop) {
      if (width >= 1400) {
        crossAxisCount = 2;
      } else if (width >= 900) {
        crossAxisCount = 2;
      }
    }

    if (isDesktop && crossAxisCount > 1) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          return _buildHistoryCard(event, index, context);
        },
      );
    } else {
      return Column(
        children: List.generate(filteredEvents.length, (index) {
          final event = filteredEvents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildHistoryCard(event, index, context),
          );
        }),
      );
    }
  }

  Widget _buildHistoryCard(
    HistoryEvent event,
    int index,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = PlatformUtils.isDesktop;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => _showEventDetails(event, context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              Container(
                width: isDesktop ? 48.0 : 40.0,
                height: isDesktop ? 48.0 : 40.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 18.0 : 16.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                        fontSize: isDesktop ? 18.0 : null,
                      ),
                    ),
                    if (event.hijriYear.isNotEmpty ||
                        event.lunarMonth.isNotEmpty ||
                        event.gregorianYear.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (event.hijriYear.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      event.hijriYear,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontSize: size.width * 0.028,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            if (event.lunarMonth.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      theme.colorScheme.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.nights_stay,
                                      size: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      event.lunarMonth
                                          .replaceAll('الشهر القمري : ', '')
                                          .replaceAll('الشهر القمري :', ''),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontSize: size.width * 0.028,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            if (event.gregorianYear.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  event.gregorianYear,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontSize: size.width * 0.028,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      event.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'اقرأ المزيد',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: size.width * 0.032,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(HistoryEvent event, BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.hintColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (event.hijriYear.isNotEmpty ||
                          event.lunarMonth.isNotEmpty ||
                          event.gregorianYear.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.06,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.25,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.event_note_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'التاريخ',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      fontFamily: 'Almarai',
                                    ),
                                  ),
                                ],
                              ),
                              if (event.hijriYear.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          event.hijriYear,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontFamily: 'Almarai',
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (event.lunarMonth.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.nights_stay_rounded,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          event.lunarMonth,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontFamily: 'Almarai',
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (event.gregorianYear.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.today_rounded,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          event.gregorianYear,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontFamily: 'Almarai',
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: SelectableText(
                          event.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 2.0,
                            fontSize: size.width * 0.04,
                            fontFamily: 'Almarai',
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
      ),
    );
  }
}

class HistoryEvent {
  final int id;
  final String title;
  final String text;
  final String hijriYear;
  final String lunarMonth;
  final String gregorianYear;

  HistoryEvent({
    required this.id,
    required this.title,
    required this.text,
    required this.hijriYear,
    required this.lunarMonth,
    required this.gregorianYear,
  });
}

// Custom painter for Islamic geometric pattern
class IslamicPatternPainter extends CustomPainter {
  final Color color;

  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final spacing = 40.0;
    final rows = (size.height / spacing).ceil() + 1;
    final cols = (size.width / spacing).ceil() + 1;

    // Draw Islamic geometric stars pattern
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = col * spacing;
        final y = row * spacing;

        // Draw 8-pointed star
        _drawStar(canvas, paint, Offset(x, y), 12, 8);

        // Draw connecting lines
        if (col < cols - 1) {
          canvas.drawLine(
            Offset(x + 12, y),
            Offset(x + spacing - 12, y),
            paint,
          );
        }
        if (row < rows - 1) {
          canvas.drawLine(
            Offset(x, y + 12),
            Offset(x, y + spacing - 12),
            paint,
          );
        }
      }
    }
  }

  void _drawStar(
    Canvas canvas,
    Paint paint,
    Offset center,
    double radius,
    int points,
  ) {
    final path = Path();
    final angle = (2 * 3.14159) / points;

    for (int i = 0; i < points; i++) {
      final x = center.dx + radius * cos(i * angle - 3.14159 / 2);
      final y = center.dy + radius * sin(i * angle - 3.14159 / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
