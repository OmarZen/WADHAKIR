import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:wadhakir/features/radio/cubit/radio_cubit.dart';
import 'package:wadhakir/features/radio/cubit/radio_state.dart';
import 'package:wadhakir/core/localization/app_localizations.dart';
import '../../features/settings/view/screens/settings_screen.dart';
import 'package:wadhakir/features/home/views/screens/home_screen.dart';
import 'package:wadhakir/features/quran/views/screens/quran_screen.dart';
import 'package:wadhakir/features/azkar/views/screens/azkar_screen.dart';
import 'package:wadhakir/features/radio/views/widgets/radio_player_bar.dart';


class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({super.key});

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;

  final List<Widget> _screens = const [
    HomeScreen(),
    QuranScreen(),
    AzkarScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    // Trigger animation when changing tabs
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final primaryColor = theme.primaryColor;
    final isLightMode = theme.brightness == Brightness.light;
    final navBackground = isLightMode
        ? primaryColor.withValues(alpha: 0.95)
        : const Color(0xFF2C2C2C).withValues(alpha: 0.95);

    // Navigation items
    // (kept for reference if switching packages later)

    return Scaffold(
      body: FadeTransition(
        opacity: _animationController,
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      extendBody: true,
      bottomSheet: BlocBuilder<RadioCubit, RadioState>(
        builder: (context, state) {
          if (state is! RadioLoaded || state.current == null) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            child: Stack(
              children: [
                const RadioPlayerBar(),
                Positioned(
                  right: 18,
                  top: 6,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.06),
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                      iconSize: 18,
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () async {
                        final cubit = context.read<RadioCubit>();
                        await cubit.stop();
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: size.width * 0.04,
          right: size.width * 0.04,
          bottom: size.height * 0.018,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: navBackground,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.2,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04,
                vertical: size.height * 0.008,
              ),
              child: GNav(
                gap: 8,
                rippleColor: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
                hoverColor: theme.colorScheme.onPrimary.withValues(alpha: 0.06),
                haptic: true,
                tabBorderRadius: 16,
                curve: Curves.easeOutCubic,
                duration: const Duration(milliseconds: 350),
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.75),
                activeColor: theme.colorScheme.onPrimary,
                iconSize: 22,
                tabBackgroundColor: Colors.white.withValues(alpha: 0.12),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.045,
                  vertical: size.height * 0.012,
                ),
                selectedIndex: _selectedIndex,
                onTabChange: _onItemTapped,
                tabs: [
                  GButton(
                    icon: Icons.home_rounded,
                    text: l10n?.translate('nav_bar.home') ?? 'الرئيسية',
                  ),
                  GButton(
                    icon: Icons.menu_book_rounded,
                    text: l10n?.translate('nav_bar.quran') ?? 'المصحف',
                  ),
                  GButton(
                    icon: Icons.format_list_bulleted_rounded,
                    text: l10n?.translate('nav_bar.azkar') ?? 'الاذكار',
                  ),
                  GButton(
                    icon: Icons.settings_rounded,
                    text: l10n?.translate('nav_bar.settings') ?? 'الإعدادات',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavItem({required this.icon, required this.activeIcon, required this.label});
}
