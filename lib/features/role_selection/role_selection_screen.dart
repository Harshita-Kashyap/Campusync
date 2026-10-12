import 'package:flutter/material.dart';
import '../../app.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Demo navigation only, NOT production security.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Align(alignment: Alignment.centerRight, child: ThemeToggleButton()),
                const Spacer(),
                Reveal(
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: pal.hero, borderRadius: BorderRadius.circular(20)),
                    child: Icon(Icons.eco, size: 30, color: pal.heroAccent),
                  ),
                ),
                const SizedBox(height: 20),
                Reveal(delay: stagger(1, 80), child: Text('Campusync', style: t.displaySmall)),
                const SizedBox(height: 8),
                Reveal(
                  delay: stagger(2, 80),
                  child: Text('Small campus actions. Measurable environmental change.',
                      style: t.bodyLarge?.copyWith(color: pal.muted)),
                ),
                const Spacer(),
                Reveal(
                  delay: stagger(3, 80),
                  child: _RoleCard(
                    icon: Icons.school_outlined,
                    title: 'Student view',
                    message: 'Report a leak and follow what happens next.',
                    onTap: () => Navigator.pushReplacementNamed(context, Routes.student),
                  ),
                ),
                const SizedBox(height: 12),
                Reveal(
                  delay: stagger(4, 80),
                  child: _RoleCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin view',
                    message: 'Work through the priority queue and update status.',
                    onTap: () => Navigator.pushReplacementNamed(context, Routes.admin),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Sample campus data · role switch is for demo only', style: t.bodySmall),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title, message;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.title, required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: pal.brandSoft, borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: pal.ink),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: t.titleMedium),
            const SizedBox(height: 2),
            Text(message, style: t.bodyMedium?.copyWith(color: pal.muted)),
          ]),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 16, color: pal.muted),
      ]),
    );
  }
}
