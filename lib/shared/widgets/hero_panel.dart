import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The single high-emphasis surface on a screen.
class HeroPanel extends StatelessWidget {
  final Widget child;
  const HeroPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: context.pal.hero, borderRadius: BorderRadius.circular(28)),
        child: child,
      );
}
