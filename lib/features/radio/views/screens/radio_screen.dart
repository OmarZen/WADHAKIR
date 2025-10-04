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

    return Scaffold(
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
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  return Center(child: Text(state.message));
                }
                if (state is RadioLoaded) {
                  final filtered = _applyCategory(state)
                      .where(
                        (s) =>
                            s.name.toLowerCase().contains(_query.toLowerCase()),
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
                      final isCurrentStation = state.current?.id == station.id;
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
  Size get preferredSize => const Size.fromHeight(110);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color onPrimary = theme.colorScheme.onPrimary;

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, Color.lerp(primary, Colors.black, 0.15)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            child: Row(
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    icon: Icon(Icons.arrow_back_rounded, color: onPrimary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                else
                  Icon(Icons.radio_rounded, color: onPrimary, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: Icon(Icons.refresh_rounded, color: onPrimary),
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
