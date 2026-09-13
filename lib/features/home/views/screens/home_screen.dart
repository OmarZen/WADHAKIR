import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/features/share/views/widgets/occasion_card.dart';
// Hadith card removed: feature and assets pruned
import 'package:wadhakir/features/home/views/widgets/prayer_card_widget.dart';
import 'package:wadhakir/features/home/views/widgets/welcome_section_widget.dart';
import 'package:wadhakir/features/home/views/widgets/name_prompt_sheet.dart';
import 'package:wadhakir/features/home/views/widgets/home_streak_banner.dart';
import 'package:wadhakir/features/home/views/widgets/more_islamic_excerpts_widget.dart';
import 'package:wadhakir/features/home/views/widgets/palestine_support_card_widget.dart';
import 'package:wadhakir/features/home/views/widgets/daily_progress_strip.dart';
import 'package:wadhakir/features/home/views/widgets/religious_occasions_strip.dart';
import 'package:wadhakir/features/daily_inspiration/views/widgets/daily_inspiration_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeScreenContent();
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  @override
  void initState() {
    super.initState();
    // Existing users (who never saw the onboarding name page) get a one-time
    // gentle prompt to add their name. No-op for everyone else.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NamePromptSheet.maybeShow(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get today's date in Hijri
    final hijriToday = HijriDateTime.now();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // The hero. Its ground is drawn in code now — see HeroBackdrop.
          SliverToBoxAdapter(
            child: WelcomeSectionWidget(hijriDate: hijriToday),
          ),
          // Compact Prayer Times Card
          SliverToBoxAdapter(child: CompactPrayerCardWidget()),
          // Salah streak + today's prayers — "don't break the chain"
          // Present on a Friday and on six annual occasions, and an
          // empty box on every other day — see OccasionCard. High in the
          // list because the whole point is that it is seen ON the day.
          const SliverToBoxAdapter(child: OccasionCard()),
          const SliverToBoxAdapter(child: HomeStreakBanner()),
          // Daily progress (wird / adhkar / nawafil)
          const SliverToBoxAdapter(child: DailyProgressStrip()),
          // Verse/Dua of the Day card
          const SliverToBoxAdapter(child: DailyInspirationCard()),
          // Feature directory grouped into labelled sections
          const SliverToBoxAdapter(child: MoreIslamicExcerptsWidget()),
          // Religious occasions strip
          const SliverToBoxAdapter(child: ReligiousOccasionsStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
          // Palestine Support Card
          const SliverToBoxAdapter(child: PalestineSupportCardWidget()),
          // more space
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
