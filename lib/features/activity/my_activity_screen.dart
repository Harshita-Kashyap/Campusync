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
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My activity'), actions: const [ThemeToggleButton(), SizedBox(width: 4)]),
      body: SafeArea(
        child: (inc.isEmpty && subs.isEmpty)
            ? const EmptyState(title: 'Nothing reported yet', message: 'If you notice waste, you can help fix it.')
            : PageBody(children: [
                Text('Demo-local activity: no real student identity is modelled.', style: t.bodySmall),
                if (inc.isNotEmpty) const SectionHeading('Water reports'),
                for (var i = 0; i < inc.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Reveal(
                      key: ValueKey(inc[i].id),
                      delay: stagger(i),
                      child: AppCard(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(inc[i].locationName, style: t.titleSmall),
                              Text(plainDescription(inc[i].description), style: t.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('~${fmtNum(inc[i].estimatedLitresLost)} L (estimate), ${timeAgo(inc[i].reportedAt)}', style: t.bodySmall),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          StatusBadge.status(inc[i].status),
                        ]),
                      ),
                    ),
                  ),
                if (subs.isNotEmpty) const SectionHeading('Digital submissions'),
                for (final s in subs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.fileName, style: t.titleSmall),
                            Text('${s.id}, ${timeAgo(s.submittedAt)}', style: t.bodySmall),
                          ]),
                        ),
                        if (s.duplicateDetected) const StatusBadge(label: 'Duplicate', icon: Icons.copy_outlined, tone: Tone.warning),
                      ]),
                    ),
                  ),
              ]),
      ),
    );
  }
}
