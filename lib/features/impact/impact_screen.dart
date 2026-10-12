import 'package:flutter/material.dart';
import '../../services/app_repository.dart';
import '../../services/impact_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Impact / Methodology: separate units, formula, scope for every metric.
class ImpactScreen extends StatelessWidget {
  const ImpactScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final m = ImpactService.compute(RepositoryScope.of(context));
    Widget row(String name, String value, String how) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: ListTile(
              title: Text('$name: $value', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(how),
            ),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Impact & methodology')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text(demoLabel, style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          const Text('Units are never combined into a single score.'),
          const SectionHeading('Energy (SDG 7, 13)'),
          row('Estimated excess energy', '${m.excessKwh.toStringAsFixed(1)} kWh', 'Σ max(0, actual − expected) over active alerts.'),
          row('Estimated cost', '₹${m.energyCost.toStringAsFixed(0)}', 'excess kWh × tariff per kWh.'),
          row('Estimated emissions', '${m.co2Kg.toStringAsFixed(1)} kg CO₂e', 'excess kWh × CO₂ factor per kWh.'),
          const SectionHeading('Water (SDG 6)'),
          row('Estimated current loss', '${m.waterActiveLossLitres.toStringAsFixed(0)} L', 'litres/hour × hours, open + in-progress incidents only.'),
          row('Historical estimated loss', '${m.waterHistoricalLossLitres.toStringAsFixed(0)} L', 'Same formula, including resolved incidents; dismissed excluded.'),
          const SectionHeading('Paperless (SDG 12)'),
          row('Estimated pages avoided', '${m.pagesAvoided}', 'Sum of declared per-submission estimates (counterfactual, not verified).'),
        ]),
      ),
    );
  }
}
