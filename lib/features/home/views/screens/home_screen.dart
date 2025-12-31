import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'package:wadhakir/features/home/cubit/unsplash_cubit.dart';
import 'package:wadhakir/features/home/cubit/unsplash_state.dart';
import 'package:wadhakir/features/home/views/widgets/hadith_card_widget.dart';
import 'package:wadhakir/features/home/views/widgets/prayer_card_widget.dart';
import 'package:wadhakir/features/home/views/widgets/welcome_section_widget.dart';
import 'package:wadhakir/features/home/views/widgets/more_islamic_excerpts_widget.dart';
import 'package:wadhakir/features/home/views/widgets/palestine_support_card_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UnsplashCubit()..fetchMosqueImages(),
      child: const HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get today's date in Hijri
    final hijriToday = HijriDateTime.now();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocBuilder<UnsplashCubit, UnsplashState>(
        builder: (context, state) {
          final mosqueImage =
              context.read<UnsplashCubit>().getCurrentMosqueImage();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Welcome Section with Mosque Image
              SliverToBoxAdapter(
                child: WelcomeSectionWidget(
                  mosqueImage: mosqueImage,
                  hijriDate: hijriToday,
                ),
              ),
              // Compact Prayer Times Card
              SliverToBoxAdapter(
                child: CompactPrayerCardWidget(),
              ),
              // Hadith Card (Nawawi 40) - appears after the compact prayer card
              const SliverToBoxAdapter(
                child: HadithCardWidget(),
              ),
              // More Islamic Excerpts
              const SliverToBoxAdapter(
                child: MoreIslamicExcerptsWidget(),
              ),
              // Tight spacing between sections
              const SliverToBoxAdapter(
                child: SizedBox(height: 6),
              ),
              // Palestine Support Card
              const SliverToBoxAdapter(
                child: PalestineSupportCardWidget(),
              ),
              // more space
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }
}
