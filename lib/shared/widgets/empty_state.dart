import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  const EmptyState({super.key, required this.title, this.message, this.icon = Icons.eco_outlined});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: pal.brandSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 26, color: pal.ink),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: t.titleMedium),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: pal.muted)),
          ],
        ]),
      ),
    );
  }
}
