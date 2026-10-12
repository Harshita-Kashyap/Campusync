import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MetricTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? note;
  final Color color;
  const MetricTile({super.key, required this.icon, required this.label, required this.value, this.note, this.color = AppColors.forest});

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label: $value',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon, color: color),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(value, key: ValueKey(value),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                if (note != null) Text(note!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.muted)),
              ]),
            ]),
          ),
        ),
      );
}
