import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'reveal.dart';

class ExplainStep {
  final IconData icon;
  final String title;
  final String? detail, value;
  final Tone tone;
  const ExplainStep({required this.icon, required this.title, this.detail, this.value, this.tone = Tone.brand});
}

/// The "evidence trail": step by step, how a number or alert came to be.
/// This is what lets judges follow what the system decided and why.
class ExplainSteps extends StatelessWidget {
  final List<ExplainStep> steps;
  const ExplainSteps({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    return Column(children: [
      for (var i = 0; i < steps.length; i++)
        Reveal(
          delay: stagger(i, 70),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                width: 32,
                child: Column(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: pal.of(steps[i].tone).withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: Icon(steps[i].icon, size: 16, color: pal.of(steps[i].tone)),
                  ),
                  if (i < steps.length - 1)
                    Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: pal.line)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 5, bottom: i < steps.length - 1 ? 18 : 0),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(steps[i].title, style: t.titleSmall),
                        if (steps[i].detail != null) ...[const SizedBox(height: 2), Text(steps[i].detail!, style: t.bodySmall)],
                      ]),
                    ),
                    if (steps[i].value != null) ...[
                      const SizedBox(width: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(steps[i].value!, textAlign: TextAlign.right,
                            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
        ),
    ]);
  }
}
