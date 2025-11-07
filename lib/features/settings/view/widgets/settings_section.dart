import 'package:flutter/material.dart';

class SettingsSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;
  final String? subtitle;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.subtitle,
  });

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovered = true;
        _controller.forward();
      }),
      onExit: (_) => setState(() {
        _isHovered = false;
        _controller.reverse();
      }),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Section Header with Glass Morphism Effect
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                    child: Row(
                      children: [
                        if (widget.icon != null) ...[
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary
                                            .withValues(alpha: 0.15),
                                        theme.colorScheme.primary
                                            .withValues(alpha: 0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    color: isDark
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 17,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Futuristic Card with Glassmorphism
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF1A1F3A).withValues(alpha: 0.6),
                                const Color(0xFF0F1419).withValues(alpha: 0.4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.95),
                                Colors.white.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isHovered
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isHovered
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.15)
                              : (isDark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.06)),
                          blurRadius: _isHovered ? 20 : 12,
                          offset: Offset(0, _isHovered ? 6 : 4),
                        ),
                        if (isDark)
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: BackdropFilter(
                      filter: isDark
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.src,
                            )
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.src,
                            ),
                      child: Column(
                        children: widget.children,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
