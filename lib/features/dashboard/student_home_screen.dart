import 'package:flutter/material.dart';
import '../../services/app_repository.dart';
import '../../services/impact_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import 'role_switch_button.dart';

class StudentHomeScreen extends StatelessWidget {
  final ValueChanged<int> onOpenTab; // 1 report, 2 my activity
  const StudentHomeScreen({super.key, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final m = ImpactService.compute(repo);
    final mine = repo.getIncidents().reversed.take(3).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Campusync'), actions: const [RoleSwitchButton()]),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Your campus, a little better.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.forest)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => onOpenTab(1), icon: const Icon(Icons.add), label: const Text('Report a problem')),
          const SectionHeading('Campus snapshot'),
          const Text(demoLabel, style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: Row(children: [
              Expanded(child: MetricTile(icon: Icons.water_drop, label: 'Est. water loss (current)', value: '${m.waterActiveLossLitres.toStringAsFixed(0)} L')),
              const SizedBox(width: 10),
              Expanded(child: MetricTile(icon: Icons.report_problem_outlined, label: 'Open incidents', value: '${m.openIncidents}', color: AppColors.coral)),
              const SizedBox(width: 10),
              Expanded(child: MetricTile(icon: Icons.description_outlined, label: 'Est. pages avoided', value: '${m.pagesAvoided}', color: AppColors.leaf)),
            ]),
          ),
          const SectionHeading('Recent reports'),
          if (mine.isEmpty)
            const Card(child: EmptyState(title: 'Nothing reported yet', message: 'If you notice waste, you can help fix it.'))
          else
            for (final i in mine)
              Card(child: ListTile(title: Text(i.locationName), subtitle: Text(timeAgo(i.reportedAt)), trailing: StatusBadge.status(i.status))),
          const SectionHeading('One useful action'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.tips_and_updates_outlined, color: AppColors.amber),
              title: Text('Spot a dripping tap?'),
              subtitle: Text('Report it with an estimated rate — even a slow drip adds up over days.'),
            ),
          ),
        ]),
      ),
    );
  }
}
