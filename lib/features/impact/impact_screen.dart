
import 'package:flutter/material.dart';

import '../../services/app_repository.dart';
import '../../services/impact_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

class ImpactScreen extends StatelessWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = ImpactService.compute(RepositoryScope.of(context));
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final pal = context.pal;
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Our impact'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            // Hero
            Reveal(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: pal.hero,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: pal.heroAccent.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.eco_rounded,
                        size: 30,
                        color: pal.heroAccent,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Small actions.\nA healthier campus.',
                      style: t.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Every reported leak, energy issue and '
                      'digital submission helps us understand '
                      'where our campus can do better.',
                      style: t.bodyMedium?.copyWith(
                        color: pal.muted,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ImpactTag(
                          icon: Icons.bolt_rounded,
                          label: 'Energy',
                        ),
                        _ImpactTag(
                          icon: Icons.water_drop_outlined,
                          label: 'Water',
                        ),
                        _ImpactTag(
                          icon: Icons.description_outlined,
                          label: 'Paper',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Campus impact at a glance',
              style: t.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Three ways we measure progress, each in its own unit.',
              style: t.bodyMedium?.copyWith(
                color: pal.muted,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            // Energy summary
            Reveal(
              delay: stagger(1),
              child: _ImpactSection(
                icon: Icons.bolt_rounded,
                title: 'Energy',
                subtitle: 'Use less. Waste less.',
                color: const Color(0xFFB9812B),
                background: const Color(0xFFFFF2D8),
                sdg: 'SDG 7 · 13',
                children: [
                  _MetricTile(
                    name: 'Excess energy',
                    value: '${fmtNum(m.excessKwh, 1)} kWh',
                    explanation:
                        'Estimated excess consumption across active '
                        'energy alerts.',
                    icon: Icons.electric_bolt_rounded,
                  ),
                  _MetricTile(
                    name: 'Estimated cost',
                    value: '₹${fmtNum(m.energyCost)}',
                    explanation:
                        'Excess energy multiplied by the configured '
                        'electricity tariff.',
                    icon: Icons.currency_rupee_rounded,
                  ),
                  _MetricTile(
                    name: 'Associated emissions',
                    value: '${fmtNum(m.co2Kg, 1)} kg CO₂e',
                    explanation:
                        'Estimated emissions associated with excess '
                        'energy consumption.',
                    icon: Icons.cloud_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Water summary
            Reveal(
              delay: stagger(2),
              child: _ImpactSection(
                icon: Icons.water_drop_rounded,
                title: 'Water',
                subtitle: 'Every drop matters.',
                color: const Color(0xFF367FA0),
                background: const Color(0xFFE4F3FA),
                sdg: 'SDG 6',
                children: [
                  _MetricTile(
                    name: 'Current estimated loss',
                    value: '${fmtNum(m.waterActiveLossLitres)} L',
                    explanation:
                        'Loss from open and in-progress incidents.',
                    icon: Icons.water_drop_outlined,
                  ),
                  _MetricTile(
                    name: 'Historical estimated loss',
                    value: '${fmtNum(m.waterHistoricalLossLitres)} L',
                    explanation:
                        'Includes resolved incidents; dismissed '
                        'incidents are excluded.',
                    icon: Icons.history_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Paper summary
            Reveal(
              delay: stagger(3),
              child: _ImpactSection(
                icon: Icons.description_rounded,
                title: 'Paperless campus',
                subtitle: 'Make digital the easier choice.',
                color: const Color(0xFF528052),
                background: const Color(0xFFE7F1E4),
                sdg: 'SDG 12',
                children: [
                  _MetricTile(
                    name: 'Pages estimated avoided',
                    value: fmtNum(m.pagesAvoided),
                    explanation:
                        'Sum of declared per-submission estimates. '
                        'This is a counterfactual estimate, not '
                        'a verified count of paper saved.',
                    icon: Icons.auto_stories_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Methodology, kept accessible but secondary.
            Text(
              'Where do these numbers come from?',
              style: t.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Explore how Campusync calculates its estimates '
              'and how it uses AI and rules.',
              style: t.bodyMedium?.copyWith(
                color: pal.muted,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 14),

            _MethodCard(
              icon: Icons.photo_camera_outlined,
              title: 'Water leak analysis',
              description:
                  'An image model may suggest the issue type, '
                  'severity and flow rate. A student can confirm '
                  'or edit the suggestion.',
              color: pal.brand,
            ),
            const SizedBox(height: 10),
            _MethodCard(
              icon: Icons.rule_rounded,
              title: 'Readable rules',
              description:
                  'Energy calculations, priority ordering and '
                  'recommended actions use explicit rules.',
              color: colors.primary,
            ),
            const SizedBox(height: 10),
            _MethodCard(
              icon: Icons.fact_check_outlined,
              title: 'Evidence, not guesswork',
              description:
                  'Where available, each alert or recommendation '
                  'can explain the reasoning behind it.',
              color: pal.success,
            ),
            const SizedBox(height: 10),
            _MethodCard(
              icon: Icons.science_outlined,
              title: 'Transparent demo data',
              description:
                  'Sample data, assumptions and fallbacks are '
                  'not presented as verified live measurements.',
              color: const Color(0xFFB9812B),
            ),

            const SizedBox(height: 22),

            // Important distinction between estimates and verified results.
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest
                    .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: pal.muted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Impact, measured honestly',
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Energy, water and paper are reported '
                          'separately because kWh, litres and pages '
                          'are different units. Values shown in this '
                          'demo are estimates, not proof of '
                          'verified environmental savings.',
                          style: t.bodySmall?.copyWith(
                            color: pal.muted,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const DemoNote(),
          ],
        ),
      ),
    );
  }
}

class _ImpactTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ImpactTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: pal.heroAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: pal.heroAccent),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: pal.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ImpactSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final String sdg;
  final List<Widget> children;

  const _ImpactSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.sdg,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final effectiveBackground = dark
        ? theme.colorScheme.surfaceContainerHighest
        : background;

    final effectiveColor = dark
        ? theme.colorScheme.primary
        : color;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: effectiveBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: effectiveColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: t.bodySmall?.copyWith(
                        color: context.pal.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: effectiveBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  sdg,
                  style: t.labelSmall?.copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 6),

          ...children,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String name;
  final String value;
  final String explanation;
  final IconData icon;

  const _MetricTile({
    required this.name,
    required this.value,
    required this.explanation,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pal = context.pal;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest
                  .withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 19,
              color: pal.muted,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: t.bodySmall?.copyWith(
                    color: pal.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: AnimatedNumber(
              value: double.tryParse(
                    value
                        .replaceAll(',', '')
                        .replaceAll('₹', '')
                        .replaceAll(' kWh', '')
                        .replaceAll(' kg CO₂e', '')
                        .replaceAll(' L', ''),
                  ) ??
                  0,
              style: t.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pal = context.pal;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: t.bodySmall?.copyWith(
                    color: pal.muted,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
