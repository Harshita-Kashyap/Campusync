import 'package:flutter/material.dart';
import '../../services/app_repository.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Student: demo-local activity (no real identity is modelled; all records are shown).
class MyActivityScreen extends StatelessWidget {
  const MyActivityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final inc = repo.getIncidents().reversed.toList();
    final subs = repo.getSubmissions().reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('My activity')),
      body: SafeArea(
        child: (inc.isEmpty && subs.isEmpty)
            ? const EmptyState(title: 'Nothing reported yet', message: 'If you notice waste, you can help fix it.')
            : ListView(padding: const EdgeInsets.all(20), children: [
                const Text('Demo-local activity: no real student identity is modelled.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                const SectionHeading('Water reports'),
                if (inc.isEmpty) const Text('None yet.'),
                for (final i in inc)
                  Card(child: ListTile(title: Text(i.locationName), subtitle: Text('${i.description}\n~${i.estimatedLitresLost.toStringAsFixed(0)} L (estimate) · ${timeAgo(i.reportedAt)}'), isThreeLine: true, trailing: StatusBadge.status(i.status))),
                const SectionHeading('Digital submissions'),
                if (subs.isEmpty) const Text('None yet.'),
                for (final s in subs)
                  Card(child: ListTile(title: Text(s.fileName), subtitle: Text('${s.id} · ${timeAgo(s.submittedAt)}'), trailing: s.duplicateDetected ? const StatusBadge(label: 'Duplicate', icon: Icons.copy, color: AppColors.amber) : null)),
              ]),
      ),
    );
  }
}
