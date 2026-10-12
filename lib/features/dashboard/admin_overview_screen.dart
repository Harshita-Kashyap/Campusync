import 'package:flutter/material.dart';
import '../../models/models.dart';
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
    final t = Theme.of(context).textTheme;
    final shown = m.queue.take(4).toList();
    final hidden = m.queue.length - shown.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus overview'),
        actions: const [ThemeToggleButton(), RoleSwitchButton(), SizedBox(width: 4)],
      ),
      body: SafeArea(
        child: PageBody(children: [
          Reveal(child: _Hero(m: m)),
          const SizedBox(height: 12),
          const DemoNote(),
          const SizedBox(height: 20),
          Reveal(
            delay: stagger(1),
            child: MetricGrid(children: [
              MetricTile(icon: Icons.currency_rupee, label: 'Energy cost, estimate', number: m.energyCost,
                  format: (v) => '₹${fmtNum(v)}', note: 'Active alerts only', tone: Tone.warning),
              MetricTile(icon: Icons.cloud_outlined, label: 'Emissions, estimate', number: m.co2Kg,
                  format: (v) => '${fmtNum(v, 1)} kg', note: 'CO₂e from excess energy', tone: Tone.info),
              MetricTile(icon: Icons.description_outlined, label: 'Pages avoided, estimate',
                  number: m.pagesAvoided.toDouble(), note: 'Declared, not verified'),
              MetricTile(icon: Icons.task_alt, label: 'Resolved so far', number: m.resolvedItems.toDouble(),
                  note: 'Water and energy', tone: Tone.success),
            ]),
          ),
          const SectionHeading('Priority queue'),
          if (shown.isEmpty)
            const AppCard(child: EmptyState(title: 'Queue is clear', message: 'Nothing needs attention right now.', icon: Icons.task_alt))
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(children: [
                for (var i = 0; i < shown.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Reveal(
                      key: ValueKey(shown[i].id),
                      delay: stagger(i + 2),
                      child: _QueueRow(item: shown[i], onTap: () => _openQueueSheet(context, repo, shown[i])),
                    ),
                  ),
              ]),
            ),
          if (hidden > 0) Text('+$hidden more in the Water and Energy tabs', style: t.bodySmall),
          const SectionHeading('Suggested actions'),
          if (m.recommendations.isEmpty)
            const AppCard(child: EmptyState(title: 'No suggestions yet', icon: Icons.lightbulb_outline))
          else
            for (final r in m.recommendations.take(2))
              Padding(padding: const EdgeInsets.only(bottom: 10), child: _RecCard(rec: r)),
          const SizedBox(height: 14),
          AppCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ImpactScreen())),
            child: Row(children: [
              Icon(Icons.rule, color: context.pal.muted),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('How every number is calculated', style: t.titleSmall),
                  Text('Formulas, scope, and where AI is used', style: t.bodySmall),
                ]),
              ),
              Icon(Icons.chevron_right, color: context.pal.muted),
            ]),
          ),
        ]),
      ),
    );
  }

  void _openQueueSheet(BuildContext context, AppRepository repo, QueueItem q) {
    final messenger = ScaffoldMessenger.of(context);
    final isWater = q.type == 'water';
    final options = isWater
        ? ['open', 'in_progress', 'resolved', 'dismissed'].where((s) => s != q.status).toList()
        : ['resolved', 'dismissed'];
    final List<ExplainStep> steps;
    if (isWater) {
      final i = repo.getIncidents().where((e) => e.id == q.id).firstOrNull;
      steps = i == null ? const [] : waterEvidence(i);
    } else {
      final a = repo.getAlerts().where((e) => e.id == q.id).firstOrNull;
      steps = a == null ? const [] : energyEvidence(a);
    }
    showAppSheet<void>(
      context,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(q.title, style: t.titleLarge),
          const SizedBox(height: 2),
          Text(q.subtitle, style: t.bodyMedium?.copyWith(color: ctx.pal.muted)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [StatusBadge.priority(q.priority), StatusBadge.status(q.status)]),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Why it is on the list', style: t.titleMedium),
            const SizedBox(height: 14),
            ExplainSteps(steps: steps),
          ],
          const SizedBox(height: 24),
          StatusActions(
            options: options,
            onPick: (s) async {
              Navigator.pop(ctx);
              if (isWater) {
                await repo.updateIncidentStatus(q.id, s);
              } else {
                await repo.updateAlertStatus(q.id, s);
              }
              messenger.showSnackBar(SnackBar(content: Text('${q.title} marked ${prettyStatus(s).toLowerCase()}')));
            },
          ),
        ]);
      },
    );
  }
}

class _Hero extends StatelessWidget {
  final ImpactMetrics m;
  const _Hero({required this.m});

  String _headline() {
    final parts = <String>[
      if (m.openIncidents > 0) '${m.openIncidents} water ${m.openIncidents == 1 ? 'incident' : 'incidents'}',
      if (m.activeAlerts > 0) '${m.activeAlerts} energy ${m.activeAlerts == 1 ? 'alert' : 'alerts'}',
    ];
    return '${parts.join(' and ')} ${m.openIncidents + m.activeAlerts == 1 ? 'needs' : 'need'} attention';
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    final open = m.openIncidents + m.activeAlerts;
    final figure = t.headlineMedium?.copyWith(color: pal.heroAccent);
    final cap = t.bodySmall?.copyWith(color: pal.onHero.withValues(alpha: 0.72));
    return HeroPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(open == 0 ? 'Everything is under control' : _headline(), style: t.headlineSmall?.copyWith(color: pal.onHero)),
        const SizedBox(height: 6),
        Text(
          open == 0
              ? 'No open water incidents or energy alerts.'
              : (m.criticalHigh > 0 ? '${m.criticalHigh} marked high or critical. Start at the top of the queue.' : 'None are high priority.'),
          style: t.bodyMedium?.copyWith(color: pal.onHero.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 22),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedNumber(value: m.waterActiveLossLitres, format: (v) => '${fmtNum(v)} L', style: figure),
              Text('Water lost now, estimate', style: cap),
            ]),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedNumber(value: m.excessKwh, format: (v) => '${fmtNum(v, 1)} kWh', style: figure),
              Text('Above energy baseline', style: cap),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final QueueItem item;
  final VoidCallback onTap;
  const _QueueRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    final hot = item.priority == 'critical' || item.priority == 'high';
    final c = pal.of(hot ? Tone.danger : (item.priority == 'medium' ? Tone.warning : Tone.neutral));
    return AppCard(
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
          child: Icon(item.type == 'water' ? Icons.water_drop_outlined : Icons.bolt_outlined, color: c),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(item.subtitle, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [StatusBadge.priority(item.priority), StatusBadge.status(item.status)]),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(timeAgo(item.time), style: t.labelSmall),
          const SizedBox(height: 14),
          Icon(Icons.chevron_right, color: pal.muted),
        ]),
      ]),
    );
  }
}

class _RecCard extends StatelessWidget {
  final SustainabilityRecommendation rec;
  const _RecCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(rec.title, style: t.titleSmall)), StatusBadge.priority(rec.priority)]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.fact_check_outlined, size: 16, color: pal.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(rec.evidenceSummary, style: t.bodySmall)),
        ]),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.build_outlined, size: 16, color: pal.ink),
          const SizedBox(width: 8),
          Expanded(child: Text(rec.suggestedAction, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),
        rec.isAiGenerated ? StatusBadge.source('ai') : StatusBadge.rules(),
      ]),
    );
  }
}
