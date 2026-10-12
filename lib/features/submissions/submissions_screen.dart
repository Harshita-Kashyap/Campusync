import 'package:flutter/material.dart';
import '../../services/app_repository.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../dashboard/role_switch_button.dart';

/// Digital submissions: graded files, duplicate checks and the paper they avoid.
class SubmissionsScreen extends StatelessWidget {
  const SubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subs = RepositoryScope.of(context).getSubmissions().reversed.toList();
    final pages = subs.fold<int>(0, (s, x) => s + x.pagesAvoidedEstimate);
    final t = Theme.of(context).textTheme;
    final pal = context.pal;

    return ModuleScaffold(
      title: 'Digital Submissions',
      actions: const [ThemeToggleButton(), RoleSwitchButton(), SizedBox(width: 4)],
      body: subs.isEmpty
          ? const EmptyState(title: 'No submissions yet', message: 'Submitted files appear here with a score and a duplicate check.', icon: Icons.description_outlined)
          : PageBody(children: [
              Reveal(
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pages avoided, estimate', style: t.bodySmall),
                    const SizedBox(height: 4),
                    AnimatedNumber(value: pages.toDouble(), style: t.headlineMedium?.copyWith(color: pal.success)),
                    const SizedBox(height: 6),
                    Text('Sum of declared per-submission estimates. Not verified.', style: t.bodySmall),
                  ]),
                ),
              ),
              SectionHeading('${subs.length} ${subs.length == 1 ? 'submission' : 'submissions'}',
                  trailing: const StatusBadge(label: 'Prototype grading', icon: Icons.science_outlined)),
              for (var i = 0; i < subs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Reveal(
                    key: ValueKey(subs[i].id),
                    delay: stagger(i),
                    child: AppCard(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _ScoreRing(score: subs[i].score, max: subs[i].maxScore),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(subs[i].fileName, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${subs[i].id}, ${timeAgo(subs[i].submittedAt)}', style: t.bodySmall),
                            const SizedBox(height: 6),
                            Text(subs[i].gradingFeedback, style: t.bodyMedium),
                            const SizedBox(height: 10),
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              if (subs[i].duplicateDetected)
                                const StatusBadge(label: 'Duplicate flagged', icon: Icons.copy_outlined, tone: Tone.warning)
                              else
                                const StatusBadge(label: 'Unique', icon: Icons.verified_outlined, tone: Tone.success),
                              StatusBadge(label: '~${subs[i].pagesAvoidedEstimate} pages avoided', icon: Icons.description_outlined),
                            ]),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
            ]),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final double score, max;
  const _ScoreRing({required this.score, required this.max});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final f = max <= 0 ? 0.0 : (score / max).clamp(0.0, 1.0);
    String n(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
    return SizedBox(
      width: 54, height: 54,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: f),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Stack(alignment: Alignment.center, children: [
          SizedBox.expand(
            child: CircularProgressIndicator(value: v, strokeWidth: 5, backgroundColor: pal.surfaceHigh, color: pal.success, strokeCap: StrokeCap.round),
          ),
          Text('${n(score)}/${n(max)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
