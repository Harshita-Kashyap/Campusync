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
    final recent = repo.getIncidents().reversed.take(3).toList();
    final pal = context.pal;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Campusync'), actions: const [ThemeToggleButton(), RoleSwitchButton(), SizedBox(width: 4)]),
      body: SafeArea(
        child: PageBody(children: [
          Reveal(
            child: HeroPanel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your campus, a little better.', style: t.headlineSmall?.copyWith(color: pal.onHero)),
                const SizedBox(height: 6),
                Text('Spot a leak? Snap it, let AI suggest the details, and confirm. It joins the admin priority queue.',
                    style: t.bodyMedium?.copyWith(color: pal.onHero.withValues(alpha: 0.8))),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => onOpenTab(1),
                  icon: const Icon(Icons.add),
                  label: const Text('Report a problem'),
                  style: FilledButton.styleFrom(backgroundColor: pal.heroAccent, foregroundColor: pal.hero),
                ),
              ]),
            ),
          ),
          const SectionHeading('Campus right now'),
          Reveal(
            delay: stagger(1),
            child: MetricGrid(columns: 3, children: [
              MetricTile(icon: Icons.water_drop_outlined, label: 'Water lost (est.)', number: m.waterActiveLossLitres,
                  format: (v) => '${fmtNum(v)} L', tone: Tone.info),
              MetricTile(icon: Icons.report_problem_outlined, label: 'Open reports', number: m.openIncidents.toDouble(), tone: Tone.danger),
              MetricTile(icon: Icons.description_outlined, label: 'Pages avoided (est.)', number: m.pagesAvoided.toDouble()),
            ]),
          ),
          const SizedBox(height: 10),
          const DemoNote(),
          SectionHeading('Recent reports', trailing: TextButton(onPressed: () => onOpenTab(2), child: const Text('See all'))),
          if (recent.isEmpty)
            const AppCard(child: EmptyState(title: 'Nothing reported yet', message: 'If you notice waste, you can help fix it.'))
          else
            for (var i = 0; i < recent.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Reveal(
                  key: ValueKey(recent[i].id),
                  delay: stagger(i + 2),
                  child: AppCard(
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(recent[i].locationName, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(timeAgo(recent[i].reportedAt), style: t.bodySmall),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge.status(recent[i].status),
                    ]),
                  ),
                ),
              ),
        ]),
      ),
    );
  }
}
