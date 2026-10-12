import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Actual draw (filled) against the expected baseline (tick). Fills in on first show.
class LoadBar extends StatelessWidget {
  final double actual, expected, max;
  final bool over;
  const LoadBar({super.key, required this.actual, required this.expected, required this.max, this.over = false});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final top = max <= 0 ? 1.0 : max;
    final fill = (actual / top).clamp(0.0, 1.0);
    final mark = (expected / top).clamp(0.0, 1.0);
    final instant = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: instant ? fill : 0, end: fill),
        duration: instant ? Duration.zero : const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, f, __) => SizedBox(
          height: 16,
          child: Stack(children: [
            Positioned(left: 0, right: 0, top: 4, bottom: 4,
                child: DecoratedBox(decoration: BoxDecoration(color: pal.surfaceHigh, borderRadius: BorderRadius.circular(4)))),
            Positioned(left: 0, top: 4, bottom: 4, width: w * f,
                child: DecoratedBox(decoration: BoxDecoration(color: over ? pal.danger : pal.success, borderRadius: BorderRadius.circular(4)))),
            Positioned(left: (w * mark - 1).clamp(0.0, w - 2), top: 0, bottom: 0, width: 2,
                child: DecoratedBox(decoration: BoxDecoration(color: pal.ink, borderRadius: BorderRadius.circular(1)))),
          ]),
        ),
      );
    });
  }
}
