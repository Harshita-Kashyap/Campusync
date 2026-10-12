import 'package:flutter/material.dart';
import '../../services/app_repository.dart';
import '../../services/impact_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Impact and method: what each number means, how it is computed, and where AI is (and is not) used.
class ImpactScreen extends StatelessWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = ImpactService.compute(RepositoryScope.of(context));
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Impact & methodology'), actions: const [ThemeToggleButton(), SizedBox(width: 4)]),
      body: SafeArea(
        child: PageBody(children: [
          const DemoNote(),
          const SizedBox(height: 4),
          Text('Units are never combined into one score.', style: t.bodySmall),
          const SectionHeading('How the system decides'),
          Reveal(
            child: AppCard(
              child: ExplainSteps(steps: const [
                ExplainStep(icon: Icons.photo_camera_outlined, title: 'AI reads the leak photo',
                    detail: 'A vision model suggests type, severity and litres per hour. The student confirms or edits.'),
                ExplainStep(icon: Icons.rule, title: 'Rules score and rank',
                    detail: 'Energy alerts, the priority queue and suggested actions use plain, readable rules.', tone: Tone.info),
                ExplainStep(icon: Icons.fact_check_outlined, title: 'Evidence on every item',
                    detail: 'Tap any queue item or alert to see the steps behind it.', tone: Tone.success),
                ExplainStep(icon: Icons.verified_outlined, title: 'Honest labels',
                    detail: 'Saved samples and fallbacks are never shown as live AI.', tone: Tone.warning),
              ]),
            ),
          ),
          const SectionHeading('Energy', trailing: _Sdg('SDG 7, 13')),
          _Metric('Excess energy', '${fmtNum(m.excessKwh, 1)} kWh', 'Sum of max(0, actual − expected) over active alerts.'),
          _Metric('Cost', '₹${fmtNum(m.energyCost)}', 'Excess kWh × tariff per kWh.'),
          _Metric('Emissions', '${fmtNum(m.co2Kg, 1)} kg CO₂e', 'Excess kWh × CO₂ factor per kWh.'),
          const SectionHeading('Water', trailing: _Sdg('SDG 6')),
          _Metric('Current loss', '${fmtNum(m.waterActiveLossLitres)} L', 'Litres per hour × hours, open and in-progress incidents only.'),
          _Metric('Historical loss', '${fmtNum(m.waterHistoricalLossLitres)} L', 'Same formula including resolved incidents. Dismissed are excluded.'),
          const SectionHeading('Paperless', trailing: _Sdg('SDG 12')),
          _Metric('Pages avoided', fmtNum(m.pagesAvoided), 'Sum of declared per-submission estimates. A counterfactual, not verified.'),
        ]),
      ),
    );
  }
}

class _Sdg extends StatelessWidget {
  final String text;
  const _Sdg(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.bodySmall);
}

class _Metric extends StatelessWidget {
  final String name, value, how;
  const _Metric(this.name, this.value, this.how);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(name, style: t.titleSmall)),
            Text(value, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 4),
          Text(how, style: t.bodySmall),
        ]),
      ),
    );
  }
}
