
import 'package:campusync/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../shared/widgets/widgets.dart';

/// Demo navigation only — role selection is NOT production security.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _headingFade;
  late final Animation<Offset> _headingSlide;
  late final Animation<double> _studentFade;
  late final Animation<Offset> _studentSlide;
  late final Animation<double> _adminFade;
  late final Animation<Offset> _adminSlide;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );

    _brandFade = _fade(0.0, 0.45);
    _brandSlide = _slide(0.0, 0.45);

    _headingFade = _fade(0.12, 0.62);
    _headingSlide = _slide(0.12, 0.62);

    _studentFade = _fade(0.35, 0.78);
    _studentSlide = _slide(0.35, 0.78);

    _adminFade = _fade(0.48, 0.90);
    _adminSlide = _slide(0.48, 0.90);

    _footerFade = _fade(0.65, 1.0);

    _controller.forward();
  }

  Animation<double> _fade(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(
        begin,
        end,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Animation<Offset> _slide(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          begin,
          end,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _entrance({
    required Animation<double> fade,
    required Animation<Offset> slide,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;
            final horizontalPadding = isDesktop ? 36.0 : 20.0;

            // Introduction section
            final hero = _entrance(
              fade: _brandFade,
              slide: _brandSlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      size: 35,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.spa_rounded,
                          size: 15,
                          color: colors.onSecondaryContainer,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'A GREENER CAMPUS STARTS HERE',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Small actions.\nLasting impact.',
                    style: (isDesktop
                            ? textTheme.displayMedium
                            : textTheme.displaySmall)
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      letterSpacing: -1.2,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 440,
                    ),
                    child: Text(
                      'A leaking tap, a wasted light, a better '
                      'tomorrow. Choose your space in the change.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );

            // Role selection section
            final roleCards = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _entrance(
                  fade: _studentFade,
                  slide: _studentSlide,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'How will you contribute?',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.waving_hand_rounded,
                        size: 21,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _entrance(
                  fade: _studentFade,
                  slide: _studentSlide,
                  child: _RoleCard(
                    icon: Icons.school_rounded,
                    title: 'I’m a student',
                    subtitle: 'Notice something? Make it better.',
                    description:
                        'Report campus issues and track their progress.',
                    tag: 'TAKE ACTION',
                    iconColor: colors.primary,
                    iconBackground: colors.primaryContainer,
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        Routes.student,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _entrance(
                  fade: _adminFade,
                  slide: _adminSlide,
                  child: _RoleCard(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'I’m an administrator',
                    subtitle: 'Turn reports into real action.',
                    description:
                        'Prioritize issues and manage resolutions.',
                    tag: 'MANAGE CAMPUS',
                    iconColor: colors.tertiary,
                    iconBackground: colors.tertiaryContainer,
                    onTap: () {
                      Navigator.pushReplacementNamed(
                        context,
                        Routes.admin,
                      );
                    },
                  ),
                ),
              ],
            );

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top navigation bar
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.eco_rounded,
                              color: colors.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'campusync',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: colors.onSurface,
                            ),
                          ),
                          const Spacer(),
                          const ThemeToggleButton(),
                        ],
                      ),

                      SizedBox(height: isDesktop ? 64 : 36),

                      // Laptop: two columns.
                      // Phone/tablet: single column.
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 24,
                                  right: 36,
                                ),
                                child: hero,
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: roleCards,
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            hero,
                            const SizedBox(height: 40),
                            roleCards,
                          ],
                        ),

                      const SizedBox(height: 32),

                      // Demo disclaimer
                      _entrance(
                        fade: _footerFade,
                        slide: _adminSlide,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.outlineVariant,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Demo mode · Sample campus data. '
                                  'Role selection is for demonstration '
                                  'only, not authentication.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        'BUILT FOR A MORE SUSTAINABLE TOMORROW',
                        textAlign: TextAlign.center,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final String tag;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tag,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AnimatedScale(
      scale: _pressed ? 0.99 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          splashColor: widget.iconColor.withValues(alpha: 0.08),
          highlightColor: widget.iconColor.withValues(alpha: 0.035),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colors.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.iconBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          widget.icon,
                          color: colors.onPrimaryContainer ==
                                  widget.iconColor
                              ? colors.onPrimaryContainer
                              : widget.iconColor,
                          size: 27,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: colors.secondaryContainer,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            widget.tag,
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: widget.iconColor,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue',
                        style: textTheme.labelLarge?.copyWith(
                          color: widget.iconColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 19,
                        color: widget.iconColor,
                      ),
                    ],
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
