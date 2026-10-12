import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'animated_number.dart';
import 'app_card.dart';
import 'format.dart';

class MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value; // used when [number] is null
  final String? note;
  final Tone tone;
  final double? number;
  final String Function(double)? format;
  const MetricTile({super.key, required this.icon, required this.label, this.value = '', this.note,
      this.tone = Tone.brand, this.number, this.format});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final c = pal.of(tone);
    final t = Theme.of(context).textTheme;
    final style = t.titleLarge!.copyWith(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5);
    final f = format ?? fmtNum;
    return Semantics(
      label: '$label: ${number != null ? f(number!) : value}',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: c),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: number != null ? AnimatedNumber(value: number!, format: f, style: style) : Text(value, style: style),
          ),
          const SizedBox(height: 2),
          Text(label, style: t.bodySmall),
          if (note != null) Text(note!, style: t.labelSmall),
        ]),
      ),
    );
  }
}

/// Equal-height grid of tiles; no fixed aspect ratios (safe with large text).
class MetricGrid extends StatelessWidget {
  final List<Widget> children;
  final int? columns;
  const MetricGrid({super.key, required this.children, this.columns});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = columns ?? (c.maxWidth > 720 ? 4 : 2);
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final slice = children.sublist(i, math.min(i + cols, children.length));
          rows.add(IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(child: j < slice.length ? slice[j] : const SizedBox.shrink()),
              ],
            ]),
          ));
        }
        return Column(children: [for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: 12), rows[i]]]);
      });
}
