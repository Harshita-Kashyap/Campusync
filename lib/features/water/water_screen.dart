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
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    final all = repo.getIncidents();
    final items = all.where((i) => (_status == 'all' || i.status == _status) && (_sev == 'all' || i.severity == _sev)).toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    final current = WaterService(repo).getEstimatedWaterLossLitres();
    int count(String s) => s == 'all' ? all.length : all.where((i) => i.status == s).length;

    return ModuleScaffold(
      title: 'Water',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Filter by severity',
          icon: Badge(isLabelVisible: _sev != 'all', smallSize: 8, child: const Icon(Icons.filter_list)),
          onSelected: (v) => setState(() => _sev = v),
          itemBuilder: (_) => [
            for (final o in const ['all', ...waterSeverities])
              CheckedPopupMenuItem<String>(value: o, checked: _sev == o, child: Text(o == 'all' ? 'Any severity' : prettyStatus(o))),
          ],
        ),
        const ThemeToggleButton(),
        const RoleSwitchButton(),
        const SizedBox(width: 4),
      ],
      body: PageBody(children: [
        Reveal(
          child: AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Estimated loss right now', style: t.bodySmall),
              const SizedBox(height: 4),
              AnimatedNumber(value: current, format: (v) => '~${fmtNum(v)} L', style: t.headlineMedium?.copyWith(color: pal.info)),
              const SizedBox(height: 6),
              Text('Open and in-progress incidents only. Rate × hours, as reported.', style: t.bodySmall),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final s in const ['all', 'open', 'in_progress', 'resolved', 'dismissed'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${s == 'all' ? 'All' : prettyStatus(s)} ${count(s)}'),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          AppCard(child: EmptyState(title: all.isEmpty ? 'No incidents reported' : 'No incidents match these filters', icon: Icons.water_drop_outlined))
        else
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Reveal(
                key: ValueKey('${items[i].id}-$_status-$_sev'),
                delay: stagger(i),
                child: AppCard(
                  onTap: () => _detail(context, repo, items[i]),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(items[i].locationName, style: t.titleSmall),
                        const SizedBox(height: 2),
                        Text('${prettyStatus(labelOf(items[i].issueType))}, ${timeAgo(items[i].reportedAt)}', style: t.bodySmall),
                        const SizedBox(height: 2),
                        Text('~${fmtNum(items[i].estimatedLitresLost)} L lost (estimate)', style: t.bodyMedium),
                        const SizedBox(height: 10),
                        Wrap(spacing: 6, runSpacing: 6, children: [StatusBadge.priority(items[i].severity), StatusBadge.status(items[i].status)]),
                      ]),
                    ),
                    Icon(Icons.chevron_right, color: pal.muted),
                  ]),
                ),
              ),
            ),
      ]),
    );
  }

  void _detail(BuildContext context, AppRepository repo, WaterIncident i) {
    final messenger = ScaffoldMessenger.of(context);
    final options = ['open', 'in_progress', 'resolved', 'dismissed'].where((s) => s != i.status).toList();
    showAppSheet<void>(
      context,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(i.locationName, style: t.titleLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [StatusBadge.priority(i.severity), StatusBadge.status(i.status)]),
          const SizedBox(height: 12),
          Text(i.description, style: t.bodyLarge),
          const SizedBox(height: 24),
          Text('How the loss was estimated', style: t.titleMedium),
          const SizedBox(height: 14),
          ExplainSteps(steps: waterEvidence(i)),
          const SizedBox(height: 24),
          StatusActions(
            options: options,
            onPick: (s) async {
              Navigator.pop(ctx);
              await WaterService(repo).updateIncidentStatus(i.id, s);
              messenger.showSnackBar(SnackBar(content: Text('${i.locationName} marked ${prettyStatus(s).toLowerCase()}')));
            },
          ),
        ]);
      },
    );
  }
}
