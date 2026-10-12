import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

/// Light / dark switch for any AppBar (hidden if no ThemeScope, e.g. in isolated tests).
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = ThemeScope.maybeOf(context);
    if (ctrl == null) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () => ctrl.toggle(Theme.of(context).brightness),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, key: ValueKey(dark)),
      ),
    );
  }
}
