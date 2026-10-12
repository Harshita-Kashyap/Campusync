import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Status is always shown as text + icon, never colour alone.
class StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.icon, required this.color});

  factory StatusBadge.status(String s) {
    switch (s) {
      case 'open': return const StatusBadge(label: 'Open', icon: Icons.error_outline, color: AppColors.coral);
      case 'active': return const StatusBadge(label: 'Active', icon: Icons.error_outline, color: AppColors.coral);
      case 'in_progress': return const StatusBadge(label: 'In progress', icon: Icons.autorenew, color: AppColors.amber);
      case 'resolved': return const StatusBadge(label: 'Resolved', icon: Icons.check_circle_outline, color: AppColors.forest);
      default: return const StatusBadge(label: 'Dismissed', icon: Icons.block, color: AppColors.muted);
    }
  }

  factory StatusBadge.priority(String p) => StatusBadge(
        label: p[0].toUpperCase() + p.substring(1),
        icon: (p == 'critical' || p == 'high') ? Icons.priority_high : Icons.flag_outlined,
        color: (p == 'critical' || p == 'high') ? AppColors.coral : (p == 'medium' ? AppColors.amber : AppColors.muted),
      );

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}
