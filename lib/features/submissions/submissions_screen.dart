
import 'package:flutter/material.dart';

import '../../services/app_repository.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../dashboard/role_switch_button.dart';

enum _SubmissionFilter { all, flagged, unique }

class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  State<SubmissionsScreen> createState() =>
      _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  _SubmissionFilter _filter = _SubmissionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final submissions = repo.getSubmissions().reversed.toList();
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final pal = context.pal;
    final colors = theme.colorScheme;

    final totalPages = submissions.fold<int>(
      0,
      (sum, item) => sum + item.pagesAvoidedEstimate,
    );

    final flagged = submissions
        .where((item) => item.duplicateDetected)
        .length;

    final query = _searchController.text.trim().toLowerCase();

    final filtered = submissions.where((item) {
      final matchesFilter = switch (_filter) {
        _SubmissionFilter.all => true,
        _SubmissionFilter.flagged => item.duplicateDetected,
        _SubmissionFilter.unique => !item.duplicateDetected,
      };

      final matchesSearch = query.isEmpty ||
          item.fileName.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query) ||
          item.studentId.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();

    return ModuleScaffold(
      title: 'Digital Submissions',
      actions: const [
        ThemeToggleButton(),
        RoleSwitchButton(),
        SizedBox(width: 4),
      ],
      body: PageBody(
        children: [
          // Header
          Text(
            'Submission review',
            style: t.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Review assignments, inspect duplicate checks, '
            'and understand how prototype grading was decided.',
            style: t.bodyMedium?.copyWith(
              color: pal.muted,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 22),

          // Overview metrics
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 370;
              final cardWidth = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _MetricCard(
                      icon: Icons.description_outlined,
                      label: 'Submissions',
                      value: submissions.length,
                      color: colors.primary,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MetricCard(
                      icon: Icons.copy_all_rounded,
                      label: 'Duplicate flags',
                      value: flagged,
                      color: flagged > 0
                          ? colors.error
                          : pal.success,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MetricCard(
                      icon: Icons.eco_outlined,
                      label: 'Pages avoided',
                      value: totalPages,
                      color: pal.success,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MetricCard(
                      icon: Icons.verified_outlined,
                      label: 'Marked unique',
                      value: submissions.length - flagged,
                      color: pal.brand,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // Data disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: pal.muted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Demo data · Estimates, not live sensor measurements. '
                    'Scores are prototype grading results, not official '
                    'academic decisions. Duplicate flags require review.',
                    style: t.bodySmall?.copyWith(
                      color: pal.muted,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // List heading
          SectionHeading(
            'Review queue',
            trailing: StatusBadge(
              label: '${filtered.length} shown',
              icon: Icons.inbox_outlined,
            ),
          ),

          const SizedBox(height: 12),

          // Search
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search file, student or reference',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  count: submissions.length,
                  selected: _filter == _SubmissionFilter.all,
                  onTap: () => setState(
                    () => _filter = _SubmissionFilter.all,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Flagged',
                  count: flagged,
                  selected: _filter == _SubmissionFilter.flagged,
                  onTap: () => setState(
                    () => _filter = _SubmissionFilter.flagged,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Unique',
                  count: submissions.length - flagged,
                  selected: _filter == _SubmissionFilter.unique,
                  onTap: () => setState(
                    () => _filter = _SubmissionFilter.unique,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (filtered.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  Icon(
                    submissions.isEmpty
                        ? Icons.inbox_outlined
                        : Icons.search_off_rounded,
                    size: 38,
                    color: pal.muted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    submissions.isEmpty
                        ? 'No submissions yet'
                        : 'No matching submissions',
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    submissions.isEmpty
                        ? 'Student assignments will appear here '
                            'when they are submitted.'
                        : 'Try another search or change the filter.',
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(
                      color: pal.muted,
                      height: 1.5,
                    ),
                  ),
                  if (query.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(
                          () => _filter = _SubmissionFilter.all,
                        );
                      },
                      child: const Text('Clear search and filters'),
                    ),
                  ],
                ],
              ),
            )
          else
            for (var i = 0; i < filtered.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Reveal(
                  key: ValueKey(filtered[i].id),
                  delay: stagger(i),
                  child: _SubmissionCard(
                    submission: filtered[i],
                    onTap: () => _showDetails(
                      context,
                      filtered[i],
                    ),
                  ),
                ),
              ),

          const SizedBox(height: 12),
          const DemoNote(),
        ],
      ),
    );
  }

  void _showDetails(
    BuildContext context,
    dynamic submission,
  ) {
    showAppSheet<void>(
      context,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        final pal = ctx.pal;
        final colors = Theme.of(ctx).colorScheme;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: pal.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              Text(
                'Submission review',
                style: t.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                submission.fileName,
                style: t.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                'Reference: ${submission.id}',
                style: t.bodySmall?.copyWith(color: pal.muted),
              ),

              const SizedBox(height: 20),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  submission.duplicateDetected
                      ? const StatusBadge(
                          label: 'Duplicate flagged',
                          icon: Icons.copy_outlined,
                          tone: Tone.warning,
                        )
                      : const StatusBadge(
                          label: 'No duplicate detected',
                          icon: Icons.verified_outlined,
                          tone: Tone.success,
                        ),
                  StatusBadge(
                    label: submission.source == 'api' ? 'AI evaluation' : 'Prototype grading',
                    icon: submission.source == 'api' ? Icons.auto_awesome_outlined : Icons.science_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: _DetailMetric(
                      label: 'Score',
                      value: '${submission.score % 1 == 0 ? submission.score.toStringAsFixed(0) : submission.score.toStringAsFixed(1)} / ${submission.maxScore.toStringAsFixed(submission.maxScore % 1 == 0 ? 0 : 1)}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DetailMetric(
                      label: 'Pages avoided',
                      value: '~${submission.pagesAvoidedEstimate}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Text(
                'Grading feedback',
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                submission.gradingFeedback,
                style: t.bodyMedium?.copyWith(
                  color: pal.muted,
                  height: 1.55,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'How this was decided',
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ExplainSteps(
                steps: submissionEvidence(submission),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      color: pal.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A duplicate flag is a review signal, not '
                        'proof of misconduct. Confirm the evidence '
                        'before making any academic decision.',
                        style: t.bodySmall?.copyWith(
                          color: pal.muted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 15),
          AnimatedNumber(
            value: value.toDouble(),
            style: t.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: t.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: pal.brandSoft,
        labelStyle: TextStyle(
          color: selected ? pal.ink : colors.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
        side: BorderSide(
          color: selected ? pal.brand : colors.outlineVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final dynamic submission;
  final VoidCallback onTap;

  const _SubmissionCard({
    required this.submission,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pal = context.pal;
    final flagged = submission.duplicateDetected;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScoreRing(
                score: submission.score,
                max: submission.maxScore,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.fileName,
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Student: ${submission.studentId}',
                      style: t.bodySmall?.copyWith(
                        color: pal.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${submission.id} · ${timeAgo(submission.submittedAt)}',
                      style: t.bodySmall?.copyWith(
                        color: pal.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.chevron_right_rounded,
                color: pal.muted,
              ),
            ],
          ),

          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              flagged
                  ? const StatusBadge(
                      label: 'Duplicate flagged',
                      icon: Icons.copy_outlined,
                      tone: Tone.warning,
                    )
                  : const StatusBadge(
                      label: 'No duplicate detected',
                      icon: Icons.verified_outlined,
                      tone: Tone.success,
                    ),
              StatusBadge(
                label: submission.source == 'api' ? 'AI-evaluated score' : 'Rule-based score',
                icon: submission.source == 'api' ? Icons.auto_awesome_outlined : Icons.rule_rounded,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            submission.gradingFeedback,
            style: t.bodyMedium?.copyWith(
              color: pal.muted,
              height: 1.45,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 17,
                color: pal.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '~${submission.pagesAvoidedEstimate} pages estimated avoided',
                  style: t.bodySmall?.copyWith(
                    color: pal.muted,
                  ),
                ),
              ),
              Text(
                'Review',
                style: t.labelLarge?.copyWith(
                  color: pal.brand,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final double score;
  final double max;

  const _ScoreRing({
    required this.score,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    final fraction =
        max <= 0 ? 0.0 : (score / max).clamp(0.0, 1.0);

    String format(double value) =>
        value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

    return SizedBox(
      width: 57,
      height: 57,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: pal.surfaceHigh,
                  color: pal.success,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${format(score)}\n/ ${format(max)}',
                textAlign: TextAlign.center,
                style: t.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DetailMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pal = context.pal;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: pal.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t.bodySmall?.copyWith(color: pal.muted),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: t.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
