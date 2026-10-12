import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'format.dart';

/// Counts up on first show and glides whenever the value changes
/// (e.g. water loss drops when an admin resolves an incident).
class AnimatedNumber extends StatelessWidget {
  final double value;
  final String Function(double) format;
  final TextStyle? style;
  const AnimatedNumber({super.key, required this.value, this.format = _fmt, this.style});

  static String _fmt(double v) => fmtNum(v);

  @override
  Widget build(BuildContext context) {
    final s = (style ?? DefaultTextStyle.of(context).style).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final instant = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: instant ? value : 0, end: value),
      duration: instant ? Duration.zero : const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(format(v), style: s),
    );
  }
}
