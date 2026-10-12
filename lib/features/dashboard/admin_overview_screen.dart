import 'package:flutter/material.dart';
import '../../services/app_repository.dart';
import '../../services/impact_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../impact/impact_screen.dart';
import 'role_switch_button.dart';

class AdminOverviewScreen extends StatelessWidget {
  final ValueChanged<int> onOpenTab; // 1 energy, 2 water, 3 submissions
  const AdminOverviewScreen({super.key, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final m = ImpactService.compute(repo);
    final w = MediaQuery.of(context).size.width;
    final cols = w > 900 ? 4 : (w > 600 ? 3 : 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Campus overview'), actions: const [RoleSwitchButton()]),
      body: SafeArea(
        child: ListView(padding: EdgeInsets.all(w > 600 ? 28 : 20), children: [
          const Row(children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.amber),
            SizedBox(width: 6),
            Expanded(child: Text(demoLabel, style: TextStyle(fontSize: 12, color: AppColors.muted))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _stat(context, '${m.openIncidents + m.activeAlerts}', 'Open items'),
            _stat(context, '${m.criticalHigh}', 'Critical / high'),
            _stat(context, '${m.resolvedItems}', 'Resolved'),
          ]),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.05,
            children: [
              MetricTile(icon: Icons.bolt, label: 'Estimated excess energy', value: '${m.excessKwh.toStringAsFixed(1)} kWh', note: 'active alerts', color: AppColors.amber),
              MetricTile(icon: Icons.currency_rupee, label: 'Estimated excess energy cost', value: '₹${m.energyCost.toStringAsFixed(0)}', note: 'active alerts', color: AppColors.amber),
              MetricTile(icon: Icons.cloud_outlined, label: 'Estimated excess emissions', value: '${m.co2Kg.toStringAsFixed(1)} kg CO₂e', note: 'active alerts', color: AppColors.muted),
              MetricTile(icon: Icons.water_drop, label: 'Estimated water loss (current)', value: '${m.waterActiveLossLitres.toStringAsFixed(0)} L', note: 'open + in-progress only'),
              MetricTile(icon: Icons.report_problem_outlined, label: 'Open / in-progress incidents', value: '${m.openIncidents}', color: AppColors.coral),
              MetricTile(icon: Icons.description_outlined, label: 'Estimated pages avoided', value: '${m.pagesAvoided}', note: 'declared estimate', color: AppColors.leaf),
            ],
          ),
          const SectionHeading('Priority queue'),
          if (m.queue.isEmpty)
            const Card(child: EmptyState(title: 'No active alerts', message: 'Nothing needs attention right now.'))
          else
            for (final q in m.queue.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showActions(context, repo, q),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(q.type == 'water' ? Icons.water_drop : Icons.bolt, color: AppColors.forest),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(q.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(q.subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(timeAgo(q.time), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 6, runSpacing: 6, children: [StatusBadge.priority(q.priority), StatusBadge.status(q.status)]),
                          ]),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.muted),
                      ]),
                    ),
                  ),
                ),
              ),
          const SectionHeading('Recent recommendations'),
          if (m.recommendations.isEmpty)
            const Card(child: EmptyState(title: 'No recommendations yet'))
          else
            for (final r in m.recommendations.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700))), StatusBadge.priority(r.priority)]),
                      const SizedBox(height: 6),
                      Text('Evidence: ${r.evidenceSummary}', style: const TextStyle(color: AppColors.muted)),
                      Text('Action: ${r.suggestedAction}'),
                    ]),
                  ),
                ),
              ),
          const SectionHeading('Modules'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: () => onOpenTab(1), icon: const Icon(Icons.bolt), label: const Text('Energy')),
            OutlinedButton.icon(onPressed: () => onOpenTab(2), icon: const Icon(Icons.water_drop_outlined), label: const Text('Water')),
            OutlinedButton.icon(onPressed: () => onOpenTab(3), icon: const Icon(Icons.upload_file), label: const Text('Submissions')),
            OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpactScreen())),
                icon: const Icon(Icons.rule), label: const Text('How we calculate')),
          ]),
        ]),
      ),
    );
  }

  Widget _stat(BuildContext c, String v, String l) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Text(v, style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.forest)),
              Text(l, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
        ),
      );

  void _showActions(BuildContext context, AppRepository repo, QueueItem q) {
    final messenger = ScaffoldMessenger.of(context);
    final options = q.type == 'water'
        ? ['open', 'in_progress', 'resolved', 'dismissed'].where((s) => s != q.status)
        : ['resolved', 'dismissed'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q.title, style: Theme.of(ctx).textTheme.titleLarge),
            Text(q.subtitle, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            const Text('Update status', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in options)
                FilledButton.tonal(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (q.type == 'water') {
                      await repo.updateIncidentStatus(q.id, s);
                    } else {
                      await repo.updateAlertStatus(q.id, s);
                    }
                    messenger.showSnackBar(SnackBar(content: Text('${q.title} marked ${s.replaceAll('_', ' ')}')));
                  },
                  child: Text(s.replaceAll('_', ' ')),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
