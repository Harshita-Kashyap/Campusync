import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Status is always text + icon, never colour alone.
class StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Tone tone;
  const StatusBadge({super.key, required this.label, required this.icon, this.tone = Tone.neutral});

  factory StatusBadge.status(String s) {
    switch (s) {
      case 'open':
        return const StatusBadge(label: 'Open', icon: Icons.error_outline, tone: Tone.danger);
      case 'active':
        return const StatusBadge(label: 'Active', icon: Icons.error_outline, tone: Tone.danger);
      case 'in_progress':
        return const StatusBadge(label: 'In progress', icon: Icons.autorenew, tone: Tone.warning);
      case 'resolved':
        return const StatusBadge(label: 'Resolved', icon: Icons.check_circle_outline, tone: Tone.success);
      default:
        return const StatusBadge(label: 'Dismissed', icon: Icons.block, tone: Tone.neutral);
    }
  }

  factory StatusBadge.priority(String p) {
    final hot = p == 'critical' || p == 'high';
    return StatusBadge(
      label: p.isEmpty ? p : p[0].toUpperCase() + p.substring(1),
      icon: hot ? Icons.priority_high : Icons.flag_outlined,
      tone: hot ? Tone.danger : (p == 'medium' ? Tone.warning : Tone.neutral),
    );
  }

  /// Where an estimate came from. Only 'ai' may ever be presented as AI.
  factory StatusBadge.source(String source) {
    switch (source) {
      case 'ai':
        return const StatusBadge(label: 'AI estimate', icon: Icons.auto_awesome, tone: Tone.brand);
      case 'sample':
        return const StatusBadge(label: 'Saved sample, not live AI', icon: Icons.science_outlined, tone: Tone.warning);
      case 'fallback':
        return const StatusBadge(label: 'Fallback estimate', icon: Icons.science_outlined, tone: Tone.warning);
      case 'manual':
        return const StatusBadge(label: 'Manual report', icon: Icons.edit_outlined, tone: Tone.neutral);
      default:
        return const StatusBadge(label: 'Unverified source', icon: Icons.help_outline, tone: Tone.neutral);
    }
  }

  factory StatusBadge.rules() => const StatusBadge(label: 'Rule-based', icon: Icons.rule, tone: Tone.neutral);

  @override
  Widget build(BuildContext context) {
    final c = context.pal.of(tone);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }
}
