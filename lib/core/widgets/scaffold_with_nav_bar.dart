import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
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
  bool _showRadioPlayer = true;

  bool _hasSetupRadioListener = false;
  StreamSubscription? _radioSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Setup RadioCubit listener only once
    if (!_hasSetupRadioListener) {
      _radioSubscription = context.read<RadioCubit>().stream.listen((state) {
        if (state is RadioLoaded &&
            state.current != null &&
            !_showRadioPlayer) {
          setState(() {
            _showRadioPlayer = true;
          });
        }
      });
      _hasSetupRadioListener = true;
    }
  }

  @override
  void dispose() {
    _radioSubscription?.cancel();
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

  /// A single pill-style navigation item: icon-only when inactive, icon +
  /// label inside a rounded highlight when active (mimics the previous GNav
  /// look without the extra dependency).
  Widget _buildNavItem({
    required int index,
    required Widget icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
    required Size size,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        _onItemTapped(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? size.width * 0.045 : size.width * 0.03,
          vertical: size.height * 0.012,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme.merge(
              data: IconThemeData(
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
              child: icon,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const QuranScreen();
      case 2:
        return const AzkarScreen();
      case 3:
      default:
        return const SettingsScreen();
    }
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

    // Colors for nav icons
    final inactiveColor = theme.colorScheme.onPrimary.withValues(alpha: 0.75);
    final activeColor = theme.colorScheme.onPrimary;

    // Navigation items
    // (kept for reference if switching packages later)

    return Scaffold(
      body: FadeTransition(
        opacity: _animationController,
        child: _buildCurrentScreen(),
      ),
      extendBody: true,
      bottomSheet: BlocBuilder<RadioCubit, RadioState>(
        builder: (context, state) {
          // Hide widget if not in RadioLoaded state, or current is null, or _showRadioPlayer is false
          if (state is! RadioLoaded ||
              state.current == null ||
              !_showRadioPlayer) {
            return const SizedBox.shrink();
          }
          return Container(
            color: Colors.transparent,
            child: RadioPlayerBar(
              onClose: () async {
                final cubit = context.read<RadioCubit>();
                await cubit.stop();
                setState(() {
                  _showRadioPlayer = false;
                });
              },
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.18,
                      ),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: const Icon(Icons.home_rounded, size: 22),
                      label: l10n?.translate('nav_bar.home') ?? 'الرئيسية',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      size: size,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedQuran01,
                        color: _selectedIndex == 1
                            ? activeColor
                            : inactiveColor,
                        size: 22,
                      ),
                      label: l10n?.translate('nav_bar.quran') ?? 'المصحف',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      size: size,
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 22,
                      ),
                      label: l10n?.translate('nav_bar.azkar') ?? 'الاذكار',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      size: size,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: const Icon(Icons.settings_rounded, size: 22),
                      label: l10n?.translate('nav_bar.settings') ?? 'الإعدادات',
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      size: size,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
