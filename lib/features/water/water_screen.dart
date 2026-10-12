import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../services/water_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../dashboard/role_switch_button.dart';

/// Admin: list, filter and update water incidents.
class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});
  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  String _status = 'all';
  String _sev = 'all';

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final all = repo.getIncidents();
    final items = all
        .where((i) => (_status == 'all' || i.status == _status) && (_sev == 'all' || i.severity == _sev))
        .toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    final current = WaterService(repo).getEstimatedWaterLossLitres();

    return ModuleScaffold(
      title: 'Water',
      actions: const [RoleSwitchButton()],
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.water_drop, color: AppColors.forest),
            title: Text('Estimated current loss: ~${current.toStringAsFixed(0)} L'),
            subtitle: const Text('Open + in-progress incidents only. Estimates from reported rate × duration.'),
          ),
        ),
        const SectionHeading('Filter'),
        _chips('Status', const ['all', 'open', 'in_progress', 'resolved', 'dismissed'], _status, (v) => setState(() => _status = v)),
        const SizedBox(height: 8),
        _chips('Severity', const ['all', ...waterSeverities], _sev, (v) => setState(() => _sev = v)),
        const SectionHeading('Incidents'),
        if (items.isEmpty)
          Card(child: EmptyState(title: all.isEmpty ? 'No incidents reported' : 'No incidents match these filters'))
        else
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _detail(context, repo, i),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(i.locationName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${labelOf(i.issueType)} · ${timeAgo(i.reportedAt)}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      Text('~${i.estimatedLitresLost.toStringAsFixed(0)} L lost (estimate)', style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: [StatusBadge.priority(i.severity), StatusBadge.status(i.status)]),
                    ]),
                  ),
                ),
              ),
            ),
      ]),
    );
  }

  Widget _chips(String label, List<String> opts, String sel, ValueChanged<String> on) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          Wrap(spacing: 6, children: [
            for (final o in opts) ChoiceChip(label: Text(labelOf(o)), selected: sel == o, onSelected: (_) => on(o)),
          ]),
        ],
      );

  void _detail(BuildContext context, AppRepository repo, WaterIncident i) {
    final messenger = ScaffoldMessenger.of(context);
    final options = ['open', 'in_progress', 'resolved', 'dismissed'].where((s) => s != i.status);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i.locationName, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: [StatusBadge.priority(i.severity), StatusBadge.status(i.status)]),
            const SizedBox(height: 12),
            Text(i.description),
            const SizedBox(height: 8),
            Text('${labelOf(i.issueType)} · ${i.estimatedLitresPerHour.toStringAsFixed(0)} L/h × ${i.estimatedDurationHours.toStringAsFixed(1)} h '
                '= ~${i.estimatedLitresLost.toStringAsFixed(0)} L (estimate)', style: const TextStyle(color: AppColors.muted)),
            Text(i.status == 'open' || i.status == 'in_progress' ? 'Counts toward current loss.' : 'Not counted in current loss.',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 16),
            const Text('Update status', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in options)
                FilledButton.tonal(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await WaterService(repo).updateIncidentStatus(i.id, s);
                    messenger.showSnackBar(SnackBar(content: Text('${i.locationName} marked ${labelOf(s)}')));
                  },
                  child: Text(labelOf(s)),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
