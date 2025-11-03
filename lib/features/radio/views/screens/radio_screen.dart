import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wadhakir/features/radio/cubit/radio_cubit.dart';
import 'package:wadhakir/features/radio/cubit/radio_state.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import 'package:wadhakir/features/radio/views/widgets/radio_station_list_item.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  String _query = '';
  String _category = 'all';
  final TextEditingController _searchController = TextEditingController();
  static const List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'كل الإذاعات'},
    {'key': 'readers', 'label': 'القراء'},
    {'key': 'ruqiah', 'label': 'الرقية الشرعية'},
    {'key': 'fatwa', 'label': 'الفتاوى'},
    {'key': 'adhkar', 'label': 'الأدعية والأذكار'},
    {'key': 'qiraat', 'label': 'القراءات العشر'},
    {'key': 'tafsir', 'label': 'التفسير وعلوم القرآن'},
    {'key': 'translations', 'label': 'ترجمات ومعاني القرآن'},
    {'key': 'seerah', 'label': 'السيرة والقصص'},
    {'key': 'seasons', 'label': 'مواسم الخير'},
    {'key': 'featured', 'label': 'تلاوات مميزة'},
  ];

  static const Map<String, IconData> _categoryIcons = {
    'all': Icons.apps_rounded,
    'readers': Icons.people_alt_rounded,
    'ruqiah': Icons.health_and_safety_rounded,
    'fatwa': Icons.record_voice_over_rounded,
    'adhkar': Icons.self_improvement_rounded,
    'qiraat': Icons.library_music_rounded,
    'tafsir': Icons.menu_book_rounded,
    'translations': Icons.translate_rounded,
    'seerah': Icons.history_edu_rounded,
    'seasons': Icons.event_rounded,
    'featured': Icons.star_rounded,
  };

  @override
  void initState() {
    super.initState();
    context.read<RadioCubit>().loadStations();
    _searchController.addListener(() {
      final v = _searchController.text.trim();
      if (v != _query) setState(() => _query = v);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    return BlocListener<RadioCubit, RadioState>(
      listener: (context, state) {
        // Show snackbar for playback errors (so user doesn't lose the list)
        if (state is RadioError && state.errorType == 'playback') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: Colors.blue.shade700,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'حسناً',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
          // Return to loaded state after showing error
          context.read<RadioCubit>().loadStations();
        }
      },
      child: Scaffold(
        appBar: _CustomRadioAppBar(
          title: l10n?.translate('radio.title') ?? 'Radio',
          onRefresh: () => context.read<RadioCubit>().loadStations(),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                size.width * 0.04,
                size.width * 0.04,
                size.width * 0.04,
                8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onChanged: (v) => setState(() => _query = v.trim()),
                        decoration: InputDecoration(
                          hintText: l10n?.translate('radio.search') ?? 'Search',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 0,
                          ),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        style: IconButton.styleFrom(padding: EdgeInsets.zero),
                        tooltip: l10n?.translate('radio.clear') ?? 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        color: theme.colorScheme.primary,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    else
                      Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                      ),
                    SizedBox(width: size.width * 0.03),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04,
                vertical: 6,
              ),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: _categories.map((c) {
                      final selected = _category == c['key'];
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: ChoiceChip(
                          showCheckmark: false,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(
                            horizontal: -2,
                            vertical: -2,
                          ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _categoryIcons[c['key']] ?? Icons.label_rounded,
                                size: 18,
                                color: selected
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(c['label']!),
                            ],
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _category = c['key']!),
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          backgroundColor: theme.colorScheme.surface,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Expanded(
              child: BlocBuilder<RadioCubit, RadioState>(
                builder: (context, state) {
                  if (state is RadioLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is RadioError) {
                    return _ErrorView(
                      message: state.message,
                      errorType: state.errorType,
                      onRetry: () => context.read<RadioCubit>().loadStations(),
                    );
                  }
                  if (state is RadioLoaded) {
                    final filtered = _applyCategory(state)
                        .where(
                          (s) => s.name
                              .toLowerCase()
                              .contains(_query.toLowerCase()),
                        )
                        .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          l10n?.translate('radio.no_results') ?? 'No results',
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                        vertical: size.height * 0.01,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: size.height * 0.012),
                      itemBuilder: (_, i) {
                        final station = filtered[i];
                        final isCurrentStation =
                            state.current?.id == station.id;
                        final isActive = isCurrentStation && state.isPlaying;
                        final isLoading = isCurrentStation && state.isLoading;

                        return RadioStationListItem(
                          station: station,
                          isActive: isActive,
                          isLoading: isLoading,
                          onTap: () {
                            if (isCurrentStation && state.isPlaying) {
                              // If this station is currently playing, pause it
                              context.read<RadioCubit>().togglePlayPause();
                            } else {
                              // Otherwise, play this station
                              context.read<RadioCubit>().playStation(station);
                            }
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            // Player bar is now global at the app scaffold level
            SizedBox(height: size.height * 0.01),
          ],
        ),
      ),
    );
  }

  List<dynamic> _applyCategory(RadioState state) {
    if (state is! RadioLoaded) return const [];
    final list = state.stations;
    switch (_category) {
      case 'readers':
        final names = {
          'أحمد الحواشي',
          'أحمد الطرابلسي',
          'أحمد بن علي العجمي',
          'أحمد خليل شاهين',
          'أحمد ديبان',
          'أحمد صابر',
          'أحمد عامر',
          'أحمد نعينع',
          'أكرم العلاقمي',
          'إبراهيم الأخضر',
          'إدريس أبكر',
          'الزين محمد أحمد',
          'بندر بليله',
          'توفيق الصايغ',
          'جمال شاكر عبدالله',
          'جمعان العصيمي',
          'حاتم فريد الواعر',
          'خالد الجليل',
          'خالد القحطاني',
          'خالد المهنا',
          'خالد عبدالكافي',
          'خليفة الطنيجي',
          'زكي داغستاني',
          'سعد الغامدي',
          'سعود الشريم',
          'سهل ياسين',
          'سيد رمضان',
          'شيخ أبو بكر الشاطري',
          'شيرزاد عبدالرحمن طاهر',
          'صابر عبدالحكم',
          'صلاح البدير',
          'صلاح الهاشم',
          'صلاح بو خاطر',
          'عادل الكلباني',
          'عادل ريان',
          'عبدالبارئ الثبيتي',
          'عبدالبارئ محمد',
          'عبدالباسط عبدالصمد',
          'عبدالرحمن السديس',
          'عبدالرحمن الشحات',
          'عبدالرحمن الماجد',
          'عبدالعزيز الأحمد',
          'عبدالله الخلف',
          'عبدالله الكندري',
          'عبدالله المطرود',
          'عبدالله الموسى',
          'عبدالله بصفر',
          'عبدالله خياط',
          'عبدالله عواد الجهني',
          'عبدالمحسن الحارثي',
          'عبدالمحسن العبيكان',
          'عبدالمحسن القاسم',
          'عبدالهادي أحمد كناكري',
          'عبدالودود حنيف',
          'علي الحذيفي',
          'علي جابر',
          'علي حجاج السويسي',
          'عماد زهير حافظ',
          'فارس عباد',
          'ماجد الزامل',
          'ماهر المعيقلي',
          'ماهر شخاشيرو',
          'محمد أبوسنينة',
          'محمد أيوب',
          'محمد الأمين قنيوة',
          'محمد الطبلاوي',
          'محمد اللحيدان',
          'محمد جبريل',
          'محمد رشاد الشريف',
          'محمد صالح عالم شاه',
          'محمد صديق المنشاوي',
          'محمد عبدالكريم',
          'محمد عثمان خان',
          'محمود الرفاعي',
          'محمود خليل الحصري',
          'محمود علي البنا',
          'مشاري العفاسي',
          'مصطفى إسماعيل',
          'مصطفى اللاهوني',
          'مصطفى رعد العزاوي',
          'معيض الحارثي',
          'مفتاح السلطني',
          'موسى بلال',
          'ناصر العصفور',
          'ناصر القطامي',
          'ناصر الماجد',
          'نبيل الرفاعي',
          'نعمة الحسان',
          'هاني الرفاعي',
          'هيثم الجدعاني',
          'ياسر الدوسري',
          'ياسر القرشي',
          'يحيى حوا',
          'يوسف الشويعي',
          'يوسف بن نوح أحمد',
        };
        return list.where((s) => names.any((n) => s.name.contains(n))).toList();
      case 'ruqiah':
        return list.where((s) {
          final n = s.name;
          final u = s.url;
          return n.contains('الرقية') ||
              n.contains('السكينة') ||
              u.contains('roqiah') ||
              u.contains('sakeenah');
        }).toList();
      case 'fatwa':
        return list.where((s) {
          final n = s.name;
          final u = s.url;
          return n.contains('الفتاوى') ||
              n.contains('الاختيارات الفقهية') ||
              u.contains('fatwa') ||
              u.contains('alaikhtiarat_alfiqhayh_bin_baz');
        }).toList();
      case 'adhkar':
        return list.where((s) {
          final n = s.name;
          final u = s.url;
          return n.contains('أذكار الصباح') ||
              n.contains('أذكار المساء') ||
              n.contains('تكبيرات العيد') ||
              u.contains('athkar_sabah') ||
              u.contains('athkar_masa') ||
              u.contains('eid');
        }).toList();
      case 'qiraat':
        const qiraatUrls = {
          // Explicit riwayat by URL to disambiguate duplicates
          'ahmed_altrabulsi', // قالون عن نافع
          'ibrahim_aldosari', // ورش عن نافع
          'addokali_mohammad_alalim', // قالون عن نافع
          'aloyoon_alkoshi', // ورش عن نافع
          'alfateh_alzubair', // الدوري عن أبي عمرو
          'alqaria_yassen', // ورش عن نافع
          'tareq_abdulgani_daawob', // قالون عن نافع
          'abdulbasit_abdulsamad_warsh', // ورش عن نافع
          'abdulrasheed_soufi_assosi', // السوسي عن أبي عمرو
          'abdulrasheed_soufi_khalaf', // خلف عن حمزة
          'omar_alqazabri', // ورش عن نافع
          'mohammad_alabdullah_albizi', // البزي/قنبل عن ابن كثير
          'mohammad_alabdullah_aldorai', // الدوري عن الكسائي
          'mohammad_abdullkarem_alasbahani', // ورش عن نافع (طريق أبي بكر الأصبهاني)
          'mahmood_alsheimy', // الدوري عن الكسائي
          'mahmoud_khalil_alhussary_warsh', // ورش عن نافع
          'muftah_alsaltany_ibn_thakwan_an_ibn_amr', // ابن ذكوان عن ابن عامر
          'muftah_alsaltany_aldori_an_abi_amr', // الدوري عن أبي عمرو
          'muftah_alsaltany_aldorai', // الدوري (عن الكسائي)
          'waleed_alnaehi', // قالون عن نافع (طريق أبي نشيط)
          'yasser_almazroyee', // يعقوب الحضرمي (رويس وروح)
        };
        return list
            .where((s) => qiraatUrls.any((p) => s.url.contains(p)))
            .toList();
      case 'tafsir':
        return list.where((s) => s.name.contains('تفسير')).toList();
      case 'translations':
        return list
            .where((s) => s.name.contains('ترجمة معاني القرآن'))
            .toList();
      case 'seerah':
        return list
            .where(
              (s) => s.name.contains('السيرة') || s.name.contains('الصحابة'),
            )
            .toList();
      case 'seasons':
        return list.where((s) {
          final n = s.name;
          final u = s.url;
          return n.contains('رمضان') ||
              n.contains('ستة من شوال') ||
              n.contains('عشر ذي الحجة') ||
              n.contains('عاشوراء') ||
              u.contains('ramadan');
        }).toList();
      case 'featured':
        return list
            .where(
              (s) =>
                  s.name.contains('تراتيل') ||
                  s.name.contains('الإذاعة العامة') ||
                  s.name.contains('تلاوات') ||
                  s.name.contains('سورة'),
            )
            .toList();
      case 'all':
      default:
        return list;
    }
  }
}

class _CustomRadioAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onRefresh;

  const _CustomRadioAppBar({required this.title, this.onRefresh});

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color onPrimary = theme.colorScheme.onPrimary;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primary,
              Color.lerp(primary,
                  isDark ? Colors.black : const Color(0xFF0D1122), 0.3)!,
            ],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Animated background pattern
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                child: CustomPaint(
                  painter: _WavePatternPainter(
                    color: onPrimary.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 8),
                        if (Navigator.of(context).canPop())
                          Container(
                            decoration: BoxDecoration(
                              color: onPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: onPrimary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .backButtonTooltip,
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: onPrimary,
                              ),
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: onPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: onPrimary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: onPrimary.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.radio_rounded,
                              color: onPrimary,
                              size: 32,
                            ),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: onPrimary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF27AE60),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF27AE60)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'البث المباشر',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: onPrimary.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: onPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: onPrimary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            tooltip: 'تحديث',
                            icon: Icon(Icons.refresh_rounded, color: onPrimary),
                            onPressed: onRefresh,
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for wave pattern background
class _WavePatternPainter extends CustomPainter {
  final Color color;

  _WavePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final waveHeight = 20.0;
    final waveLength = size.width / 4;

    for (var i = 0; i < 3; i++) {
      path.reset();
      final yOffset = size.height * (0.3 + i * 0.2);

      for (var x = -waveLength; x <= size.width + waveLength; x += 0.5) {
        final y = yOffset +
            waveHeight *
                (0.5 + 0.5 * (i % 2 == 0 ? 1 : -1)) *
                (1 + 0.3 * i) *
                math.sin(x / waveLength);

        if (x == -waveLength) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePatternPainter oldDelegate) => false;
}

// Error View Widget
class _ErrorView extends StatelessWidget {
  final String message;
  final String errorType;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.errorType,
    required this.onRetry,
  });

  IconData _getErrorIcon() {
    switch (errorType) {
      case 'network':
        return Icons.wifi_off_rounded;
      case 'timeout':
        return Icons.timer_off_rounded;
      case 'playback':
        return Icons.error_outline_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getErrorColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (errorType) {
      case 'network':
        return isDark
            ? const Color(0xFF48A7E8)
            : const Color(0xFF3498DB); // Blue from theme
      case 'timeout':
        return isDark
            ? const Color(0xFFF06050)
            : const Color(0xFFE74C3C); // Red from theme
      case 'playback':
        return isDark
            ? const Color(0xFFE67E22)
            : const Color(0xFFD35400); // Orange from theme
      default:
        return isDark
            ? const Color(0xFFF1C40F)
            : const Color(0xFFDAA520); // Gold from theme
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = _getErrorColor(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getErrorIcon(),
                size: 80,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorType == 'network'
                  ? 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى'
                  : 'حاول مرة أخرى بعد قليل',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
